namespace ResortGuestbook.Tests.Data;

/// <summary>Shares one PostgreSQL container between the PostgreSQL test classes.</summary>
[CollectionDefinition(Name)]
public sealed class PostgresCollection : ICollectionFixture<PostgresDatabaseFactory>, ICollectionFixture<SqliteDatabaseFactory>
{
    public const string Name = "postgres";
}
