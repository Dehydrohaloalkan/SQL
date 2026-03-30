-- DB2 for z/OS: представление над PBI."Account" с вычисляемым столбцом "Account" (конкатенация как в script.sql)
-- Выполнять: до итогового запроса (script_final.sql)
-- Если CREATE OR REPLACE VIEW недоступен: раскомментировать блок DROP + CREATE внизу файла

CREATE OR REPLACE VIEW PBI.V_ACCOUNT_WITH_ACCOUNT AS
SELECT
    A."IDNAccount",
    A."NrBank",
    A."CdBank",
    A."NrAccount",
    SUBSTR(A."NrAccount", 9, 1) AS "BalPrefix1",
    SUBSTR(A."NrAccount", 9, 2) AS "BalPrefix2",
    SUBSTR(A."NrAccount", 9, 3) AS "BalPrefix3",
    SUBSTR(A."NrAccount", 9, 4) AS "BalPrefix4",
    A."CdCurrency",
    A."NrEWallet",
    A."AccountStatus",
    A."IDNAccountStatus",
    A."IDNInfoYSB",
    A."DtTmProcessing",
    CASE
        WHEN SUBSTR(A."NrAccount", 9, 4) = '3119'
         AND A."NrEWallet" IS NOT NULL
            THEN A."NrAccount" || '|' || A."NrEWallet" || '|' || A."CdCurrency"
        ELSE A."NrAccount" || '||' || A."CdCurrency"
    END AS "Account"
FROM PBI."Account" A;

/*
-- Вариант без OR REPLACE:
DROP VIEW PBI.V_ACCOUNT_WITH_ACCOUNT;
CREATE VIEW PBI.V_ACCOUNT_WITH_ACCOUNT AS
SELECT
    A."IDNAccount",
    A."NrBank",
    A."CdBank",
    A."NrAccount",
    SUBSTR(A."NrAccount", 9, 1) AS "BalPrefix1",
    SUBSTR(A."NrAccount", 9, 2) AS "BalPrefix2",
    SUBSTR(A."NrAccount", 9, 3) AS "BalPrefix3",
    SUBSTR(A."NrAccount", 9, 4) AS "BalPrefix4",
    A."CdCurrency",
    A."NrEWallet",
    A."AccountStatus",
    A."IDNAccountStatus",
    A."IDNInfoYSB",
    A."DtTmProcessing",
    CASE
        WHEN SUBSTR(A."NrAccount", 9, 4) = '3119'
         AND A."NrEWallet" IS NOT NULL
            THEN A."NrAccount" || '|' || A."NrEWallet" || '|' || A."CdCurrency"
        ELSE A."NrAccount" || '||' || A."CdCurrency"
    END AS "Account"
FROM PBI."Account" A;
*/
