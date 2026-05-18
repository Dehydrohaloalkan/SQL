-- Ключевые оптимизации:
-- 1. PACC: коррелированный EXISTS → JOIN к CTE BICS.
--    Оптимизатор использует BICS (малый набор) как внешнюю таблицу и зондирует
--    TableYTIGos через индексы на выражениях:
--    IXE_YTIGOS_PAYER (NrBankMQ, SUBSTR(NrAccountPayer,5,4))
--    IXE_YTIGOS_BENEF (NrBankMQ, SUBSTR(NrAccountBenef,5,4))
-- 2. PAC/AC: исправлен синтаксис запятой + INNER JOIN → явные INNER JOIN + CROSS JOIN
-- 3. PAC/AC: EXISTS по SPBICBY с BICStatus → matching scan по IX_SPBICBY_FILTER
--    (BICStatus, CdActRecord, NrBank, CdBank)
-- 4. Q3/Q33: NOT EXISTS вместо EXCEPT — точечный поиск по индексам
-- 5. LPACC/LSRA: явный список столбцов вместо SELECT *
with
FD as (
    select "DtMin3"
    from PBI."SPFunctionalDates"
),
DSTART as (
    -- IX_SPDATESCTL_FILTER: matching scan на PrYSR_Month, MIN = последняя строка DESC
    select MIN("LastWorkDayMonth") as "DtStartYSR"
    from PBI."SPDatesControl"
    where "PrYSR_Month" = '1'
),
-- Предвычисляем пары (NrBank, CdBank4) из SPBICBY для JOIN к TableYTIGos.
-- Позволяет оптимизатору использовать BICS как внешнюю таблицу с зондом по
-- IXE_YTIGOS_PAYER / IXE_YTIGOS_BENEF вместо коррелированного EXISTS.
BICS as (
    select distinct "NrBank",
                    SUBSTR("CdBank", 1, 4) as "CdBank4"
    from PBI."SPBICBY"
),
-- PACC: зондирование TableYTIGos через IXE_YTIGOS_PAYER и IXE_YTIGOS_BENEF
PACC as (
    select GOS."NrBankMQ"          as "NrBank",
           DATE(GOS."DtTmOperation") as "DtControl",
           GOS."NrAccount4Payer"   as "BalAccount4",
           GOS."NrAccountPayer"    as "Account",
           GOS."NrEWalletPayer"    as "NrEWallet"
    from PBI."TableYTIGos" GOS
    inner join BICS on GOS."NrBankMQ" = BICS."NrBank"
        and SUBSTR(GOS."NrAccountPayer", 5, 4) = BICS."CdBank4"
    union
    select GOS."NrBankMQ",
           DATE(GOS."DtTmOperation"),
           GOS."NrAccount4Benef",
           GOS."NrAccountBenef",
           GOS."NrEWalletBenef"
    from PBI."TableYTIGos" GOS
    inner join BICS on GOS."NrBankMQ" = BICS."NrBank"
        and SUBSTR(GOS."NrAccountBenef", 5, 4) = BICS."CdBank4"
),
-- PAC: исправлен синтаксис (запятая + INNER JOIN → явный INNER JOIN + CROSS JOIN).
-- IX_ACCSTATUS_OWNER_COVER (IDNAccount, AccountStatus, StatusOwner, DtAccountOpen, DtAccountChange)
-- IX_SPBICBY_FILTER (BICStatus, CdActRecord, NrBank, CdBank): matching scan BICStatus IN ('0','1')
PAC as (
    select distinct
        PAA."NrAccount"  as "AccountACC",
        PAA."NrEWallet"  as "NrEWalletACC",
        PST."AccountStatus",
        PST."DtAccountOpen",
        PST."DtAccountChange"
    from PBI."Account" PAA
    inner join PBI."AccountStatus" PST on PAA."IDNAccount" = PST."IDNAccount"
    cross join FD
    where PAA."NrBank" <> '042'
      and (
            PST."AccountStatus" in ('1', '2', '3', '5')
            or (
                PST."AccountStatus" in ('8', '9')
                and PST."DtAccountChange" >= FD."DtMin3"
               )
          )
      and exists (
            select 1
            from PBI."SPBICBY" B
            where B."NrBank"      = PAA."NrBank"
              and B."BICStatus"   in ('0', '1')
              and B."CdActRecord" = '0'
          )
),
LPACC as (
    select PACC."NrBank", PACC."DtControl", PACC."BalAccount4",
           PACC."Account", PACC."NrEWallet",
           PAC."AccountStatus", PAC."DtAccountOpen", PAC."DtAccountChange"
    from PACC
    inner join PAC on PACC."Account"   = PAC."AccountACC"
                  and PACC."NrEWallet" = PAC."NrEWalletACC"
    where PACC."NrEWallet" is not null
      and PAC."NrEWalletACC" is not null
    union
    select PACC."NrBank", PACC."DtControl", PACC."BalAccount4",
           PACC."Account", PACC."NrEWallet",
           PAC."AccountStatus", PAC."DtAccountOpen", PAC."DtAccountChange"
    from PACC
    inner join PAC on PACC."Account" = PAC."NrEWalletACC"
    where PACC."NrEWallet"      is null
      and PACC."BalAccount4"    <> '3119'
      and PAC."NrEWalletACC"   is not null
    union
    select PACC."NrBank", PACC."DtControl", PACC."BalAccount4",
           PACC."Account", PACC."NrEWallet",
           PAC."AccountStatus", PAC."DtAccountOpen", PAC."DtAccountChange"
    from PACC
    inner join PAC on PACC."Account" = PAC."AccountACC"
    where PACC."NrEWallet"    is null
      and PAC."NrEWalletACC"  is null
),
Q1 as (
    select "NrBank", "DtControl", "Account", "NrEWallet"
    from LPACC
    where (
            "AccountStatus" in ('1', '2', '3', '5')
            and "DtAccountOpen" <= "DtControl"
          )
       or (
            "AccountStatus" in ('8', '9')
            and "DtAccountOpen" <= "DtControl"
            and "DtAccountChange" >= "DtControl"
          )
),
-- NOT EXISTS вместо EXCEPT: для каждой строки PACC — точечный поиск по Q1
Q3 as (
    select distinct
        PACC."NrBank",
        '6|' || VARCHAR_FORMAT(PACC."DtControl", 'YYYY-MM-DD') || '|'
            || case when PACC."NrEWallet" is not null
                    then PACC."Account" || '|' || PACC."NrEWallet"
                    else PACC."Account" || '|'
               end
            || '|040|На отчетную дату отсутствуют сведения о номере лицевого счета/номере счета аналит.учета (эл.кошелька) в АИС ПБИ' as "LineFile"
    from PACC
    where not exists (
        select 1
        from Q1
        where Q1."NrBank"    = PACC."NrBank"
          and Q1."DtControl" = PACC."DtControl"
          and Q1."Account"   = PACC."Account"
          and (
                (Q1."NrEWallet" = PACC."NrEWallet")
             or (Q1."NrEWallet" is null and PACC."NrEWallet" is null)
              )
    )
),
SRA as (
    -- TableYSRGos мал (~28K строк); IX_YSRGOS_JOIN используется при зондировании из AC в LSRA
    select "NrBank",
           "DtBalance" as "DtControl",
           "NrEWallet",
           "NrAccount",
           "CdCurrency"
    from PBI."TableYSRGos"
),
-- AC: исправлен синтаксис (запятая + INNER JOIN → явный INNER JOIN + CROSS JOIN DSTART).
-- IX_ACCSTATUS_JOIN_COVER (IDNAccount, AccountStatus, DtAccountOpen, DtAccountChange): covering scan.
-- IX_SPBICBY_FILTER: matching scan BICStatus IN ('0','1')
AC as (
    select AA."NrEWallet"    as "NrEWalletACC",
           AA."NrAccount"    as "AccountACC",
           AA."CdCurrency"   as "CdCurrencyACC",
           ST."AccountStatus",
           ST."DtAccountOpen",
           ST."DtAccountChange"
    from PBI."Account" AA
    inner join PBI."AccountStatus" ST on AA."IDNAccount" = ST."IDNAccount"
    cross join DSTART
    where AA."NrBank" <> '042'
      and (
            ST."AccountStatus" in ('1', '2', '3', '5')
            or (
                ST."AccountStatus" in ('8', '9')
                and ST."DtAccountChange" >= DSTART."DtStartYSR"
               )
          )
      and exists (
            select 1
            from PBI."SPBICBY" B
            where B."NrBank"      = AA."NrBank"
              and B."BICStatus"   in ('0', '1')
              and B."CdActRecord" = '0'
          )
),
-- LSRA: при SRA как внешней, зондирование AC; при AC как внешней —
-- IX_YSRGOS_JOIN (NrAccount, CdCurrency, NrEWallet, NrBank, DtBalance) на TableYSRGos
LSRA as (
    select SRA."NrBank", SRA."DtControl", SRA."NrAccount",
           SRA."NrEWallet", SRA."CdCurrency",
           AC."AccountStatus", AC."DtAccountOpen", AC."DtAccountChange"
    from SRA
    inner join AC on SRA."NrAccount"  = AC."AccountACC"
                 and SRA."CdCurrency" = AC."CdCurrencyACC"
                 and SRA."NrEWallet"  = AC."NrEWalletACC"
    where SRA."NrEWallet"   is not null
      and AC."NrEWalletACC" is not null
    union
    select SRA."NrBank", SRA."DtControl", SRA."NrAccount",
           SRA."NrEWallet", SRA."CdCurrency",
           AC."AccountStatus", AC."DtAccountOpen", AC."DtAccountChange"
    from SRA
    inner join AC on SRA."NrAccount"  = AC."AccountACC"
                 and SRA."CdCurrency" = AC."CdCurrencyACC"
    where SRA."NrEWallet"   is null
      and AC."NrEWalletACC" is null
),
Q11 as (
    select "NrBank", "DtControl", "NrAccount", "NrEWallet", "CdCurrency"
    from LSRA
    where (
            "AccountStatus" in ('1', '2', '3', '5')
            and "DtAccountOpen" <= "DtControl"
          )
       or (
            "AccountStatus" in ('8', '9')
            and "DtAccountOpen" <= "DtControl"
            and "DtAccountChange" >= "DtControl"
          )
),
-- NOT EXISTS вместо EXCEPT: для каждой строки SRA — поиск в Q11
Q33 as (
    select distinct
        SRA."NrBank",
        '5|' || VARCHAR_FORMAT(SRA."DtControl", 'YYYY-MM-DD') || '|'
            || case when SRA."NrEWallet" is not null
                    then SRA."NrAccount" || '|' || SRA."NrEWallet" || '|' || SRA."CdCurrency"
                    else SRA."NrAccount" || '||' || SRA."CdCurrency"
               end
            || '|040|На отчетную дату отсутствуют сведения о номере лицевого счета/номере счета аналит.учета (эл.кошелька) в АИС ПБИ' as "LineFile"
    from SRA
    where not exists (
        select 1
        from Q11
        where Q11."NrBank"     = SRA."NrBank"
          and Q11."DtControl"  = SRA."DtControl"
          and Q11."NrAccount"  = SRA."NrAccount"
          and Q11."CdCurrency" = SRA."CdCurrency"
          and (
                (Q11."NrEWallet" = SRA."NrEWallet")
             or (Q11."NrEWallet" is null and SRA."NrEWallet" is null)
              )
    )
)
select * from Q3
union all
select * from Q33
order by "NrBank",
         "LineFile"
