-- Test4: оптимизированный new_script_A.
-- BalPrefix4 вместо SUBSTR, AccountKey вместо CASE, SPBalAccount4 вместо SPAccountControl OR.
-- CROSS JOIN паттерн для MATCHCOLS=2 на Account.

WITH D AS (
    SELECT MAX("LastWorkDayMonth") AS "DtBalance"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = '1'
),
AA AS (
    SELECT
        A."IDNAccount",
        A."NrBank",
        A."BalPrefix4" AS "BalAcc",
        A."AccountKey" AS "Account"
    FROM (
        SELECT "BalAccount"
        FROM PBI."SPBalAccount4"
        WHERE "PrYSR" = 1
    ) C
    INNER JOIN PBI."Account" A
        ON A."BalPrefix4" = C."BalAccount"
    WHERE A."NrBank" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
      AND A."NrBank" <> '042'
),
AC AS (
    SELECT AA.*,
        ST."AccountStatus",
        ST."DtAccountOpen",
        ST."DtAccountChange"
    FROM AA
    INNER JOIN PBI."AccountStatus" ST
        ON AA."IDNAccount" = ST."IDNAccount"
    WHERE NOT (
        AA."BalAcc" = 3119
        AND ST."StatusOwner" IN ('INP', 'IZP')
    )
),
AAC AS (
    SELECT *
    FROM AC, D
    WHERE (
            AC."AccountStatus" IN ('1', '2', '3', '5')
            AND AC."DtAccountOpen" <= D."DtBalance"
        )
        OR (
            AC."AccountStatus" IN ('8', '9')
            AND AC."DtAccountOpen" <= D."DtBalance"
            AND AC."DtAccountChange" >= D."DtBalance"
        )
),
SRA AS (
    SELECT I."NrBank",
        D."DtBalance",
        I."AccountKey" AS "Account"
    FROM D
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPBalAccount4"
        WHERE "PrYSR" = 1
    ) C
    INNER JOIN PBI."InfoYSR" I
        ON I."DtBalance" = D."DtBalance"
       AND I."BalPrefix4" = C."BalAccount"
    WHERE I."NrBank" IN (
            '108','110','117','175','182','222','226','270','272','288','303','333',
            '345','369','704','735','739','742','749','765','782','795','820','964'
        )
),
Q1 AS (
    SELECT "NrBank",
        "DtBalance",
        "Account"
    FROM AAC
    EXCEPT
    SELECT "NrBank",
        "DtBalance",
        "Account"
    FROM SRA
),
QREZ AS (
    SELECT "NrBank",
        '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account" || '|090|' AS "LineFile"
    FROM Q1
)
SELECT *
FROM QREZ
ORDER BY "NrBank", "LineFile";
