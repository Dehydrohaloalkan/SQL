-- Ключевые оптимизации:
-- 1. UNION вместо OR для BalAccount2/3/4 → каждая ветка использует свой индекс:
--    IX_ACCOUNT_BA2 (NrBank, BalAccount2, IDNAccount)
--    IX_ACCOUNT_BA3 (NrBank, BalAccount3, IDNAccount)
--    IX_ACCOUNT_NB_BA4 (NrBank, BalAccount4, IDNAccount)
-- 2. Фильтры SPAccGosInclude/Exclude вынесены в отдельные CTE (однократное чтение)
--    IX_SPACCINC_FILTER / IX_SPACCEXC_FILTER (PrYSR, count_NrAccount, NrAccountOrder)
-- 3. AccountStatus через INNER JOIN → IX_ACCSTATUS_OWNER_COVER covering scan
--    (IDNAccount, AccountStatus, StatusOwner, DtAccountOpen, DtAccountChange)
-- 4. InfoYSR через NOT EXISTS → точечный поиск по X2InfoYSR (DtBalance, NrBank, ...)
with
D as (
    -- IX_SPDATESCTL_FILTER: matching scan PrYSR_Month, MAX = первая строка по DESC
    select MAX("LastWorkDayMonth") as "DtBalance"
    from PBI."SPDatesControl"
    where "PrYSR_Month" = '1'
),
BANKS as (
    -- IX_SPBICBY_FILTER: non-matching scan (CdActRecord не ведущий), NrBank в индексе
    select "NrBank"
    from PBI."SPBICBY"
    where "CdActRecord" = '0'
),
INC2 as (
    -- IX_SPACCINC_FILTER: matching scan (PrYSR=1, count=2), NrAccountOrder covering
    select "NrAccountOrder"
    from PBI."SPAccGosInclude"
    where "PrYSR" = 1 and "count_NrAccount" = 2
),
INC3 as (
    select "NrAccountOrder"
    from PBI."SPAccGosInclude"
    where "PrYSR" = 1 and "count_NrAccount" = 3
),
INC4 as (
    select "NrAccountOrder"
    from PBI."SPAccGosInclude"
    where "PrYSR" = 1 and "count_NrAccount" = 4
),
EXC1_2 as (
    -- IX_SPACCEXC_FILTER: matching scan (PrYSR=1, count=2)
    select "NrAccountOrder"
    from PBI."SPAccGosExclude"
    where "PrYSR" = 1 and "count_NrAccount" = 2
),
EXC1_3 as (
    select "NrAccountOrder"
    from PBI."SPAccGosExclude"
    where "PrYSR" = 1 and "count_NrAccount" = 3
),
EXC1_4 as (
    select "NrAccountOrder"
    from PBI."SPAccGosExclude"
    where "PrYSR" = 1 and "count_NrAccount" = 4
),
EXC2_2 as (
    select "NrAccountOrder"
    from PBI."SPAccGosExclude"
    where "PrYSR" = 2 and "count_NrAccount" = 2
),
EXC2_3 as (
    select "NrAccountOrder"
    from PBI."SPAccGosExclude"
    where "PrYSR" = 2 and "count_NrAccount" = 3
),
EXC2_4 as (
    select "NrAccountOrder"
    from PBI."SPAccGosExclude"
    where "PrYSR" = 2 and "count_NrAccount" = 4
),
-- UNION трёх веток: оптимизатор использует отдельный индекс для каждой ветки.
-- UNION (без ALL) дедублицирует счета, попавшие в несколько веток.
AA_CAND as (
    -- ветка 1: IX_ACCOUNT_BA2 (NrBank, BalAccount2, IDNAccount)
    select AA."IDNAccount",
           AA."NrBank",
           AA."NrEWallet",
           AA."NrAccount",
           AA."CdCurrency",
           AA."BalAccount2",
           AA."BalAccount3",
           AA."BalAccount4"
    from PBI."Account" AA
    inner join BANKS B on AA."NrBank" = B."NrBank"
    where AA."NrBank" <> '042'
      and AA."BalAccount2" in (select "NrAccountOrder" from INC2)
    union
    -- ветка 2: IX_ACCOUNT_BA3 (NrBank, BalAccount3, IDNAccount)
    select AA."IDNAccount",
           AA."NrBank",
           AA."NrEWallet",
           AA."NrAccount",
           AA."CdCurrency",
           AA."BalAccount2",
           AA."BalAccount3",
           AA."BalAccount4"
    from PBI."Account" AA
    inner join BANKS B on AA."NrBank" = B."NrBank"
    where AA."NrBank" <> '042'
      and AA."BalAccount3" in (select "NrAccountOrder" from INC3)
    union
    -- ветка 3: IX_ACCOUNT_NB_BA4 (NrBank, BalAccount4, IDNAccount)
    select AA."IDNAccount",
           AA."NrBank",
           AA."NrEWallet",
           AA."NrAccount",
           AA."CdCurrency",
           AA."BalAccount2",
           AA."BalAccount3",
           AA."BalAccount4"
    from PBI."Account" AA
    inner join BANKS B on AA."NrBank" = B."NrBank"
    where AA."NrBank" <> '042'
      and AA."BalAccount4" in (select "NrAccountOrder" from INC4)
),
-- IX_ACCSTATUS_OWNER_COVER (IDNAccount, AccountStatus, StatusOwner, DtAccountOpen, DtAccountChange)
-- covering: все нужные поля в индексе, обращения к странице данных нет.
-- NOT IN по EXC-спискам: каждый подзапрос — точечный поиск по IX_SPACCEXC_FILTER
AA as (
    select C."IDNAccount",
           C."NrBank",
           C."NrEWallet",
           C."NrAccount",
           C."CdCurrency",
           ST."AccountStatus",
           ST."DtAccountOpen",
           ST."DtAccountChange"
    from AA_CAND C
    inner join PBI."AccountStatus" ST on C."IDNAccount" = ST."IDNAccount"
    where not (
               C."BalAccount2" in (select "NrAccountOrder" from EXC1_2)
            or C."BalAccount3" in (select "NrAccountOrder" from EXC1_3)
            or C."BalAccount4" in (select "NrAccountOrder" from EXC1_4)
          )
      and not (
               ST."StatusOwner" in ('INP', 'IZP')
           and (
                  C."BalAccount2" in (select "NrAccountOrder" from EXC2_2)
               or C."BalAccount3" in (select "NrAccountOrder" from EXC2_3)
               or C."BalAccount4" in (select "NrAccountOrder" from EXC2_4)
               )
          )
),
AAC as (
    select AA."NrBank",
           D."DtBalance",
           AA."NrEWallet",
           AA."NrAccount",
           AA."CdCurrency"
    from AA, D
    where (
            AA."AccountStatus" in ('1', '2', '3', '5')
            and AA."DtAccountOpen" <= D."DtBalance"
          )
       or (
            AA."AccountStatus" in ('8', '9')
            and AA."DtAccountOpen" <= D."DtBalance"
            and AA."DtAccountChange" >= D."DtBalance"
          )
),
-- NOT EXISTS вместо EXCEPT: для каждой строки AAC — точечный поиск по X2InfoYSR
-- (DtBalance, NrBank, NrAccount, NrEWallet, CdCurrency, BalanceStatus)
QREZ as (
    select distinct
           AAC."NrBank",
           AAC."DtBalance",
           case when AAC."NrEWallet" is not null
                then AAC."NrAccount" || '|' || AAC."NrEWallet" || '|' || AAC."CdCurrency"
                else AAC."NrAccount" || '||' || AAC."CdCurrency"
           end as "Account"
    from AAC
    where not exists (
        select 1
        from PBI."InfoYSR" Y
        where Y."DtBalance"   = AAC."DtBalance"
          and Y."NrBank"      = AAC."NrBank"
          and Y."NrAccount"   = AAC."NrAccount"
          and Y."CdCurrency"  = AAC."CdCurrency"
          and (
                (Y."NrEWallet" = AAC."NrEWallet")
             or (Y."NrEWallet" is null and AAC."NrEWallet" is null)
              )
    )
)
select "NrBank",
       '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account"
           || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' as "LineFile"
from QREZ
order by "NrBank",
         "LineFile"
