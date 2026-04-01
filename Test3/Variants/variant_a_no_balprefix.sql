-- Вариант A: БЕЗ BalPrefix4 (используется SUBSTR).
-- С AccountKey (материализованное поле) и SPBalAccount4 (раскрытая таблица).
-- Индексы: IX_ACCOUNT_NB_BP4_COVER, IX_ACST_IDNACC_COVER, IX_INFOYSR_DT_BP4.
-- Ожидание: MATCHCOLS=1 на Account (SUBSTR не sargable для BalPrefix4 в индексе).
--           AccountStatus covering index работает.

WITH D AS (
    SELECT MAX("LastWorkDayMonth") AS "DtBalance"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = 1
),
AA AS (
    SELECT
        A."IDNAccount",
        A."NrBank",
        A."AccountKey" AS "Account"
    FROM (
        SELECT "NrBank"
        FROM PBI."SPBICBY"
        WHERE "BICStatus" IN ('0', '1')
          AND "CdActRecord" = '0'
          AND "NrBank" <> '042'
          AND "NrBank" IN (
                '108','110','117','175','182','222','226','270','272','288','303','333',
                '345','369','704','735','739','742','749','765','782','795','820','964'
            )
    ) BNK
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPBalAccount4"
        WHERE "PrYSR" = 1
    ) C
    INNER JOIN PBI."Account" A
        ON A."NrBank" = BNK."NrBank"
       AND SUBSTR(A."NrAccount", 9, 4) = C."BalAccount"
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
            SUBSTR(AA."Account", 9, 4) = '3119'
            AND S."StatusOwner" IN ('INP', 'IZP')
        )
),
AAC AS (
    SELECT AC.*, D."DtBalance"
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
    SELECT I."AccountKey" AS "Account"
    FROM D
    CROSS JOIN (
        SELECT "BalAccount"
        FROM PBI."SPBalAccount4"
        WHERE "PrYSR" = 1
    ) C
    INNER JOIN PBI."InfoYSR" I
        ON I."DtBalance" = D."DtBalance"
       AND SUBSTR(I."NrAccount", 9, 4) = C."BalAccount"
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
