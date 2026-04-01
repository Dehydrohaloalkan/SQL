# Test3: материализация префиксов и ключа через колонки + триггеры (Db2 for z/OS)

Идея: вместо `SUBSTR(...)` в предикатах и `CASE` для ключа — добавить **обычные** колонки:

- `BalPrefix1..4` = `SUBSTR(NrAccount, 9, N)`
- `AccountKey` = ключ `"Account"` из отчёта (конкатенация)

И поддерживать их триггерами на `INSERT/UPDATE`.

## v4 — раскрытие BalAccount до 4 знаков (SPBalAccount4)

Ключевая оптимизация: все значения `BalAccount` из `SPAccountControl` (1-4 знака)
раскрываются до 4 знаков в отдельную таблицу `SPBalAccount4`.
Например `151` (3 знака) → `1510, 1511, ..., 1519` (10 четырёхзначных).

Это устраняет `OR` по 4 колонкам и 4 UNION-ветки — остаётся **один** JOIN на `BalPrefix4`.

| Версия | InfoYSR | Индексы | MATCHCOLS |
|--------|---------|---------|-----------|
| v1 (OR) | 1 запрос с OR | 1 комбинированный | 1 |
| v2 (IN) | 4 UNION ALL + IN | 4 (по BalPrefix) | 1 |
| v3 (CROSS JOIN) | 4 UNION ALL + CROSS JOIN | 4 (по BalPrefix) | 1 |
| **v4 (SPBalAccount4)** | **1 CROSS JOIN** | **1** | **ожидаем 2** |

## Файлы

| Файл | Назначение |
|------|------------|
| `01_add_columns.sql` | Добавить колонки `BalPrefix*`, `AccountKey` (как nullable) |
| `02_backfill.sql` | Заполнить колонки для существующих строк |
| `03_create_triggers.sql` | Триггеры (BEFORE) для поддержки колонок |
| `03_create_triggers_after.sql` | Триггеры (AFTER + `BEGIN ATOMIC`) в стиле вашего окружения |
| `04_create_indexes.sql` | 1 индекс на InfoYSR: `(DtBalance, BalPrefix4, AccountKey)` |
| `05_runstats_hint.sql` | Памятка по RUNSTATS |
| `06_create_expanded_table.sql` | DDL для таблицы `SPBalAccount4` |
| `ExpandBalAccount/` | C# программа для заполнения `SPBalAccount4` |
| `script_final.sql` | Запрос: SRA через CROSS JOIN на SPBalAccount4 |

## Порядок

`01` → `02` → `03` → `04` → `06` → ExpandBalAccount → RUNSTATS → `script_final.sql`.

## Важно

- **RUNSTATS** обязателен после DDL-изменений и создания индексов.
- Если `SPAccountControl` изменится — перезапустить `ExpandBalAccount` для обновления `SPBalAccount4`.
- Триггеры увеличивают стоимость INSERT/UPDATE на больших таблицах.

## Откат

`DROP TRIGGER` → `DROP INDEX` → `DROP TABLE PBI."SPBalAccount4"` → (опционально) `ALTER TABLE ... DROP COLUMN`.
