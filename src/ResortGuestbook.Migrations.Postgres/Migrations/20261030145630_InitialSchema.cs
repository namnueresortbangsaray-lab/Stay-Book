using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ResortGuestbook.Migrations.Postgres.Migrations
{
    /// <inheritdoc />
    public partial class InitialSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "guests",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    phone = table.Column<string>(type: "text", nullable: false),
                    normalized_phone = table.Column<string>(type: "text", nullable: false),
                    customer_type = table.Column<string>(type: "text", nullable: false, defaultValue: "ลูกค้าทั่วไป"),
                    is_regular = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    customer_note = table.Column<string>(type: "text", nullable: true),
                    preferences = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_guests", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "rooms",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    zone = table.Column<string>(type: "text", nullable: false),
                    type = table.Column<string>(type: "text", nullable: false),
                    price_satang = table.Column<long>(type: "bigint", nullable: false),
                    base_guests = table.Column<int>(type: "integer", nullable: false),
                    max_guests = table.Column<int>(type: "integer", nullable: false),
                    extra_guest_fee_satang = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    sort_order = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    status = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    is_pet_friendly = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_rooms", x => x.id);
                    table.CheckConstraint("ck_rooms_base_guests", "base_guests >= 1");
                    table.CheckConstraint("ck_rooms_max_guests", "max_guests >= base_guests");
                    table.CheckConstraint("ck_rooms_price_satang", "price_satang >= 0");
                    table.CheckConstraint("ck_rooms_status", "status IN (0,1)");
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    email = table.Column<string>(type: "text", nullable: false),
                    password_hash = table.Column<string>(type: "text", nullable: false),
                    role = table.Column<string>(type: "text", nullable: false),
                    active = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    security_stamp = table.Column<string>(type: "text", nullable: false),
                    lockout_end = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    access_failed_count = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.id);
                    table.CheckConstraint("ck_users_role", "role IN ('admin','front_desk','housekeeping')");
                });

            migrationBuilder.CreateTable(
                name: "stays",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    guest_id = table.Column<Guid>(type: "uuid", nullable: true),
                    room_id = table.Column<Guid>(type: "uuid", nullable: false),
                    guest_name = table.Column<string>(type: "text", nullable: false),
                    phone = table.Column<string>(type: "text", nullable: true),
                    check_in_date = table.Column<DateOnly>(type: "date", nullable: false),
                    check_out_date = table.Column<DateOnly>(type: "date", nullable: false),
                    guests = table.Column<int>(type: "integer", nullable: false),
                    extra_bed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    total_amount_satang = table.Column<long>(type: "bigint", nullable: false),
                    status = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    note = table.Column<string>(type: "text", nullable: true),
                    deposit_amount_satang = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    deposit_paid = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    id_verified = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    pet_type = table.Column<string>(type: "text", nullable: true),
                    pet_count = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    pet_fee_satang = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    discount_amount_satang = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_stays", x => x.id);
                    table.CheckConstraint("ck_stays_dates", "check_out_date > check_in_date");
                    table.CheckConstraint("ck_stays_guests", "guests >= 1");
                    table.CheckConstraint("ck_stays_status", "status IN (0,1,2)");
                    table.CheckConstraint("ck_stays_total_amount_satang", "total_amount_satang >= 0");
                    table.ForeignKey(
                        name: "FK_stays_guests_guest_id",
                        column: x => x.guest_id,
                        principalTable: "guests",
                        principalColumn: "id");
                    table.ForeignKey(
                        name: "FK_stays_rooms_room_id",
                        column: x => x.room_id,
                        principalTable: "rooms",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "audit_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    action = table.Column<string>(type: "text", nullable: false),
                    entity_type = table.Column<string>(type: "text", nullable: false),
                    entity_id = table.Column<Guid>(type: "uuid", nullable: false),
                    before_json = table.Column<string>(type: "jsonb", nullable: true),
                    after_json = table.Column<string>(type: "jsonb", nullable: true),
                    ip_address = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_audit_logs", x => x.id);
                    table.ForeignKey(
                        name: "FK_audit_logs_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "attachments",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    stay_id = table.Column<Guid>(type: "uuid", nullable: false),
                    uploaded_by = table.Column<Guid>(type: "uuid", nullable: false),
                    original_name = table.Column<string>(type: "text", nullable: false),
                    stored_name = table.Column<string>(type: "text", nullable: false),
                    mime_type = table.Column<string>(type: "text", nullable: false),
                    size_bytes = table.Column<long>(type: "bigint", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_attachments", x => x.id);
                    table.ForeignKey(
                        name: "FK_attachments_stays_stay_id",
                        column: x => x.stay_id,
                        principalTable: "stays",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_attachments_users_uploaded_by",
                        column: x => x.uploaded_by,
                        principalTable: "users",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "checkout_inspections",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    stay_id = table.Column<Guid>(type: "uuid", nullable: false),
                    key_returned = table.Column<bool>(type: "boolean", nullable: false),
                    room_clean = table.Column<bool>(type: "boolean", nullable: false),
                    equipment_complete = table.Column<bool>(type: "boolean", nullable: false),
                    no_damage = table.Column<bool>(type: "boolean", nullable: false),
                    minibar_checked = table.Column<bool>(type: "boolean", nullable: false),
                    inspection_note = table.Column<string>(type: "text", nullable: true),
                    inspected_by = table.Column<Guid>(type: "uuid", nullable: true),
                    inspected_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_checkout_inspections", x => x.id);
                    table.ForeignKey(
                        name: "FK_checkout_inspections_stays_stay_id",
                        column: x => x.stay_id,
                        principalTable: "stays",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_checkout_inspections_users_inspected_by",
                        column: x => x.inspected_by,
                        principalTable: "users",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "feedbacks",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    stay_id = table.Column<Guid>(type: "uuid", nullable: false),
                    cleanliness_rating = table.Column<int>(type: "integer", nullable: false),
                    service_rating = table.Column<int>(type: "integer", nullable: false),
                    facility_rating = table.Column<int>(type: "integer", nullable: false),
                    overall_rating = table.Column<int>(type: "integer", nullable: false),
                    would_return = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    comment = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_feedbacks", x => x.id);
                    table.CheckConstraint("ck_feedbacks_cleanliness_rating", "cleanliness_rating BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_feedbacks_facility_rating", "facility_rating BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_feedbacks_overall_rating", "overall_rating BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_feedbacks_service_rating", "service_rating BETWEEN 1 AND 5");
                    table.ForeignKey(
                        name: "FK_feedbacks_stays_stay_id",
                        column: x => x.stay_id,
                        principalTable: "stays",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_attachments_stay_id",
                table: "attachments",
                column: "stay_id");

            migrationBuilder.CreateIndex(
                name: "IX_attachments_uploaded_by",
                table: "attachments",
                column: "uploaded_by");

            migrationBuilder.CreateIndex(
                name: "ux_attachments_stored_name",
                table: "attachments",
                column: "stored_name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_audit_entity",
                table: "audit_logs",
                columns: new[] { "entity_type", "entity_id", "created_at" });

            migrationBuilder.CreateIndex(
                name: "IX_audit_logs_user_id",
                table: "audit_logs",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_checkout_inspections_inspected_by",
                table: "checkout_inspections",
                column: "inspected_by");

            migrationBuilder.CreateIndex(
                name: "ux_checkout_inspections_stay_id",
                table: "checkout_inspections",
                column: "stay_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ux_feedbacks_stay_id",
                table: "feedbacks",
                column: "stay_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_guests_name",
                table: "guests",
                column: "name");

            migrationBuilder.CreateIndex(
                name: "idx_guests_phone",
                table: "guests",
                column: "normalized_phone");

            migrationBuilder.CreateIndex(
                name: "ux_guests_normalized_phone",
                table: "guests",
                column: "normalized_phone",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_rooms_zone_status",
                table: "rooms",
                columns: new[] { "zone", "status" });

            migrationBuilder.CreateIndex(
                name: "ux_rooms_name",
                table: "rooms",
                column: "name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_stays_dates",
                table: "stays",
                columns: new[] { "check_in_date", "check_out_date" });

            migrationBuilder.CreateIndex(
                name: "idx_stays_guest",
                table: "stays",
                column: "guest_id");

            migrationBuilder.CreateIndex(
                name: "idx_stays_room_status",
                table: "stays",
                columns: new[] { "room_id", "status" });

            migrationBuilder.CreateIndex(
                name: "ux_users_email",
                table: "users",
                column: "email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "attachments");

            migrationBuilder.DropTable(
                name: "audit_logs");

            migrationBuilder.DropTable(
                name: "checkout_inspections");

            migrationBuilder.DropTable(
                name: "feedbacks");

            migrationBuilder.DropTable(
                name: "users");

            migrationBuilder.DropTable(
                name: "stays");

            migrationBuilder.DropTable(
                name: "guests");

            migrationBuilder.DropTable(
                name: "rooms");
        }
    }
}
