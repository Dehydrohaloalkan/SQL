-- Test4: заполнение новых колонок для существующих строк.
-- ВНИМАНИЕ: таблицы большие (155M и 237M строк).
-- Рекомендуется выполнять в нерабочее время.
-- При необходимости можно разбить на батчи через WHERE "BalPrefix4" IS NULL
-- и повторять до полного заполнения, либо через ROWNUM-подход.

UPDATE PBI."Account"
SET "BalPrefix4" = CAST(SUBSTR("NrAccount", 9, 4) AS SMALLINT),
    "AccountKey" = CASE
        WHEN SUBSTR("NrAccount", 9, 4) = '3119' AND "NrEWallet" IS NOT NULL
            THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
        ELSE "NrAccount" || '||' || "CdCurrency"
    END
WHERE "BalPrefix4" IS NULL;

UPDATE PBI."InfoYSR"
SET "BalPrefix4" = CAST(SUBSTR("NrAccount", 9, 4) AS SMALLINT),
    "AccountKey" = CASE
        WHEN SUBSTR("NrAccount", 9, 4) = '3119' AND "NrEWallet" IS NOT NULL
            THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
        ELSE "NrAccount" || '||' || "CdCurrency"
    END
WHERE "BalPrefix4" IS NULL;

-- TableYTIGos (~1M строк, быстро)
UPDATE PBI."TableYTIGos"
SET "AccountKeyPayer" = CASE
        WHEN "NrEWalletPayer" IS NOT NULL
            THEN "NrAccountPayer" || '|' || "NrEWalletPayer"
        ELSE "NrAccountPayer" || '|'
    END,
    "AccountKeyBenef" = CASE
        WHEN "NrEWalletBenef" IS NOT NULL
            THEN "NrAccountBenef" || '|' || "NrEWalletBenef"
        ELSE "NrAccountBenef" || '|'
    END
WHERE "AccountKeyPayer" IS NULL;
