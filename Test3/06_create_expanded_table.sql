-- Test3: таблица с раскрытыми до 4 знаков значениями BalAccount из SPAccountControl.
-- Заполняется C#-программой ExpandBalAccount.
-- Заменить <DB_NAME>, <STOGROUP>, <OBID> на реальные значения из вашего окружения.

CREATE TABLESPACE SPBAL01
    IN <DB_NAME>
    USING STOGROUP <STOGROUP>
    PRIQTY 2400 SECQTY 960
    SEGSIZE 32
    MAXPARTITIONS 1
    DSSIZE 32G
    LOCKSIZE PAGE
    CCSID ASCII;

CREATE TABLE PBI."SPBalAccount4" (
    "BalAccount" CHAR(4) NOT NULL,
    "PrYSR"     INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY ("BalAccount")
) IN <DB_NAME>.SPBAL01 OBID <OBID>;

CREATE UNIQUE INDEX PBI."X1SPBalAccount4"
    ON PBI."SPBalAccount4" ("BalAccount" ASC)
    USING STOGROUP <STOGROUP>
    PRIQTY 96 SECQTY 96;
