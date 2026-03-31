--#SET TERMINATOR @
-- Test3: триггеры в “вашем” стиле (AFTER ... BEGIN ATOMIC ... END)
-- Логика та же: поддерживать BalPrefix1..4 и AccountKey.
--
-- Почему AFTER:
-- - В вашем окружении так принято (пример из DIC.*).
-- - В AFTER нельзя “присвоить” NEW.* напрямую, поэтому делаем UPDATE той же строки по PK.
-- - Чтобы не зациклиться, UPDATE-триггер объявлен только на поля-источники
--   ("NrAccount","NrEWallet","CdCurrency"). Внутренний UPDATE меняет только BalPrefix*/AccountKey.

-- Account: AFTER INSERT → пересчитать материализованные поля
CREATE TRIGGER PBI.TR_ACCOUNT_AI_MAT
AFTER INSERT
ON PBI."Account"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."Account" A
    SET
        "BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        "BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        "BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        "BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        "AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END
    WHERE A."IDNAccount" = N."IDNAccount";
END@

-- Account: AFTER UPDATE (только если изменились поля-источники)
CREATE TRIGGER PBI.TR_ACCOUNT_AU_MAT
AFTER UPDATE OF "NrAccount", "NrEWallet", "CdCurrency"
ON PBI."Account"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."Account" A
    SET
        "BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        "BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        "BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        "BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        "AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END
    WHERE A."IDNAccount" = N."IDNAccount";
END@

-- InfoYSR: AFTER INSERT
CREATE TRIGGER PBI.TR_INFOYSR_AI_MAT
AFTER INSERT
ON PBI."InfoYSR"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."InfoYSR" I
    SET
        "BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        "BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        "BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        "BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        "AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END
    WHERE I."IDNInfoYSR" = N."IDNInfoYSR";
END@

-- InfoYSR: AFTER UPDATE OF источники
CREATE TRIGGER PBI.TR_INFOYSR_AU_MAT
AFTER UPDATE OF "NrAccount", "NrEWallet", "CdCurrency"
ON PBI."InfoYSR"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    UPDATE PBI."InfoYSR" I
    SET
        "BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
        "BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
        "BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
        "BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
        "AccountKey" =
            CASE
                WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
                 AND N."NrEWallet" IS NOT NULL
                    THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
                ELSE N."NrAccount" || '||' || N."CdCurrency"
            END
    WHERE I."IDNInfoYSR" = N."IDNInfoYSR";
END@

