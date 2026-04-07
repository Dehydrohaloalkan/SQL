with AA as (
    select "IDNAccount",
        "NrBank",
        SUBSTR("NrAccount", 9, 4) as "BalAcc",
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
        and "NrBank" <> '042'
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
        ST."AccountStatus",
        ST."DtAccountOpen",
        ST."DtAccountChange"
    from AA
        Inner Join PBI."AccountStatus" ST on AA."IDNAccount" = ST."IDNAccount"
    where not (
            "BalAcc" = '3119'
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
            AC."AccountStatus" in ('1', '2', '3', '5')
            and AC."DtAccountOpen" <= D."DtBalance"
        )
        or (
            AC."AccountStatus" in ('8', '9')
            and AC."DtAccountOpen" <= D."DtBalance"
            and AC."DtAccountChange" >= D."DtBalance"
        )
),
SRA as (
    select "NrBank",
        "DtBalance",
        (
            case
                when (
                    SUBSTR("NrAccount", 9, 4) = '3119'
                    and "NrEWallet" is not NULL
                ) then "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
                else "NrAccount" || '||' || "CdCurrency"
            end
        ) as "Account"
    from PBI."InfoYSR"
    where "NrBank" in (
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
        and "DtBalance" in (
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
Q1 as (
    select "NrBank",
        "DtBalance",
        "Account"
    from AAC
    EXCEPT
    select "NrBank",
        "DtBalance",
        "Account"
    from SRA
),
QREZ as (
    select "NrBank",
        '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account" || '|090|' as "LineFile"
    from Q1
)
select *
from QREZ
ORDER BY "NrBank",
    "LineFile";