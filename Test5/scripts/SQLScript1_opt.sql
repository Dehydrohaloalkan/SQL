WITH D AS (
    SELECT MAX("LastWorkDayMonth") AS "DtBalance"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = '1'
),
AA AS (
    SELECT AA."IDNAccount",
        AA."NrBank",
        AA."NrEWallet",
        AA."NrAccount",
        AA."CdCurrency",
        ST."AccountStatus",
        ST."DtAccountOpen",
        ST."DtAccountChange"
    FROM PBI."Account" AA
    INNER JOIN PBI."AccountStatus" ST
        ON AA."IDNAccount" = ST."IDNAccount"
    WHERE AA."NrBank" <> '042'
        AND EXISTS (
            SELECT 1 FROM PBI."SPBICBY" B
            WHERE B."NrBank" = AA."NrBank"
              AND B."CdActRecord" = '0'
        )
        AND (
            AA."BalAccount2" IN (
                SELECT "NrAccountOrder" FROM PBI."SPAccGosInclude"
                WHERE "PrYSR" = 1 AND "count_NrAccount" = 2
            )
            OR AA."BalAccount3" IN (
                SELECT "NrAccountOrder" FROM PBI."SPAccGosInclude"
                WHERE "PrYSR" = 1 AND "count_NrAccount" = 3
            )
            OR AA."BalAccount4" IN (
                SELECT "NrAccountOrder" FROM PBI."SPAccGosInclude"
                WHERE "PrYSR" = 1 AND "count_NrAccount" = 4
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM PBI."SPAccGosExclude" E
            WHERE E."PrYSR" = 1
              AND ((E."count_NrAccount" = 2 AND E."NrAccountOrder" = AA."BalAccount2")
                OR (E."count_NrAccount" = 3 AND E."NrAccountOrder" = AA."BalAccount3")
                OR (E."count_NrAccount" = 4 AND E."NrAccountOrder" = AA."BalAccount4"))
        )
        AND (
            ST."StatusOwner" NOT IN ('INP', 'IZP')
            OR NOT EXISTS (
                SELECT 1 FROM PBI."SPAccGosExclude" E
                WHERE E."PrYSR" = 2
                  AND ((E."count_NrAccount" = 2 AND E."NrAccountOrder" = AA."BalAccount2")
                    OR (E."count_NrAccount" = 3 AND E."NrAccountOrder" = AA."BalAccount3")
                    OR (E."count_NrAccount" = 4 AND E."NrAccountOrder" = AA."BalAccount4"))
            )
        )
),
AAC AS (
    SELECT AA."NrBank", D."DtBalance", AA."NrAccount", AA."NrEWallet", AA."CdCurrency"
    FROM AA, D
    WHERE (
            AA."AccountStatus" IN ('1', '2', '3', '5')
            AND AA."DtAccountOpen" <= D."DtBalance"
        )
        OR (
            AA."AccountStatus" IN ('8', '9')
            AND AA."DtAccountOpen" <= D."DtBalance"
            AND AA."DtAccountChange" >= D."DtBalance"
        )
),
QREZ AS (
    SELECT DISTINCT AAC."NrBank",
        AAC."DtBalance",
        CASE
            WHEN AAC."NrEWallet" IS NOT NULL
                THEN AAC."NrAccount" || '|' || AAC."NrEWallet" || '|' || AAC."CdCurrency"
            ELSE AAC."NrAccount" || '||' || AAC."CdCurrency"
        END AS "Account"
    FROM AAC
    WHERE NOT EXISTS (
        SELECT 1
        FROM PBI."InfoYSR" Y
        WHERE Y."DtBalance" = AAC."DtBalance"
          AND Y."NrBank"    = AAC."NrBank"
          AND Y."NrAccount" = AAC."NrAccount"
          AND Y."CdCurrency"= AAC."CdCurrency"
          AND ((Y."NrEWallet" = AAC."NrEWallet")
            OR (Y."NrEWallet" IS NULL AND AAC."NrEWallet" IS NULL))
    )
)
SELECT "NrBank",
    '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account"
        || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' AS "LineFile"
FROM QREZ
ORDER BY "NrBank", "LineFile";
