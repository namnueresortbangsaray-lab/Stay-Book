namespace ResortGuestbook.Tests.Integration;

/// <summary>Web host tests run one at a time because each factory configures the process environment.</summary>
[CollectionDefinition(Name, DisableParallelization = true)]
public sealed class WebCollection
{
    public const string Name = "web";
}
