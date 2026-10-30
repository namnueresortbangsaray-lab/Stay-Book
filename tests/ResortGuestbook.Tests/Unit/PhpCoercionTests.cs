using ResortGuestbook.Web.Infrastructure.Http;

namespace ResortGuestbook.Tests.Unit;

public sealed class PhpCoercionTests
{
    [Theory]
    [InlineData("650.50", 650L)]
    [InlineData("  12abc", 12L)]
    [InlineData("abc", 0L)]
    [InlineData("1e3", 1000L)]
    [InlineData("-3.9", -3L)]
    public void ToIntTruncatesLikePhp(string value, long expected) => Assert.Equal(expected, Php.ToInt(value));

    [Theory]
    [InlineData("1", true)]
    [InlineData("on", true)]
    [InlineData(" YES ", true)]
    [InlineData("true", true)]
    [InlineData("0", false)]
    [InlineData("off", false)]
    [InlineData("2", false)]
    [InlineData("", false)]
    public void ToBoolFollowsFilterValidateBoolean(string value, bool expected) => Assert.Equal(expected, Php.ToBool(value));

    [Fact]
    public void ToBoolHandlesJsonValues()
    {
        Assert.True(Php.ToBool(true));
        Assert.True(Php.ToBool(1L));
        Assert.False(Php.ToBool(2L));
        Assert.False(Php.ToBool(null));
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
    public void IsNumericMatchesPhp(string value, bool expected) => Assert.Equal(expected, Php.IsNumeric(value));

    [Fact]
    public void BooleansAreNotNumeric() => Assert.False(Php.IsNumeric(true));

    [Fact]
    public void DigitsKeepsAsciiDigitsOnly() => Assert.Equal("0812345678", Php.Digits("081-234-5678 ๑"));

    [Fact]
    public void MbStrlenCountsCodePoints() => Assert.Equal(3, Php.MbStrlen("ทดส"));

    [Theory]
    [InlineData("2030-02-29", false)]
    [InlineData("2030-1-10", false)]
    [InlineData("2028-02-29", true)]
    public void DatesMustRoundTrip(string value, bool valid) => Assert.Equal(valid, Php.TryParseDate(value, out _));
}
