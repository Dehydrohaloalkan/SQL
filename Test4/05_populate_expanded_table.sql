-- Test4: заполнение SPBalAccount4 из SPAccountControl (чистый SQL).
-- Каждый BalAccount раскрывается до 4 знаков через арифметику.
-- Пример: 151 (3 знака) → 1510, 1511, ..., 1519 (10 строк).
-- При конфликтах (напр. 3 и 3119 оба PrYSR=1): MAX(PrYSR), MAX(YSB_NrEWallet).

DELETE FROM PBI."SPBalAccount4";

INSERT INTO PBI."SPBalAccount4" ("BalAccount", "PrYSR", "YSB_NrEWallet")
WITH DIGITS(d) AS (
    VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)
),
EXPANDED AS (
    SELECT CAST(S."BalAccount" AS SMALLINT) AS "BalAccount",
           S."PrYSR", S."YSB_NrEWallet"
    FROM PBI."SPAccountControl" S
    WHERE S."count_BalAccount" = 4

    UNION ALL

    SELECT CAST(S."BalAccount" AS SMALLINT) * 10 + D1.d,
           S."PrYSR", S."YSB_NrEWallet"
    FROM PBI."SPAccountControl" S, DIGITS D1
    WHERE S."count_BalAccount" = 3

    UNION ALL

    SELECT CAST(S."BalAccount" AS SMALLINT) * 100 + D1.d * 10 + D2.d,
           S."PrYSR", S."YSB_NrEWallet"
    FROM PBI."SPAccountControl" S, DIGITS D1, DIGITS D2
    WHERE S."count_BalAccount" = 2

    UNION ALL

    SELECT CAST(S."BalAccount" AS SMALLINT) * 1000 + D1.d * 100 + D2.d * 10 + D3.d,
           S."PrYSR", S."YSB_NrEWallet"
    FROM PBI."SPAccountControl" S, DIGITS D1, DIGITS D2, DIGITS D3
    WHERE S."count_BalAccount" = 1
)
SELECT "BalAccount", MAX("PrYSR"), MAX("YSB_NrEWallet")
FROM EXPANDED
GROUP BY "BalAccount";
