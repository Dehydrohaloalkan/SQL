-- DB2 for z/OS: те же автогенерируемые префиксы для PBI."InfoYSR"
-- Нужны для CTE SRA (фильтр по балансовым счетам без SUBSTR в предикате)
-- После выполнения: RUNSTATS + см. 03_create_indexes.sql

ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix1" CHAR(1)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 1));

ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix2" CHAR(2)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 2));

ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix3" CHAR(3)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 3));

ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix4" CHAR(4)
        GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 4));

ALTER TABLE PBI."InfoYSR"
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
ALTER TABLE PBI."InfoYSR"
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
