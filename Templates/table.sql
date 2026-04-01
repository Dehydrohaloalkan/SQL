create tablespace SINGLE01 in DICPLUS using stogroup SGDIC priqty 2400 secqty 960 segsize 32 maxpartitions 1 dssize 32G locksize page CCSID ASCII;
create table DIC."ActRecord" (
    "CdActRecord" CHAR(1) not null check ("CdActRecord" in ('0', '1', '2', '3')),
    "NmActRecord" VARCHAR(25) not null,
    primary key ("CdActRecord")
) in DICPLUS.SINGLE01 obid 2000;
create unique index DIC."X1ActRecord" on DIC."ActRecord" ("CdActRecord" ASC) using stogroup SGDIC priqty 96 secqty 96;