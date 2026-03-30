-- Test3: триггеры поддержания BalPrefix* и AccountKey при INSERT/UPDATE.
-- Примечание: синтаксис триггеров на Db2 for z/OS может отличаться по стандартам окружения;
-- если у вас принято другое (например, отдельные BEGIN ATOMIC), подстроим.

-- Account: BEFORE INSERT
CREATE TRIGGER PBI.TR_ACCOUNT_BI
    NO CASCADE BEFORE INSERT ON PBI."Account"
    REFERENCING NEW AS N
    FOR EACH ROW
    MODE DB2SQL
    SET
        N."BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        N."BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        N."BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        N."BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        N."AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END;

-- Account: BEFORE UPDATE (только если меняются поля, влияющие на расчёт)
CREATE TRIGGER PBI.TR_ACCOUNT_BU
    NO CASCADE BEFORE UPDATE OF "NrAccount", "NrEWallet", "CdCurrency" ON PBI."Account"
    REFERENCING NEW AS N
    FOR EACH ROW
    MODE DB2SQL
    SET
        N."BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        N."BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        N."BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        N."BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        N."AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END;

-- InfoYSR: BEFORE INSERT
CREATE TRIGGER PBI.TR_INFOYSR_BI
    NO CASCADE BEFORE INSERT ON PBI."InfoYSR"
    REFERENCING NEW AS N
    FOR EACH ROW
    MODE DB2SQL
    SET
        N."BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        N."BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        N."BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        N."BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        N."AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END;

-- InfoYSR: BEFORE UPDATE
CREATE TRIGGER PBI.TR_INFOYSR_BU
    NO CASCADE BEFORE UPDATE OF "NrAccount", "NrEWallet", "CdCurrency" ON PBI."InfoYSR"
    REFERENCING NEW AS N
    FOR EACH ROW
    MODE DB2SQL
    SET
        N."BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        N."BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        N."BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        N."BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        N."AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END;

