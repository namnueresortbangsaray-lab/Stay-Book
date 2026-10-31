using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ResortGuestbook.Migrations.Postgres.Migrations
{
    /// <inheritdoc />
    public partial class AddStayIdPhotos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "stay_id_photos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    stay_id = table.Column<Guid>(type: "uuid", nullable: false),
                    uploaded_by = table.Column<Guid>(type: "uuid", nullable: false),
                    stored_name = table.Column<string>(type: "text", nullable: false),
                    mime_type = table.Column<string>(type: "text", nullable: false),
                    size_bytes = table.Column<long>(type: "bigint", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_stay_id_photos", x => x.id);
                    table.ForeignKey(
                        name: "FK_stay_id_photos_stays_stay_id",
                        column: x => x.stay_id,
                        principalTable: "stays",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_stay_id_photos_users_uploaded_by",
                        column: x => x.uploaded_by,
                        principalTable: "users",
                        principalColumn: "id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_stay_id_photos_uploaded_by",
                table: "stay_id_photos",
                column: "uploaded_by");

            migrationBuilder.CreateIndex(
                name: "ux_stay_id_photos_stay_id",
                table: "stay_id_photos",
                column: "stay_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ux_stay_id_photos_stored_name",
                table: "stay_id_photos",
                column: "stored_name",
                unique: true);

            // Same as every other table: row level security on, no policies (see EnableRowLevelSecurity).
            migrationBuilder.Sql("ALTER TABLE \"stay_id_photos\" ENABLE ROW LEVEL SECURITY;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "stay_id_photos");
        }
    }
}
