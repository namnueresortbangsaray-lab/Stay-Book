using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ResortGuestbook.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingChannel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "booking_channel",
                table: "stays",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "booking_channel",
                table: "stays");
        }
    }
}
