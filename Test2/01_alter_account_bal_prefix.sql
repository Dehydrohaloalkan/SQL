-- DB2 for z/OS: автогенерируемые столбцы префикса балансового счёта (позиция 9 в NrAccount)
-- Таблица: PBI."Account"
-- После выполнения: RUNSTATS + см. 03_create_indexes.sql

ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix1" CHAR(1)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 1));

ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix2" CHAR(2)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 2));

ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix3" CHAR(3)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 3));

ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix4" CHAR(4)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 4));

-- Ключ строки отчёта (та же конкатенация, что в script.sql для поля "Account")
-- Идёт после BalPrefix*, чтобы можно было использовать "BalPrefix4" в условии.
-- Если Db2 не разрешит ссылку на другое generated-поле — см. закомментированный вариант ниже.
ALTER TABLE PBI."Account"
    ADD COLUMN "AccountKey" VARCHAR(80)
        GENERATED ALWAYS AS (
            CASE
                WHEN "BalPrefix4" = '3119'
                 AND "NrEWallet" IS NOT NULL
                    THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
                ELSE "NrAccount" || '||' || "CdCurrency"
            END
        );

/*
ALTER TABLE PBI."Account"
    ADD COLUMN "AccountKey" VARCHAR(80)
        GENERATED ALWAYS AS (
            CASE
                WHEN SUBSTR("NrAccount", 9, 4) = '3119'
                 AND "NrEWallet" IS NOT NULL
                    THEN "NrAccount" || '|' || "NrEWallet" || '|' || "CdCurrency"
                ELSE "NrAccount" || '||' || "CdCurrency"
            END
        );
*/
