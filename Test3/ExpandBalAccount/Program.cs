using System.Data;
using IBM.Data.Db2;

if (args.Length == 0)
{
    Console.Error.WriteLine("Usage: dotnet run -- \"<connection_string>\"");
    Console.Error.WriteLine("Example: dotnet run -- \"Server=host:port;Database=db;UID=user;PWD=pass;\"");
    return 1;
}

var connectionString = args[0];

using var conn = new DB2Connection(connectionString);
conn.Open();
Console.WriteLine("Connected to DB2.");

var sources = ReadSourceData(conn);
Console.WriteLine($"Read {sources.Count} rows from SPAccountControl (PrYSR=1).");

var expanded = ExpandTo4Digits(sources);
Console.WriteLine($"Expanded to {expanded.Count} unique 4-digit values.");

ClearTarget(conn);
BulkInsert(conn, expanded);
Console.WriteLine($"Done. Inserted {expanded.Count} rows into PBI.SPBalAccount4.");

return 0;

static List<string> ReadSourceData(DB2Connection conn)
{
    var result = new List<string>();
    using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        SELECT "BalAccount", "count_BalAccount"
        FROM PBI."SPAccountControl"
        WHERE "PrYSR" = 1
        """;
    using var reader = cmd.ExecuteReader();
    while (reader.Read())
    {
        var bal = reader.GetString(0).Trim();
        var count = reader.GetInt32(1);
        if (bal.Length != count)
            Console.WriteLine($"  Warning: BalAccount='{bal}' has length {bal.Length} but count_BalAccount={count}");
        result.Add(bal);
    }
    return result;
}

static SortedSet<string> ExpandTo4Digits(List<string> sources)
{
    var result = new SortedSet<string>(StringComparer.Ordinal);
    foreach (var bal in sources)
    {
        int missing = 4 - bal.Length;
        if (missing <= 0)
        {
            result.Add(bal[..4]);
            continue;
        }
        int combinations = (int)Math.Pow(10, missing);
        for (int i = 0; i < combinations; i++)
            result.Add(bal + i.ToString().PadLeft(missing, '0'));
    }
    return result;
}

static void ClearTarget(DB2Connection conn)
{
    using var cmd = conn.CreateCommand();
    cmd.CommandText = """DELETE FROM PBI."SPBalAccount4" """;
    int deleted = cmd.ExecuteNonQuery();
    if (deleted > 0)
        Console.WriteLine($"Cleared {deleted} existing rows.");
}

static void BulkInsert(DB2Connection conn, SortedSet<string> values)
{
    try
    {
        var dt = new DataTable();
        dt.Columns.Add("BalAccount", typeof(string));
        dt.Columns.Add("PrYSR", typeof(int));
        foreach (var val in values)
            dt.Rows.Add(val, 1);

        using var bulk = new DB2BulkCopy(conn);
        bulk.DestinationTableName = "PBI.\"SPBalAccount4\"";
        bulk.ColumnMappings.Add(new DB2BulkCopyColumnMapping(0, "BalAccount"));
        bulk.ColumnMappings.Add(new DB2BulkCopyColumnMapping(1, "PrYSR"));
        bulk.WriteToServer(dt);
        bulk.Close();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"DB2BulkCopy failed ({ex.Message}), falling back to parameterized INSERT...");
        InsertFallback(conn, values);
    }
}

static void InsertFallback(DB2Connection conn, SortedSet<string> values)
{
    using var tx = conn.BeginTransaction();
    using var cmd = conn.CreateCommand();
    cmd.Transaction = tx;
    cmd.CommandText = """INSERT INTO PBI."SPBalAccount4" ("BalAccount", "PrYSR") VALUES (@bal, 1)""";
    var pBal = cmd.Parameters.Add("@bal", DB2Type.Char, 4);
    cmd.Prepare();

    int count = 0;
    foreach (var val in values)
    {
        pBal.Value = val;
        cmd.ExecuteNonQuery();
        count++;
        if (count % 1000 == 0)
            Console.Write($"\r  Inserted {count}/{values.Count}...");
    }
    tx.Commit();
    Console.WriteLine($"\r  Inserted {count}/{values.Count} (fallback).");
}
