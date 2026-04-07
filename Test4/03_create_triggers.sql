--#SET TERMINATOR ~
-- Test4: триггеры поддержания BalPrefix4 и AccountKey при INSERT/UPDATE.
-- Стиль: AFTER + BEGIN ATOMIC (как в рабочем окружении).

-- =====================================================================
-- Account
-- =====================================================================

CREATE TRIGGER PBI.TR_ACCOUNT_AI_MAT
AFTER INSERT
ON PBI."Account"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."Account" A
    SET "BalPrefix4" = CAST(SUBSTR(N."NrAccount", 9, 4) AS SMALLINT),
        "AccountKey" = CASE
            WHEN SUBSTR(N."NrAccount", 9, 4) = '3119' AND N."NrEWallet" IS NOT NULL
                THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
            ELSE N."NrAccount" || '||' || N."CdCurrency"
        END
    WHERE A."IDNAccount" = N."IDNAccount";
END ~

CREATE TRIGGER PBI.TR_ACCOUNT_AU_MAT
AFTER UPDATE OF "NrAccount", "NrEWallet", "CdCurrency"
ON PBI."Account"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."Account" A
    SET "BalPrefix4" = CAST(SUBSTR(N."NrAccount", 9, 4) AS SMALLINT),
        "AccountKey" = CASE
            WHEN SUBSTR(N."NrAccount", 9, 4) = '3119' AND N."NrEWallet" IS NOT NULL
                THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
            ELSE N."NrAccount" || '||' || N."CdCurrency"
        END
    WHERE A."IDNAccount" = N."IDNAccount";
END ~

-- =====================================================================
-- InfoYSR
-- =====================================================================

CREATE TRIGGER PBI.TR_INFOYSR_AI_MAT
AFTER INSERT
ON PBI."InfoYSR"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."InfoYSR" I
    SET "BalPrefix4" = CAST(SUBSTR(N."NrAccount", 9, 4) AS SMALLINT),
        "AccountKey" = CASE
            WHEN SUBSTR(N."NrAccount", 9, 4) = '3119' AND N."NrEWallet" IS NOT NULL
                THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
            ELSE N."NrAccount" || '||' || N."CdCurrency"
        END
    WHERE I."IDNInfoYSR" = N."IDNInfoYSR";
END ~

CREATE TRIGGER PBI.TR_INFOYSR_AU_MAT
AFTER UPDATE OF "NrAccount", "NrEWallet", "CdCurrency"
ON PBI."InfoYSR"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."InfoYSR" I
    SET "BalPrefix4" = CAST(SUBSTR(N."NrAccount", 9, 4) AS SMALLINT),
        "AccountKey" = CASE
            WHEN SUBSTR(N."NrAccount", 9, 4) = '3119' AND N."NrEWallet" IS NOT NULL
                THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
            ELSE N."NrAccount" || '||' || N."CdCurrency"
        END
    WHERE I."IDNInfoYSR" = N."IDNInfoYSR";
END ~

-- =====================================================================
-- TableYTIGos (BEFORE-триггеры: PK не нужен, SET прямо в NEW-строку)
-- =====================================================================

CREATE TRIGGER PBI.TR_YTIGOG_BI_KEYS
BEFORE INSERT
ON PBI."TableYTIGos"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    SET N."AccountKeyPayer" = CASE
            WHEN N."NrEWalletPayer" IS NOT NULL
                THEN N."NrAccountPayer" || '|' || N."NrEWalletPayer"
            ELSE N."NrAccountPayer" || '|'
        END;
    SET N."AccountKeyBenef" = CASE
            WHEN N."NrEWalletBenef" IS NOT NULL
                THEN N."NrAccountBenef" || '|' || N."NrEWalletBenef"
            ELSE N."NrAccountBenef" || '|'
        END;
END ~

CREATE TRIGGER PBI.TR_YTIGOG_BU_KEYS
BEFORE UPDATE OF "NrAccountPayer", "NrEWalletPayer", "NrAccountBenef", "NrEWalletBenef"
ON PBI."TableYTIGos"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    SET N."AccountKeyPayer" = CASE
            WHEN N."NrEWalletPayer" IS NOT NULL
                THEN N."NrAccountPayer" || '|' || N."NrEWalletPayer"
            ELSE N."NrAccountPayer" || '|'
        END;
    SET N."AccountKeyBenef" = CASE
            WHEN N."NrEWalletBenef" IS NOT NULL
                THEN N."NrAccountBenef" || '|' || N."NrEWalletBenef"
            ELSE N."NrAccountBenef" || '|'
        END;
END ~
