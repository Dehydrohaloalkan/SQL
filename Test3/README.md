# Test3: материализация префиксов и ключа через колонки + триггеры (Db2 for z/OS)

Идея: вместо `SUBSTR(...)` в предикатах и `CASE` для ключа — добавить **обычные** колонки:

- `BalPrefix1..4` = `SUBSTR(NrAccount, 9, N)`
- `AccountKey` = ключ `"Account"` из отчёта (конкатенация)

И поддерживать их триггерами на `INSERT/UPDATE`.

## Важно

- Это увеличит стоимость **INSERT/UPDATE** (триггеры + индексы) на больших таблицах.
- Нужен **backfill** для уже существующих строк.
- Согласовать с DBA окно работ и RUNSTATS.

## Файлы

| Файл | Назначение |
|------|------------|
| `01_add_columns.sql` | Добавить колонки `BalPrefix*`, `AccountKey` (как nullable) |
| `02_backfill.sql` | Заполнить колонки для существующих строк |
| `03_create_triggers.sql` | Триггеры (BEFORE) для поддержки колонок |
| `03_create_triggers_after.sql` | Триггеры (AFTER + `BEGIN ATOMIC`) в стиле вашего окружения |
| `04_create_indexes.sql` | Индексы по новым колонкам |
| `05_runstats_hint.sql` | Памятка по RUNSTATS |
| `script_final.sql` | Запрос, использующий новые колонки |

## Порядок

`01` → `02` → `03` → `04` → `05` → `script_final.sql`.

## Откат (идея)

`DROP TRIGGER` → `DROP INDEX` → (опционально) `ALTER TABLE ... DROP COLUMN`.

