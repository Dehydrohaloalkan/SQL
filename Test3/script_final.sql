-- Test3 v3: SRA через CROSS JOIN + INNER JOIN для MATCHCOLS=2 на InfoYSR.
-- Ключевая идея: D × SPAccountControl → driving table (1 дата × ~25 значений = ~25 строк),
-- каждая строка делает index probe на InfoYSR по (DtBalance, BalPrefixN) = MATCHCOLS=2.
-- AA на Account оставлен с OR — индексы на Account создать нельзя.

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
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
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
    SELECT I."AccountKey" AS "Account"
    FROM D
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPAccountControl"
        WHERE "count_BalAccount" = 4 AND "PrYSR" = 1
    ) C
    INNER JOIN PBI."InfoYSR" I
        ON I."DtBalance" = D."DtBalance"
       AND I."BalPrefix4" = C."BalAccount"
    UNION ALL
    SELECT I."AccountKey" AS "Account"
    FROM D
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPAccountControl"
        WHERE "count_BalAccount" = 3 AND "PrYSR" = 1
    ) C
    INNER JOIN PBI."InfoYSR" I
        ON I."DtBalance" = D."DtBalance"
       AND I."BalPrefix3" = C."BalAccount"
    UNION ALL
    SELECT I."AccountKey" AS "Account"
    FROM D
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPAccountControl"
        WHERE "count_BalAccount" = 2 AND "PrYSR" = 1
    ) C
    INNER JOIN PBI."InfoYSR" I
        ON I."DtBalance" = D."DtBalance"
       AND I."BalPrefix2" = C."BalAccount"
    UNION ALL
    SELECT I."AccountKey" AS "Account"
    FROM D
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPAccountControl"
        WHERE "count_BalAccount" = 1 AND "PrYSR" = 1
    ) C
    INNER JOIN PBI."InfoYSR" I
        ON I."DtBalance" = D."DtBalance"
       AND I."BalPrefix1" = C."BalAccount"
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
    WHERE "Account" IN (SELECT "Account" FROM AACS)
)
SELECT
    "NrBank",
    '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account"
        || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' AS "LineFile"
FROM Q1;
