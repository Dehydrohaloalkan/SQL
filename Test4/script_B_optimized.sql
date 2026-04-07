-- Test4: оптимизированный new_script_B.
-- Исправлен баг приоритета операторов: NrBank фильтр теперь применяется к обеим веткам OR.
-- AccountKey вместо CASE в нижней половине (AC CTE).
-- Индексы: IX_ACST_IDNACC, IX_ACCOUNT_NB_BP4_COVER, IX_YTIGOG_NRBANK.

WITH PACC AS (
    SELECT "NrBankMQ" AS "NrBank",
        DATE("DtTmOperation") AS "DtControl",
        "AccountKeyPayer" AS "Account"
    FROM PBI."TableYTIGos" GOS
    WHERE SUBSTR("NrAccountPayer", 5, 4) IN (
            SELECT SUBSTR("CdBank", 1, 4)
            FROM PBI."SPBICBY"
            WHERE PBI."SPBICBY"."NrBank" = GOS."NrBankMQ"
        )
        AND "NrBankMQ" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
    UNION
    SELECT "NrBankMQ" AS "NrBank",
        DATE("DtTmOperation") AS "DtControl",
        "AccountKeyBenef" AS "Account"
    FROM PBI."TableYTIGos" GOS
    WHERE SUBSTR("NrAccountBenef", 5, 4) IN (
            SELECT SUBSTR("CdBank", 1, 4)
            FROM PBI."SPBICBY"
            WHERE PBI."SPBICBY"."NrBank" = GOS."NrBankMQ"
        )
        AND "NrBankMQ" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
),
PAC1 AS (
    SELECT
        CASE
            WHEN PAA."NrEWallet" IS NOT NULL
                THEN PAA."NrAccount" || '|' || PAA."NrEWallet"
            ELSE PAA."NrAccount" || '|'
        END AS "AccountACC",
        PST."AccountStatus",
        PST."DtAccountOpen",
        PST."DtAccountChange"
    FROM PBI."Account" PAA,
        PBI."SPFunctionalDates"
    INNER JOIN PBI."AccountStatus" PST
        ON PAA."IDNAccount" = PST."IDNAccount"
    WHERE (
            PST."AccountStatus" IN ('1', '2', '3', '5')
            OR (
                PST."AccountStatus" IN ('8', '9')
                AND PST."DtAccountChange" >= PBI."SPFunctionalDates"."DtMin3"
            )
        )
        AND PAA."NrBank" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
),
PAC AS (
    SELECT DISTINCT "AccountACC",
        "AccountStatus",
        "DtAccountOpen",
        "DtAccountChange"
    FROM PAC1
),
LPACC AS (
    SELECT *
    FROM PACC
    LEFT JOIN PAC ON PACC."Account" = PAC."AccountACC"
),
Q1 AS (
    SELECT "NrBank",
        "DtControl",
        "Account"
    FROM LPACC
    WHERE (
            "AccountStatus" IN ('1', '2', '3', '5')
            AND "DtAccountOpen" <= "DtControl"
        )
        OR (
            "AccountStatus" IN ('8', '9')
            AND "DtAccountOpen" <= "DtControl"
            AND "DtAccountChange" >= "DtControl"
        )
),
Q2 AS (
    SELECT "NrBank",
        "DtControl",
        "Account"
    FROM LPACC
    EXCEPT
    SELECT "NrBank",
        "DtControl",
        "Account"
    FROM Q1
),
Q3 AS (
    SELECT "NrBank",
        '6|' || VARCHAR_FORMAT("DtControl", 'YYYY-MM-DD') || '|' || "Account" || '|040|' AS "LineFile"
    FROM Q2
),
SRA AS (
    SELECT DISTINCT "NrBank",
        "DtBalance" AS "DtControl",
        CASE
            WHEN "NrEWallet" IS NOT NULL
                THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
            ELSE "NrAccount" || '||' || "CdCurrency"
        END AS "Account"
    FROM PBI."TableYSRGos"
    WHERE "NrBank" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
),
DSTART AS (
    SELECT MIN("LastWorkDayMonth") AS "DtStartYSR"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = '1'
),
AC AS (
    SELECT
        AA."AccountKey" AS "AccountACC",
        ST."AccountStatus",
        ST."DtAccountOpen",
        ST."DtAccountChange"
    FROM PBI."Account" AA,
        DSTART
    INNER JOIN PBI."AccountStatus" ST
        ON AA."IDNAccount" = ST."IDNAccount"
    WHERE (
            ST."AccountStatus" IN ('1', '2', '3', '5')
            OR (
                ST."AccountStatus" IN ('8', '9')
                AND ST."DtAccountChange" >= DSTART."DtStartYSR"
            )
        )
        AND AA."NrBank" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
),
LSRA AS (
    SELECT *
    FROM SRA
    LEFT JOIN AC ON SRA."Account" = AC."AccountACC"
),
Q11 AS (
    SELECT "NrBank",
        "DtControl",
        "Account"
    FROM LSRA
    WHERE (
            "AccountStatus" IN ('1', '2', '3', '5')
            AND "DtAccountOpen" <= "DtControl"
        )
        OR (
            "AccountStatus" IN ('8', '9')
            AND "DtAccountOpen" <= "DtControl"
            AND "DtAccountChange" >= "DtControl"
        )
),
Q22 AS (
    SELECT "NrBank",
        "DtControl",
        "Account"
    FROM LSRA
    EXCEPT
    SELECT "NrBank",
        "DtControl",
        "Account"
    FROM Q11
),
Q33 AS (
    SELECT "NrBank",
        '5|' || VARCHAR_FORMAT("DtControl", 'YYYY-MM-DD') || '|' || "Account" || '|040|' AS "LineFile"
    FROM Q22
)
SELECT *
FROM Q3
UNION ALL
SELECT *
FROM Q33
ORDER BY "NrBank", "LineFile";
