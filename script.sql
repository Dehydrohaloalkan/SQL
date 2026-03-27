with AA as (
    select "IDNAccount",
        "NrBank",
        (
            case
                when (
                    SUBSTR("NrAccount", 9, 4) = '3119'
                    and "NrEWallet" is not NULL
                ) then "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
                else "NrAccount" || '||' || "CdCurrency"
            end
        ) as "Account"
    from PBI."Account"
    where "NrBank" in (
            select "NrBank"
            from PBI."SPBICBY"
            where "BICStatus" in ('0', '1')
                and "CdActRecord" = '0'
        )
        and "NrBank" <> '042'
        and "NrBank" IN (
            '108',
            '110',
            '117',
            '175',
            '182',
            '222',
            '226',
            '270',
            '272',
            '288',
            '303',
            '333',
            '345',
            '369',
            '704',
            '735',
            '739',
            '742',
            '749',
            '765',
            '782',
            '795',
            '820',
            '964'
        )
        and (
            SUBSTR("NrAccount", 9, 4) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '4'
                    and "PrYSR" = '1'
            )
            or SUBSTR("NrAccount", 9, 3) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '3'
                    and "PrYSR" = '1'
            )
            or SUBSTR("NrAccount", 9, 2) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '2'
                    and "PrYSR" = '1'
            )
            or SUBSTR("NrAccount", 9, 1) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '1'
                    and "PrYSR" = '1'
            )
        )
),
AC as (
    select AA.*,
        PBI."AccountStatus"."AccountStatus",
        PBI."AccountStatus"."DtAccountOpen",
        PBI."AccountStatus"."DtAccountChange"
    from AA
        Inner Join PBI."AccountStatus" on AA."IDNAccount" = PBI."AccountStatus"."IDNAccount"
        and not (
            SUBSTR("Account", 9, 4) = '3119'
            and "StatusOwner" in ('INP', 'IZP')
        )
),
D as (
    select MAX("LastWorkDayMonth") as "DtBalance"
    from PBI."SPDatesControl"
    where "PrYSR_Month" = '1'
),
AAC as (
    select *
    from AC,
        D
    where (
            AC."DtAccountOpen" <= D."DtBalance"
            and AC."AccountStatus" in ('1', '2', '3', '5')
        )
        or (
            AC."DtAccountOpen" <= D."DtBalance"
            and AC."DtAccountChange" >= D."DtBalance"
            and AC."AccountStatus" in ('8', '9')
        )
),
SRA as (
    select (
            case
                when (
                    SUBSTR("NrAccount", 9, 4) = '3119'
                    and "NrEWallet" is not NULL
                ) then "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
                else "NrAccount" || '||' || "CdCurrency"
            end
        ) as "Account"
    from PBI."InfoYSR"
    where "DtBalance" in (
            select "DtBalance"
            from D
        )
        and (
            SUBSTR("NrAccount", 9, 4) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '4'
                    and "PrYSR" = '1'
            )
            or SUBSTR("NrAccount", 9, 3) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '3'
                    and "PrYSR" = '1'
            )
            or SUBSTR("NrAccount", 9, 2) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '2'
                    and "PrYSR" = '1'
            )
            or SUBSTR("NrAccount", 9, 1) IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '1'
                    and "PrYSR" = '1'
            )
        )
),
AACS as (
    select distinct ("Account")
    from AAC
    EXCEPT
    select distinct ("Account")
    from SRA
),
Q1 as (
    select distinct "NrBank",
        "DtBalance",
        "Account"
    from AAC
    where "Account" in (
            select "Account"
            from AACS
        )
) --select count  from Q1 
select "NrBank",
    '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account" || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' as "LineFile"
from Q1