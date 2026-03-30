-- DB2 for z/OS: представление над PBI."InfoYSR" с вычисляемым столбцом "Account" (та же конкатенация, что в script.sql)
-- Выполнять: после 01_v_account_with_account.sql, до script_final.sql

CREATE OR REPLACE VIEW PBI.V_INFOYSR_WITH_ACCOUNT AS
SELECT
    I."IDNInfoYSR",
    I."IDNAccount",
    I."IDNInputFile",
    I."Number",
    I."NrBank",
    I."CdBank",
    I."NrAccount",
    SUBSTR(I."NrAccount", 9, 1) AS "BalPrefix1",
    SUBSTR(I."NrAccount", 9, 2) AS "BalPrefix2",
    SUBSTR(I."NrAccount", 9, 3) AS "BalPrefix3",
    SUBSTR(I."NrAccount", 9, 4) AS "BalPrefix4",
    I."NrEWallet",
    I."CdCurrency",
    I."PrBalance",
    I."DtBalance",
    I."SumCurrency",
    I."SumBYN",
    I."DtOperation",
    I."PrOperation",
    I."SumOperation",
    I."DtTmProcessing",
    I."BalanceStatus",
    CASE
        WHEN SUBSTR(I."NrAccount", 9, 4) = '3119'
         AND I."NrEWallet" IS NOT NULL
            THEN I."NrAccount" || '|' || I."NrEWallet" || '|' || I."CdCurrency"
        ELSE I."NrAccount" || '||' || I."CdCurrency"
    END AS "Account"
FROM PBI."InfoYSR" I;

/*
DROP VIEW PBI.V_INFOYSR_WITH_ACCOUNT;
CREATE VIEW PBI.V_INFOYSR_WITH_ACCOUNT AS
SELECT
    I."IDNInfoYSR",
    I."IDNAccount",
    I."IDNInputFile",
    I."Number",
    I."NrBank",
    I."CdBank",
    I."NrAccount",
    SUBSTR(I."NrAccount", 9, 1) AS "BalPrefix1",
    SUBSTR(I."NrAccount", 9, 2) AS "BalPrefix2",
    SUBSTR(I."NrAccount", 9, 3) AS "BalPrefix3",
    SUBSTR(I."NrAccount", 9, 4) AS "BalPrefix4",
    I."NrEWallet",
    I."CdCurrency",
    I."PrBalance",
    I."DtBalance",
    I."SumCurrency",
    I."SumBYN",
    I."DtOperation",
    I."PrOperation",
    I."SumOperation",
    I."DtTmProcessing",
    I."BalanceStatus",
    CASE
        WHEN SUBSTR(I."NrAccount", 9, 4) = '3119'
         AND I."NrEWallet" IS NOT NULL
            THEN I."NrAccount" || '|' || I."NrEWallet" || '|' || I."CdCurrency"
        ELSE I."NrAccount" || '||' || I."CdCurrency"
    END AS "Account"
FROM PBI."InfoYSR" I;
*/
