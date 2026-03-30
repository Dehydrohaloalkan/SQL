-- Test3: backfill новых колонок для существующих строк.
-- На больших таблицах это может быть долгим: согласовать с DBA (батчи/утилиты/SHRLEVEL).

UPDATE PBI."Account" A
SET
    "BalPrefix1" = SUBSTR(A."NrAccount", 9, 1),
    "BalPrefix2" = SUBSTR(A."NrAccount", 9, 2),
    "BalPrefix3" = SUBSTR(A."NrAccount", 9, 3),
    "BalPrefix4" = SUBSTR(A."NrAccount", 9, 4),
    "AccountKey" =
        CASE
            WHEN SUBSTR(A."NrAccount", 9, 4) = '3119'
             AND A."NrEWallet" IS NOT NULL
                THEN A."NrAccount" || '|' || A."NrEWallet" || '|' || A."CdCurrency"
            ELSE A."NrAccount" || '||' || A."CdCurrency"
        END
WHERE
    A."BalPrefix4" IS NULL
 OR A."AccountKey" IS NULL;

UPDATE PBI."InfoYSR" I
SET
    "BalPrefix1" = SUBSTR(I."NrAccount", 9, 1),
    "BalPrefix2" = SUBSTR(I."NrAccount", 9, 2),
    "BalPrefix3" = SUBSTR(I."NrAccount", 9, 3),
    "BalPrefix4" = SUBSTR(I."NrAccount", 9, 4),
    "AccountKey" =
        CASE
            WHEN SUBSTR(I."NrAccount", 9, 4) = '3119'
             AND I."NrEWallet" IS NOT NULL
                THEN I."NrAccount" || '|' || I."NrEWallet" || '|' || I."CdCurrency"
            ELSE I."NrAccount" || '||' || I."CdCurrency"
        END
WHERE
    I."BalPrefix4" IS NULL
 OR I."AccountKey" IS NULL;

