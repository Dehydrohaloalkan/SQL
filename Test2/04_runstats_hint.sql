-- После ALTER и CREATE INDEX выполнить RUNSTATS по соответствующим tablespace
-- (точный синтаксис — как у вас принято: DSNUTILB / ADMIN_CMD / пакеты утилит)

-- Пример через ADMIN_CMD (раскомментировать и подставить tablespace):
-- CALL SYSPROC.ADMIN_CMD('RUNSTATS TABLESPACE PBI.<TS_ACCOUNT> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE');
-- CALL SYSPROC.ADMIN_CMD('RUNSTATS TABLESPACE PBI.<TS_INFOYSR> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE');
