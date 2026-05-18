WITH PACC AS (
    SELECT GOS."NrBankMQ" AS "NrBank",
        DATE(GOS."DtTmOperation") AS "DtControl",
        GOS."NrAccount4Payer" AS "BalAccount4",
        GOS."NrAccountPayer" AS "Account",
        GOS."NrEWalletPayer" AS "NrEWallet"
    FROM PBI."TableYTIGos" GOS
    WHERE EXISTS (
        SELECT 1 FROM PBI."SPBICBY" B
        WHERE B."NrBank" = GOS."NrBankMQ"
          AND SUBSTR(B."CdBank", 1, 4) = SUBSTR(GOS."NrAccountPayer", 5, 4)
    )
    UNION
    SELECT GOS."NrBankMQ",
        DATE(GOS."DtTmOperation"),
        GOS."NrAccount4Benef",
        GOS."NrAccountBenef",
        GOS."NrEWalletBenef"
    FROM PBI."TableYTIGos" GOS
    WHERE EXISTS (
        SELECT 1 FROM PBI."SPBICBY" B
        WHERE B."NrBank" = GOS."NrBankMQ"
          AND SUBSTR(B."CdBank", 1, 4) = SUBSTR(GOS."NrAccountBenef", 5, 4)
    )
),
FD AS (
    SELECT "DtMin3" FROM PBI."SPFunctionalDates"
),
DSTART AS (
    SELECT MIN("LastWorkDayMonth") AS "DtStartYSR"
    FROM PBI."SPDatesControl"
    WHERE "PrYSR_Month" = '1'
),
PAC AS (
    SELECT DISTINCT
        PAA."NrAccount" AS "AccountACC",
        PAA."NrEWallet" AS "NrEWalletACC",
        PST."AccountStatus",
        PST."DtAccountOpen",
        PST."DtAccountChange"
    FROM PBI."Account" PAA
    INNER JOIN PBI."AccountStatus" PST
        ON PAA."IDNAccount" = PST."IDNAccount"
    CROSS JOIN FD
    WHERE PAA."NrBank" <> '042'
      AND (
            PST."AccountStatus" IN ('1', '2', '3', '5')
            OR (PST."AccountStatus" IN ('8', '9') AND PST."DtAccountChange" >= FD."DtMin3")
      )
      AND EXISTS (
          SELECT 1 FROM PBI."SPBICBY" B
          WHERE B."NrBank" = PAA."NrBank"
            AND B."BICStatus" IN ('0', '1')
            AND B."CdActRecord" = '0'
      )
),
LPACC AS (
    SELECT PACC."NrBank", PACC."DtControl", PACC."BalAccount4",
           PACC."Account", PACC."NrEWallet",
           PAC."AccountStatus", PAC."DtAccountOpen", PAC."DtAccountChange"
    FROM PACC
    INNER JOIN PAC
        ON PACC."Account" = PAC."AccountACC"
       AND PACC."NrEWallet" = PAC."NrEWalletACC"
    WHERE PACC."NrEWallet" IS NOT NULL
      AND PAC."NrEWalletACC" IS NOT NULL
    UNION
    SELECT PACC."NrBank", PACC."DtControl", PACC."BalAccount4",
           PACC."Account", PACC."NrEWallet",
           PAC."AccountStatus", PAC."DtAccountOpen", PAC."DtAccountChange"
    FROM PACC
    INNER JOIN PAC
        ON PACC."Account" = PAC."NrEWalletACC"
    WHERE PACC."NrEWallet" IS NULL
      AND PACC."BalAccount4" <> '3119'
      AND PAC."NrEWalletACC" IS NOT NULL
    UNION
    SELECT PACC."NrBank", PACC."DtControl", PACC."BalAccount4",
           PACC."Account", PACC."NrEWallet",
           PAC."AccountStatus", PAC."DtAccountOpen", PAC."DtAccountChange"
    FROM PACC
    INNER JOIN PAC
        ON PACC."Account" = PAC."AccountACC"
    WHERE PACC."NrEWallet" IS NULL
      AND PAC."NrEWalletACC" IS NULL
),
Q1 AS (
    SELECT "NrBank", "DtControl", "Account", "NrEWallet"
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
Q3 AS (
    SELECT DISTINCT PACC."NrBank",
        '6|' || VARCHAR_FORMAT(PACC."DtControl", 'YYYY-MM-DD') || '|'
            || CASE WHEN PACC."NrEWallet" IS NOT NULL
                    THEN PACC."Account" || '|' || PACC."NrEWallet"
                    ELSE PACC."Account" || '|'
               END
            || '|040|На отчетную дату отсутствуют сведения о номере лицевого счета/номере счета аналит.учета (эл.кошелька) в АИС ПБИ' AS "LineFile"
    FROM PACC
    WHERE NOT EXISTS (
        SELECT 1 FROM Q1
        WHERE Q1."NrBank"    = PACC."NrBank"
          AND Q1."DtControl" = PACC."DtControl"
          AND Q1."Account"   = PACC."Account"
          AND ((Q1."NrEWallet" = PACC."NrEWallet")
            OR (Q1."NrEWallet" IS NULL AND PACC."NrEWallet" IS NULL))
    )
),
SRA AS (
    SELECT "NrBank",
        "DtBalance" AS "DtControl",
        "NrEWallet",
        "NrAccount",
        "CdCurrency"
    FROM PBI."TableYSRGos"
),
AC AS (
    SELECT AA."NrEWallet" AS "NrEWalletACC",
        AA."NrAccount" AS "AccountACC",
        AA."CdCurrency" AS "CdCurrencyACC",
        ST."AccountStatus",
        ST."DtAccountOpen",
        ST."DtAccountChange"
    FROM PBI."Account" AA
    INNER JOIN PBI."AccountStatus" ST
        ON AA."IDNAccount" = ST."IDNAccount"
    CROSS JOIN DSTART
    WHERE AA."NrBank" <> '042'
      AND (
            ST."AccountStatus" IN ('1', '2', '3', '5')
            OR (ST."AccountStatus" IN ('8', '9') AND ST."DtAccountChange" >= DSTART."DtStartYSR")
      )
      AND EXISTS (
          SELECT 1 FROM PBI."SPBICBY" B
          WHERE B."NrBank" = AA."NrBank"
            AND B."BICStatus" IN ('0', '1')
            AND B."CdActRecord" = '0'
      )
),
LSRA AS (
    SELECT SRA."NrBank", SRA."DtControl", SRA."NrAccount",
           SRA."NrEWallet", SRA."CdCurrency",
           AC."AccountStatus", AC."DtAccountOpen", AC."DtAccountChange"
    FROM SRA
    INNER JOIN AC
        ON SRA."NrAccount"  = AC."AccountACC"
       AND SRA."CdCurrency" = AC."CdCurrencyACC"
       AND SRA."NrEWallet"  = AC."NrEWalletACC"
    WHERE SRA."NrEWallet" IS NOT NULL
      AND AC."NrEWalletACC" IS NOT NULL
    UNION
    SELECT SRA."NrBank", SRA."DtControl", SRA."NrAccount",
           SRA."NrEWallet", SRA."CdCurrency",
           AC."AccountStatus", AC."DtAccountOpen", AC."DtAccountChange"
    FROM SRA
    INNER JOIN AC
        ON SRA."NrAccount"  = AC."AccountACC"
       AND SRA."CdCurrency" = AC."CdCurrencyACC"
    WHERE SRA."NrEWallet" IS NULL
      AND AC."NrEWalletACC" IS NULL
),
Q11 AS (
    SELECT "NrBank", "DtControl", "NrAccount", "NrEWallet", "CdCurrency"
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
Q33 AS (
    SELECT DISTINCT SRA."NrBank",
        '5|' || VARCHAR_FORMAT(SRA."DtControl", 'YYYY-MM-DD') || '|'
            || CASE WHEN SRA."NrEWallet" IS NOT NULL
                    THEN SRA."NrAccount" || '|' || SRA."NrEWallet" || '|' || SRA."CdCurrency"
                    ELSE SRA."NrAccount" || '||' || SRA."CdCurrency"
               END
            || '|040|На отчетную дату отсутствуют сведения о номере лицевого счета/номере счета аналит.учета (эл.кошелька) в АИС ПБИ' AS "LineFile"
    FROM SRA
    WHERE NOT EXISTS (
        SELECT 1 FROM Q11
        WHERE Q11."NrBank"     = SRA."NrBank"
          AND Q11."DtControl"  = SRA."DtControl"
          AND Q11."NrAccount"  = SRA."NrAccount"
          AND Q11."CdCurrency" = SRA."CdCurrency"
          AND ((Q11."NrEWallet" = SRA."NrEWallet")
            OR (Q11."NrEWallet" IS NULL AND SRA."NrEWallet" IS NULL))
    )
)
SELECT * FROM Q3
UNION ALL
SELECT * FROM Q33
ORDER BY "NrBank", "LineFile";
