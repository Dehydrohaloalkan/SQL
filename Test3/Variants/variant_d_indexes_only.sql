-- Вариант D: ОРИГИНАЛЬНЫЙ запрос + ТОЛЬКО индексы.
-- Без BalPrefix*, без AccountKey, без SPBalAccount4.
-- Индексы: IX_ACCOUNT_NB_BP4_COVER, IX_ACST_IDNACC_COVER, IX_INFOYSR_DT_BP4.
-- Ожидание: Account — MATCHCOLS=1 (NrBank), SUBSTR не sargable для BalPrefix4.
--           AccountStatus — covering index работает (index-only probe по IDNAccount).
--           InfoYSR — MATCHCOLS=1 (DtBalance), SUBSTR не sargable для BalPrefix4.
--           По сути проверяем: сколько даёт один только covering index на AccountStatus.

WITH AA AS (
    SELECT
        "IDNAccount",
        "NrBank",
        CASE
            WHEN SUBSTR("NrAccount", 9, 4) = '3119' AND "NrEWallet" IS NOT NULL
                THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
            ELSE "NrAccount" || '||' || "CdCurrency"
        END AS "Account"
    FROM PBI."Account"
    WHERE "NrBank" IN (
            SELECT "NrBank"
            FROM PBI."SPBICBY"
            WHERE "BICStatus" IN ('0', '1')
              AND "CdActRecord" = '0'
        )
      AND "NrBank" <> '042'
      AND "NrBank" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
      AND (
            SUBSTR("NrAccount", 9, 4) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '4' AND "PrYSR" = '1'
            )
            OR SUBSTR("NrAccount", 9, 3) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '3' AND "PrYSR" = '1'
            )
            OR SUBSTR("NrAccount", 9, 2) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '2' AND "PrYSR" = '1'
            )
            OR SUBSTR("NrAccount", 9, 1) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '1' AND "PrYSR" = '1'
            )
        )
),
AC AS (
    SELECT
        AA.*,
        PBI."AccountStatus"."AccountStatus",
        PBI."AccountStatus"."DtAccountOpen",
        PBI."AccountStatus"."DtAccountChange"
    FROM AA
    INNER JOIN PBI."AccountStatus"
        ON AA."IDNAccount" = PBI."AccountStatus"."IDNAccount"
       AND NOT (
            SUBSTR("Account", 9, 4) = '3119'
            AND "StatusOwner" IN ('INP', 'IZP')
        )
),
D AS (
    SELECT MAX("LastWorkDayMonth") AS "DtBalance"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = '1'
),
AAC AS (
    SELECT *
    FROM AC, D
    WHERE (
            AC."DtAccountOpen" <= D."DtBalance"
            AND AC."AccountStatus" IN ('1', '2', '3', '5')
        )
        OR (
            AC."DtAccountOpen" <= D."DtBalance"
            AND AC."DtAccountChange" >= D."DtBalance"
            AND AC."AccountStatus" IN ('8', '9')
        )
),
SRA AS (
    SELECT
        CASE
            WHEN SUBSTR("NrAccount", 9, 4) = '3119' AND "NrEWallet" IS NOT NULL
                THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
            ELSE "NrAccount" || '||' || "CdCurrency"
        END AS "Account"
    FROM PBI."InfoYSR"
    WHERE "DtBalance" IN (SELECT "DtBalance" FROM D)
      AND (
            SUBSTR("NrAccount", 9, 4) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '4' AND "PrYSR" = '1'
            )
            OR SUBSTR("NrAccount", 9, 3) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '3' AND "PrYSR" = '1'
            )
            OR SUBSTR("NrAccount", 9, 2) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '2' AND "PrYSR" = '1'
            )
            OR SUBSTR("NrAccount", 9, 1) IN (
                SELECT "BalAccount" FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = '1' AND "PrYSR" = '1'
            )
        )
),
AACS AS (
    SELECT DISTINCT "Account"
    FROM AAC
    EXCEPT
    SELECT DISTINCT "Account"
    FROM SRA
),
Q1 AS (
    SELECT DISTINCT "NrBank", "DtBalance", "Account"
    FROM AAC
    WHERE "Account" IN (SELECT "Account" FROM AACS)
)
SELECT
    "NrBank",
    '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account"
        || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' AS "LineFile"
FROM Q1;
