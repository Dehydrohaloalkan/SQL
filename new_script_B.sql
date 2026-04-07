with PACC as (
    select "NrBankMQ" as "NrBank",
        DATE ("DtTmOperation") as "DtControl",
        (
            case
                when "NrEWalletPayer" is not NULL then "NrAccountPayer" || '|' || "NrEWalletPayer"
                else "NrAccountPayer" || '|'
            end
        ) as "Account"
    from PBI."TableYTIGos" GOS
    where SUBSTR ("NrAccountPayer", 5, 4) in (
            select SUBSTR("CdBank", 1, 4)
            from PBI."SPBICBY"
            where PBI."SPBICBY"."NrBank" = GOS."NrBankMQ"
        )
        and "NrBankMQ" in (
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
    UNION
    select "NrBankMQ" as "NrBank",
        DATE ("DtTmOperation") as "DtControl",
        (
            case
                when "NrEWalletBenef" is not NULL then "NrAccountBenef" || '|' || "NrEWalletBenef"
                else "NrAccountBenef" || '|'
            end
        ) as "Account"
    from PBI."TableYTIGos" GOS
    where SUBSTR ("NrAccountBenef", 5, 4) in (
            select SUBSTR("CdBank", 1, 4)
            from PBI."SPBICBY"
            where PBI."SPBICBY"."NrBank" = GOS."NrBankMQ"
        )
        and "NrBankMQ" in (
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
),
PAC1 as (
    select (
            case
                when PAA."NrEWallet" is not NULL then PAA."NrAccount" || '|' || PAA."NrEWallet"
                else PAA."NrAccount" || '|'
            end
        ) as "AccountACC",
        PST."AccountStatus",
        PST."DtAccountOpen",
        PST."DtAccountChange"
    from PBI."Account" PAA,
        PBI."SPFunctionalDates"
        Inner Join PBI."AccountStatus" PST on PAA."IDNAccount" = PST."IDNAccount"
    where PST."AccountStatus" in ('1', '2', '3', '5')
        or (
            PST."AccountStatus" in ('8', '9')
            and PST."DtAccountChange" >= PBI."SPFunctionalDates"."DtMin3"
        )
        and "NrBank" in (
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
),
PAC as (
    select distinct "AccountACC",
        "AccountStatus",
        "DtAccountOpen",
        "DtAccountChange"
    from PAC1
),
LPACC as (
    select *
    from PACC
        Left Join PAC on PACC."Account" = PAC."AccountACC"
),
Q1 as (
    select "NrBank",
        "DtControl",
        "Account"
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
Q2 as (
    select "NrBank",
        "DtControl",
        "Account"
    from LPACC
    EXCEPT
    select "NrBank",
        "DtControl",
        "Account"
    from Q1
),
Q3 as (
    select "NrBank",
        '6|' || VARCHAR_FORMAT("DtControl", 'YYYY-MM-DD') || '|' || "Account" || '|040|' as "LineFile"
    from Q2
),
SRA as (
    select distinct "NrBank",
        "DtBalance" as "DtControl",
        (
            case
                when "NrEWallet" is not NULL then "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
                else "NrAccount" || '||' || "CdCurrency"
            end
        ) as "Account"
    from PBI."TableYSRGos"
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
),
DSTART as (
    select MIN("LastWorkDayMonth") as "DtStartYSR"
    from PBI."SPDatesControl"
    where "PrYSR_Month" = '1'
),
AC as (
    select (
            case
                when AA."NrEWallet" is not NULL then AA."NrAccount" || '|' || AA."NrEWallet" || '|' || AA."CdCurrency"
                else AA."NrAccount" || '||' || AA."CdCurrency"
            end
        ) as "AccountACC",
        ST."AccountStatus",
        ST."DtAccountOpen",
        ST."DtAccountChange"
    from PBI."Account" AA,
        DSTART
        Inner Join PBI."AccountStatus" ST on AA."IDNAccount" = ST."IDNAccount"
    where ST."AccountStatus" in ('1', '2', '3', '5')
        or (
            ST."AccountStatus" in ('8', '9')
            and ST."DtAccountChange" >= DSTART."DtStartYSR"
        )
        and "NrBank" in (
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
),
LSRA as (
    select *
    from SRA
        Left Join AC on SRA."Account" = AC."AccountACC"
),
Q11 as (
    select "NrBank",
        "DtControl",
        "Account"
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
Q22 as (
    select "NrBank",
        "DtControl",
        "Account"
    from LSRA
    EXCEPT
    select "NrBank",
        "DtControl",
        "Account"
    from Q11
),
Q33 as (
    select "NrBank",
        '5|' || VARCHAR_FORMAT("DtControl", 'YYYY-MM-DD') || '|' || "Account" || '|040|' as "LineFile"
    from Q22
)
select *
from Q3
UNION ALL
select *
from Q33
ORDER BY "NrBank",
    "LineFile";