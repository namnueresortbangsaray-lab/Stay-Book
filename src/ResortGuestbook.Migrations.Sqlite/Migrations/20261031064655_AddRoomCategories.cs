using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ResortGuestbook.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddRoomCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "room_types",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", nullable: false),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    price_satang = table.Column<long>(type: "INTEGER", nullable: false),
                    base_guests = table.Column<int>(type: "INTEGER", nullable: false),
                    max_guests = table.Column<int>(type: "INTEGER", nullable: false),
                    extra_guest_fee_satang = table.Column<long>(type: "INTEGER", nullable: false, defaultValue: 0L),
                    is_pet_friendly = table.Column<bool>(type: "INTEGER", nullable: false, defaultValue: false),
                    sort_order = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    created_at = table.Column<string>(type: "TEXT", nullable: false),
                    updated_at = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_room_types", x => x.id);
                    table.CheckConstraint("ck_room_types_base_guests", "base_guests >= 1");
                    table.CheckConstraint("ck_room_types_max_guests", "max_guests >= base_guests");
                    table.CheckConstraint("ck_room_types_price_satang", "price_satang >= 0");
                });

            migrationBuilder.CreateTable(
                name: "room_zones",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", nullable: false),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    sort_order = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    created_at = table.Column<string>(type: "TEXT", nullable: false),
                    updated_at = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_room_zones", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "ux_room_types_name",
                table: "room_types",
                column: "name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ux_room_zones_name",
                table: "room_zones",
                column: "name",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "room_types");

            migrationBuilder.DropTable(
                name: "room_zones");
        }
    }
}
