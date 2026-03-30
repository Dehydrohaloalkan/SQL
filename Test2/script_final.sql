-- Test2: тот же смысл, что ../script.sql, но с использованием generated columns:
-- BalPrefix1..4, AccountKey (конкатенация вынесена в таблицу)
-- Предварительно: 01_alter_account_bal_prefix.sql, 02_alter_infoysr_bal_prefix.sql, 03_create_indexes.sql

WITH AA AS (
    SELECT
        A."IDNAccount",
        A."NrBank",
        A."AccountKey" AS "Account",
        A."BalPrefix4"
    FROM PBI."Account" A
    WHERE A."NrBank" IN (
            SELECT "NrBank"
            FROM PBI."SPBICBY"
            WHERE "BICStatus" IN ('0', '1')
              AND "CdActRecord" = '0'
        )
      AND A."NrBank" <> '042'
      AND A."NrBank" IN (
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
      AND (
            A."BalPrefix4" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 4
                  AND "PrYSR" = 1
            )
            OR A."BalPrefix3" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 3
                  AND "PrYSR" = 1
            )
            OR A."BalPrefix2" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 2
                  AND "PrYSR" = 1
            )
            OR A."BalPrefix1" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 1
                  AND "PrYSR" = 1
            )
        )
),
AC AS (
    SELECT
        AA."IDNAccount",
        AA."NrBank",
        AA."Account",
        S."AccountStatus",
        S."DtAccountOpen",
        S."DtAccountChange"
    FROM AA
    INNER JOIN PBI."AccountStatus" S
        ON AA."IDNAccount" = S."IDNAccount"
       AND NOT (
            AA."BalPrefix4" = '3119'
            AND S."StatusOwner" IN ('INP', 'IZP')
        )
),
D AS (
    SELECT MAX("LastWorkDayMonth") AS "DtBalance"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = 1
),
AAC AS (
    SELECT *
    FROM AC
       , D
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
        I."AccountKey" AS "Account"
    FROM PBI."InfoYSR" I
    WHERE I."DtBalance" IN (
            SELECT D."DtBalance"
            FROM D
        )
      AND (
            I."BalPrefix4" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 4
                  AND "PrYSR" = 1
            )
            OR I."BalPrefix3" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 3
                  AND "PrYSR" = 1
            )
            OR I."BalPrefix2" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 2
                  AND "PrYSR" = 1
            )
            OR I."BalPrefix1" IN (
                SELECT "BalAccount"
                FROM PBI."SPAccountControl"
                WHERE "count_BalAccount" = 1
                  AND "PrYSR" = 1
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
    SELECT DISTINCT
        "NrBank",
        "DtBalance",
        "Account"
    FROM AAC
    WHERE "Account" IN (
            SELECT "Account"
            FROM AACS
        )
)
SELECT
    "NrBank",
    '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account"
        || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' AS "LineFile"
FROM Q1;
