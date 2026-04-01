CREATE TRIGGER PBI.TR_INFOYSR_AU_MAT
AFTER
UPDATE OF "NrAccount",
    "NrEWallet",
    "CdCurrency" ON PBI."InfoYSR" REFERENCING NEW AS N FOR EACH ROW MODE DB2SQL BEGIN ATOMIC
UPDATE PBI."InfoYSR" I
SET "BalPrefix1" = SUBSTR(N."NrAccount", 9, 1),
    "BalPrefix2" = SUBSTR(N."NrAccount", 9, 2),
    "BalPrefix3" = SUBSTR(N."NrAccount", 9, 3),
    "BalPrefix4" = SUBSTR(N."NrAccount", 9, 4),
    "AccountKey" = CASE
        WHEN SUBSTR(N."NrAccount", 9, 4) = '3119'
        AND N."NrEWallet" IS NOT NULL THEN N."NrAccount" || '|' || N."NrEWallet" || '|' || N."CdCurrency"
        ELSE N."NrAccount" || '||' || N."CdCurrency"
    END
WHERE I."IDNInfoYSR" = N."IDNInfoYSR";
END ~