-- DB2 for z/OS: обслуживание для стабилизации плана
-- Цель: убрать деградации из‑за устаревшей статистики/фрагментации.
-- ВАЖНО: синтаксис RUNSTATS/REORG зависит от ваших утилит (DSNUTILB / ADMIN_CMD).
-- Ниже 2 варианта: (A) через ADMIN_CMD (если разрешено) (B) шаблон JCL (если у вас так принято).

--------------------------------------------------------------------------------
-- A) Если доступна административная процедура (часто: SYSPROC.ADMIN_CMD)
--------------------------------------------------------------------------------
-- 1) RUNSTATS по таблицам и индексам, влияющим на запрос
-- Подставь корректные опции RUNSTATS, принятые у вас (TABLE(ALL)/INDEX(ALL), HISTOGRAM и т.д.)

-- CALL SYSPROC.ADMIN_CMD(
-- 'RUNSTATS TABLESPACE PBI.<TS_ACCOUNT> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE'
-- );
-- CALL SYSPROC.ADMIN_CMD(
-- 'RUNSTATS TABLESPACE PBI.<TS_ACCOUNTSTATUS> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE'
-- );
-- CALL SYSPROC.ADMIN_CMD(
-- 'RUNSTATS TABLESPACE PBI.<TS_INFOYSR> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE'
-- );
-- CALL SYSPROC.ADMIN_CMD(
-- 'RUNSTATS TABLESPACE PBI.<TS_SPACCOUNTCONTROL> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE'
-- );
-- CALL SYSPROC.ADMIN_CMD(
-- 'RUNSTATS TABLESPACE PBI.<TS_SPBICBY> TABLE(ALL) INDEX(ALL) SHRLEVEL CHANGE'
-- );

-- 2) REORG (если реально есть фрагментация/неэффективная кластеризация)
-- REORG лучше делать по результатам REAL-TIME STATS / рекомендаций DBA.

-- CALL SYSPROC.ADMIN_CMD('REORG TABLESPACE PBI.<TS_INFOYSR> SHRLEVEL CHANGE');
-- CALL SYSPROC.ADMIN_CMD('REORG TABLESPACE PBI.<TS_ACCOUNTSTATUS> SHRLEVEL CHANGE');

--------------------------------------------------------------------------------
-- B) Если всё делается через утилиты (JCL) — здесь только памятка
--------------------------------------------------------------------------------
-- 1) Сформировать RUNSTATS по tablespace, где лежат:
--    PBI."Account", PBI."AccountStatus", PBI."InfoYSR", PBI."SPAccountControl", PBI."SPBICBY"
-- 2) Прогнать REORG при необходимости.
-- 3) (Опционально) REBIND пакетов/планов, через которые выполняется запрос, если он в пакете.

