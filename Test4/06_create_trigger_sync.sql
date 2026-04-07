--#SET TERMINATOR ~
-- Test4: синхронизация SPBalAccount4 при изменении SPAccountControl.
--
-- ВАЖНО: если VALUES в FROM не компилируется внутри триггера на z/OS,
-- просто перезапускайте 05_populate_expanded_table.sql после изменения SPAccountControl.

-- =====================================================================
-- Триггеры: полная пересборка SPBalAccount4 при любом изменении
-- SPAccountControl (~172 строки → ~7K расширенных, <1 сек)
-- =====================================================================

CREATE TRIGGER PBI.TR_SPAC_AI_SYNC
AFTER INSERT ON PBI."SPAccountControl"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    DELETE FROM PBI."SPBalAccount4";
    INSERT INTO PBI."SPBalAccount4" ("BalAccount", "PrYSR", "YSB_NrEWallet")
    SELECT T."BalAccount", MAX(T."PrYSR"), MAX(T."YSB_NrEWallet")
    FROM (
        SELECT CAST(S."BalAccount" AS SMALLINT) AS "BalAccount", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S WHERE S."count_BalAccount" = 4
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 10 + D1."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d")
        WHERE S."count_BalAccount" = 3
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 100 + D1."d" * 10 + D2."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D2("d")
        WHERE S."count_BalAccount" = 2
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 1000 + D1."d" * 100 + D2."d" * 10 + D3."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D2("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D3("d")
        WHERE S."count_BalAccount" = 1
    ) T
    GROUP BY T."BalAccount";
END ~

CREATE TRIGGER PBI.TR_SPAC_AU_SYNC
AFTER UPDATE ON PBI."SPAccountControl"
REFERENCING NEW AS N
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    DELETE FROM PBI."SPBalAccount4";
    INSERT INTO PBI."SPBalAccount4" ("BalAccount", "PrYSR", "YSB_NrEWallet")
    SELECT T."BalAccount", MAX(T."PrYSR"), MAX(T."YSB_NrEWallet")
    FROM (
        SELECT CAST(S."BalAccount" AS SMALLINT) AS "BalAccount", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S WHERE S."count_BalAccount" = 4
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 10 + D1."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d")
        WHERE S."count_BalAccount" = 3
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 100 + D1."d" * 10 + D2."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D2("d")
        WHERE S."count_BalAccount" = 2
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 1000 + D1."d" * 100 + D2."d" * 10 + D3."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D2("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D3("d")
        WHERE S."count_BalAccount" = 1
    ) T
    GROUP BY T."BalAccount";
END ~

CREATE TRIGGER PBI.TR_SPAC_AD_SYNC
AFTER DELETE ON PBI."SPAccountControl"
REFERENCING OLD AS O
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
    DELETE FROM PBI."SPBalAccount4";
    INSERT INTO PBI."SPBalAccount4" ("BalAccount", "PrYSR", "YSB_NrEWallet")
    SELECT T."BalAccount", MAX(T."PrYSR"), MAX(T."YSB_NrEWallet")
    FROM (
        SELECT CAST(S."BalAccount" AS SMALLINT) AS "BalAccount", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S WHERE S."count_BalAccount" = 4
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 10 + D1."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d")
        WHERE S."count_BalAccount" = 3
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 100 + D1."d" * 10 + D2."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D2("d")
        WHERE S."count_BalAccount" = 2
        UNION ALL
        SELECT CAST(S."BalAccount" AS SMALLINT) * 1000 + D1."d" * 100 + D2."d" * 10 + D3."d", S."PrYSR", S."YSB_NrEWallet"
        FROM PBI."SPAccountControl" S,
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D1("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D2("d"),
            (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) D3("d")
        WHERE S."count_BalAccount" = 1
    ) T
    GROUP BY T."BalAccount";
END ~
