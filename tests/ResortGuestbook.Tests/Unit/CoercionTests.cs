using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Tests.Unit;

public sealed class CoercionTests
{
    [Theory]
    [InlineData("650.50", 650L)]
    [InlineData("  12abc", 12L)]
    [InlineData("abc", 0L)]
    [InlineData("1e3", 1000L)]
    [InlineData("-3.9", -3L)]
    public void ToIntTruncatesLikeV1(string value, long expected) => Assert.Equal(expected, Coerce.ToInt(value));

    [Theory]
    [InlineData("1", true)]
    [InlineData("on", true)]
    [InlineData(" YES ", true)]
    [InlineData("true", true)]
    [InlineData("0", false)]
    [InlineData("off", false)]
    [InlineData("2", false)]
    [InlineData("", false)]
    public void ToBoolFollowsFilterValidateBoolean(string value, bool expected) => Assert.Equal(expected, Coerce.ToBool(value));

    [Fact]
    public void ToBoolHandlesJsonValues()
    {
        Assert.True(Coerce.ToBool(true));
        Assert.True(Coerce.ToBool(1L));
        Assert.False(Coerce.ToBool(2L));
        Assert.False(Coerce.ToBool(null));
    }

    [Theory]
    [InlineData("650.50", true)]
    [InlineData(" 1", true)]
    [InlineData("1 ", true)]
    [InlineData(".5", true)]
    [InlineData("1e3", true)]
    [InlineData("abc", false)]
    [InlineData("", false)]
    [InlineData("1,5", false)]
    public void IsNumericMatchesV1(string value, bool expected) => Assert.Equal(expected, Coerce.IsNumeric(value));

    [Fact]
    public void BooleansAreNotNumeric() => Assert.False(Coerce.IsNumeric(true));

    [Fact]
    public void DigitsKeepsAsciiDigitsOnly() => Assert.Equal("0812345678", Coerce.Digits("081-234-5678 ๑"));

    [Fact]
    public void MbStrlenCountsCodePoints() => Assert.Equal(3, Coerce.MbStrlen("ทดส"));

    [Theory]
    [InlineData("2030-02-29", false)]
    [InlineData("2030-1-10", false)]
    [InlineData("2028-02-29", true)]
    public void DatesMustRoundTrip(string value, bool valid) => Assert.Equal(valid, Coerce.TryParseDate(value, out _));
}
