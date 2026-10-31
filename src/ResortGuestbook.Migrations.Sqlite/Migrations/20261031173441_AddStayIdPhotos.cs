using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ResortGuestbook.Migrations.Sqlite.Migrations
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
                    id = table.Column<string>(type: "TEXT", nullable: false),
                    stay_id = table.Column<string>(type: "TEXT", nullable: false),
                    uploaded_by = table.Column<string>(type: "TEXT", nullable: false),
                    stored_name = table.Column<string>(type: "TEXT", nullable: false),
                    mime_type = table.Column<string>(type: "TEXT", nullable: false),
                    size_bytes = table.Column<long>(type: "INTEGER", nullable: false),
                    created_at = table.Column<string>(type: "TEXT", nullable: false)
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
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "stay_id_photos");
        }
    }
}
