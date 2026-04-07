# Test4: оптимизация new_script_A и new_script_B

Применение лучших практик из Test3 (v5, результат 3 мин вместо 50) к обновлённым скриптам.

## Оптимизации

| Оптимизация | Script A | Script B |
|------------|----------|----------|
| BalPrefix4 (материализованный SUBSTR) | да | нет (нет BalPrefix фильтра) |
| AccountKey (предрасчётанный ключ) | да | частично (AC CTE) |
| AccountKeyPayer/Benef (TableYTIGos) | нет | да (PACC CTE, убраны CASE) |
| SPBalAccount4 (раскрытая таблица) | да | нет (нет SPAccountControl фильтра) |
| IX_ACCOUNT_NB_BP4_COVER | MATCHCOLS=2 | MATCHCOLS=1 (NrBank) |
| IX_ACST_IDNACC | probe + screening | probe + screening |
| IX_YTIGOG_NRBANK | — | NrBankMQ фильтрация (1M строк) |
| IX_INFOYSR_DT_BP4 | да (SRA CTE) | нет (TableYSRGos, другая таблица) |

## Файлы

| Файл | Назначение |
|------|------------|
| `01_add_columns.sql` | ALTER TABLE: BalPrefix4, AccountKey на Account/InfoYSR; AccountKeyPayer/Benef на TableYTIGos |
| `02_backfill.sql` | UPDATE для заполнения новых колонок (все три таблицы) |
| `03_create_triggers.sql` | Триггеры на Account/InfoYSR (AFTER) и TableYTIGos (BEFORE) |
| `04_create_expanded_table.sql` | DDL для SPBalAccount4 |
| `05_populate_expanded_table.sql` | SQL заполнение SPBalAccount4 (раскрытие BalAccount до 4 знаков) |
| `06_create_trigger_sync.sql` | Триггеры на SPAccountControl → SPBalAccount4 (+ таблица Digits) |
| `07_create_indexes.sql` | Индексы: Account, AccountStatus, InfoYSR |
| `script_A_optimized.sql` | Оптимизированный new_script_A |
| `script_B_optimized.sql` | Оптимизированный new_script_B |

## Порядок выполнения

`01` → `02` → `03` → `04` → `05` → `06` → `07` → RUNSTATS → скрипты.

## Исправленный баг в script_B

В оригинальном `new_script_B.sql` в CTE `PAC1` и `AC` был баг приоритета операторов:
```sql
-- Было (NrBank фильтр только для ветки 8/9):
WHERE AccountStatus IN ('1'...'5')
   OR (AccountStatus IN ('8','9') AND DtAccountChange >= ...) AND NrBank IN (...)

-- Стало (NrBank фильтр для обеих веток):
WHERE (AccountStatus IN ('1'...'5')
       OR (AccountStatus IN ('8','9') AND DtAccountChange >= ...))
  AND NrBank IN (...)
```
Это также существенно ускоряет запрос — вместо всех счетов всех банков обрабатываются только 24.

## Откат

`DROP TRIGGER` → `DROP INDEX` → `DROP TABLE PBI."SPBalAccount4"` → (опционально) `ALTER TABLE ... DROP COLUMN`.
