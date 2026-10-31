using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ResortGuestbook.Migrations.Postgres.Migrations
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
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    price_satang = table.Column<long>(type: "bigint", nullable: false),
                    base_guests = table.Column<int>(type: "integer", nullable: false),
                    max_guests = table.Column<int>(type: "integer", nullable: false),
                    extra_guest_fee_satang = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    is_pet_friendly = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    sort_order = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
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
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    sort_order = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
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

            // Same as every other table: row level security on, no policies (see EnableRowLevelSecurity).
            migrationBuilder.Sql("ALTER TABLE \"room_zones\" ENABLE ROW LEVEL SECURITY;");
            migrationBuilder.Sql("ALTER TABLE \"room_types\" ENABLE ROW LEVEL SECURITY;");
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
