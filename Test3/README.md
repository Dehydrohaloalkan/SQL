# Test3: материализация префиксов и ключа через колонки + триггеры (Db2 for z/OS)

Идея: вместо `SUBSTR(...)` в предикатах и `CASE` для ключа — добавить **обычные** колонки:

- `BalPrefix1..4` = `SUBSTR(NrAccount, 9, N)`
- `AccountKey` = ключ `"Account"` из отчёта (конкатенация)

И поддерживать их триггерами на `INSERT/UPDATE`.

## Важно

- Это увеличит стоимость **INSERT/UPDATE** (триггеры + индексы) на больших таблицах.
- Нужен **backfill** для уже существующих строк.
- Согласовать с DBA окно работ и RUNSTATS.
- **RUNSTATS обязателен** после DDL-изменений и создания индексов — без него оптимизатор игнорирует новые индексы.

## v2 — UNION вместо OR для InfoYSR

Проблема v1: OR по разным колонкам (`BalPrefix4 OR BalPrefix3 OR ...`) ограничивает MATCHCOLS=1 для любого индекса.
Решение: SRA переписан как `UNION ALL` из 4 запросов — каждая ветка получает свой индекс и MATCHCOLS=2.

На Account индексы создать нельзя → AA оставлен с OR (UNION дал бы 4 tablespace scan вместо 1).

## Файлы

| Файл | Назначение |
|------|------------|
| `01_add_columns.sql` | Добавить колонки `BalPrefix*`, `AccountKey` (как nullable) |
| `02_backfill.sql` | Заполнить колонки для существующих строк |
| `03_create_triggers.sql` | Триггеры (BEFORE) для поддержки колонок |
| `03_create_triggers_after.sql` | Триггеры (AFTER + `BEGIN ATOMIC`) в стиле вашего окружения |
| `04_create_indexes.sql` | 4 индекса на InfoYSR `(DtBalance, BalPrefixN, AccountKey)` для каждой UNION-ветки |
| `05_runstats_hint.sql` | Памятка по RUNSTATS |
| `script_final.sql` | Запрос: SRA через UNION ALL, AA с OR |

## Порядок

`01` → `02` → `03` → `04` → RUNSTATS → `script_final.sql`.

## Откат (идея)

`DROP TRIGGER` → `DROP INDEX` → (опционально) `ALTER TABLE ... DROP COLUMN`.

