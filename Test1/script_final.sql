-- Итоговый запрос: эквивалент ../script.sql, но с использованием view (конкатенация вынесена в V_ACCOUNT / V_INFOYSR)
-- Порядок развёртывания: 01_v_account_with_account.sql → 02_v_infoysr_with_account.sql → 03_grant_select.sql → этот файл

WITH AA AS (
    SELECT
        V."IDNAccount",
        V."NrBank",
        V."Account",
        V."BalPrefix1",
        V."BalPrefix2",
        V."BalPrefix3",
        V."BalPrefix4"
    FROM PBI.V_ACCOUNT_WITH_ACCOUNT V
    WHERE V."NrBank" IN (
        SELECT "NrBank"
        FROM PBI."SPBICBY"
        WHERE "BICStatus" IN ('0', '1')
          AND "CdActRecord" = '0'
    )
      AND V."NrBank" <> '042'
      AND V."NrBank" IN (
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
          V."BalPrefix4" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '4'
                AND "PrYSR" = '1'
          )
          OR V."BalPrefix3" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '3'
                AND "PrYSR" = '1'
          )
          OR V."BalPrefix2" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '2'
                AND "PrYSR" = '1'
          )
          OR V."BalPrefix1" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '1'
                AND "PrYSR" = '1'
          )
      )
),
AC AS (
    SELECT
        AA.*,
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
    WHERE "PrYSR_Month" = '1'
),
AAC AS (
    SELECT *
    FROM AC
    CROSS JOIN D
    WHERE
        (
            AC."DtAccountOpen" <= D."DtBalance"
            AND AC."AccountStatus" IN ('1', '2', '3', '5')
        )
        OR
        (
            AC."DtAccountOpen" <= D."DtBalance"
            AND AC."DtAccountChange" >= D."DtBalance"
            AND AC."AccountStatus" IN ('8', '9')
        )
),
SRA AS (
    SELECT
        VI."Account",
        VI."BalPrefix1",
        VI."BalPrefix2",
        VI."BalPrefix3",
        VI."BalPrefix4"
    FROM PBI.V_INFOYSR_WITH_ACCOUNT VI
    WHERE VI."DtBalance" IN (SELECT D."DtBalance" FROM D)
      AND (
          VI."BalPrefix4" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '4'
                AND "PrYSR" = '1'
          )
          OR VI."BalPrefix3" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '3'
                AND "PrYSR" = '1'
          )
          OR VI."BalPrefix2" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '2'
                AND "PrYSR" = '1'
          )
          OR VI."BalPrefix1" IN (
              SELECT "BalAccount"
              FROM PBI."SPAccountControl"
              WHERE "count_BalAccount" = '1'
                AND "PrYSR" = '1'
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
    '4|' || VARCHAR_FORMAT("DtBalance", 'YYYY-MM-DD') || '|' || "Account" || '|090|За отчетную дату не получена информация об остатке д/с на счете/эл.денег в эл.кошельке в файле YSR' AS "LineFile"
FROM Q1;
