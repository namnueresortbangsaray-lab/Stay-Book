namespace ResortGuestbook.Tests.Data;

public sealed class SqliteResortDataTests(SqliteDatabaseFactory factory) : ResortDataTests(factory), IClassFixture<SqliteDatabaseFactory>;
