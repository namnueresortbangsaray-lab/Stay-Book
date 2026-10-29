# MIGRATION PLAN: STAY-BOOK RESORT GUEST LOGBOOK
**From Flutter/Dart Local App to Production-Grade Web Application (PHP 8.3, Vanilla JS, Tailwind CSS, SQLite / PostgreSQL / Supabase, Docker, Nginx)**

---

## 1. Executive Summary

This document specifies the complete migration of **Stay Book (สมุดบันทึกผู้เข้าพักของน้ำเหนือรีสอร์ทบางเสร่)** from a single-device offline Flutter/Dart mobile application to a robust, modular, production-grade web application.

The target system maintains 100% feature and visual parity while upgrading architectural durability, multi-user concurrency, role-based security, audit logging, and cloud database portability (SQLite 3 now, Supabase/PostgreSQL ready on day one).

---

## 2. Source Code Inventory & Analysis

### 2.1 Screen and Route Inventory

| Screen Name | Flutter Source File | Purpose & User Flows |
|---|---|---|
| **Splash Screen** | `lib/screens/splash_screen.dart` | Animated splash with resort branding (`logo_white.webp`), tagline, progress bar, and asynchronous database verification before entering Home Shell. |
| **Home Shell** | `lib/screens/home_shell.dart` | Main layout with brand gradient AppBar (`#2585E6` -> `#1565C0`), title "น้ำเหนือรีสอร์ท", subtitle "บางเสร่ · [Tab Title]", 5-tab navigation, and FAB for "เปิดรายการเข้าพัก". |
| **Room Map** (ผังห้อง) | `lib/screens/room_map_screen.dart` | Real-time visual room board. Summary bar (Vacant / Occupied pill counts, Thai date), rooms grouped by zone. Vacant card -> opens Booking Form pre-assigned. Occupied card -> opens Bottom Sheet with guest summary, stay details, and instant "เช็คเอาท์ห้องนี้" action with checklist inspection. |
| **Stays & Bookings** (ตารางเข้าพัก) | `lib/screens/stay_list_screen.dart` | Dual-mode manager: <br>1) **List View**: Keyword search (name, phone, room, zone, notes), status filter chips (All, Waiting Check-in, Checked-in, Checked-out), StayCards with financial breakdown and contextual actions.<br>2) **Calendar View**: Month navigation, Thai Buddhist era month-year header, 7-day grid with status indicator dots, day selection, and daily arrival/departure/occupancy agenda. |
| **Booking Form** (เปิดรายการเข้าพัก / แก้ไข) | `lib/screens/booking_form_screen.dart` | Guest name & phone with live auto-lookup (>= 9 digits normalized), date range picker, dynamic room availability filtering (overlap detection and pet-friendly constraint), guest counter (1 to max_guests), extra bed toggle (+200 THB flat), pet toggle (+200 THB/night per room), deposit amount & paid toggle, discount amount, ID verified checkbox, note, check-in immediately toggle, and real-time live price calculation. |
| **Stay Actions** (ต่อเวลา & ตรวจห้อง) | `lib/screens/stay_actions.dart` | Modular dialogs: <br>1) `showExtendStayDialog`: new checkout date picker, discount adjustment, overlap validation, stay extension update.<br>2) `showCheckoutInspectionDialog`: 5-point room inspection checklist before checkout with mandatory damage note. |
| **Guest Feedback** (แบบประเมิน) | `lib/screens/feedback_form_screen.dart` | Post-checkout satisfaction survey: 1-5 star ratings for Cleanliness, Service, Facility, Overall; would return toggle; freeform comment. |
| **Dashboard** (ภาพรวม) | `lib/screens/dashboard_screen.dart` | Analytics and management dashboard: Filter presets (Today, Last 7 Days, This Month, Custom Date Range), Occupancy Rate card with progress bar, 8 metric KPI cards, Daily Revenue bar chart, Daily Occupancy bar chart, Booking Status donut chart, Deposit Status donut chart, financial & feedback summaries. |
| **Manage Rooms** (ห้องพัก) | `lib/screens/manage_rooms_screen.dart` | Room management CRUD: List rooms with occupancy state and specifications; Add/Edit dialog (Name, Zone, Type, Price, Base Guests, Max Guests, Extra Guest Fee, Pet-friendly toggle); Delete confirmation showing count of associated historical stays. |
| **Guest List** (ลูกค้า) | `lib/screens/guest_list_screen.dart` | Guest registry directory: Search by name or phone, regular-only filter, customer type filter, sorting (latest stay, stay count, lifetime spend, alphabetical name), guest card with lifetime metrics. |
| **Guest Details** (ประวัติลูกค้า) | `lib/screens/guest_detail_screen.dart` | Individual customer dossier: Profile card, permanent notes, preferences, edit modal, instant "สร้าง Booking" button, 4 KPI cards (completed stays, total nights, lifetime value, total discount), recommendation banner proposing regular promotion (if completed stays >= 3), and chronological booking history. |

### 2.2 Domain Business Rules & Calculations

1. **Pricing Formula (`PriceBreakdown`)**:
   $$\text{Room Total} = \text{Room Rate} \times \text{Nights}$$
   $$\text{Extra Guests Total} = \max(0, \text{Guests} - \text{Base Guests}) \times \text{Extra Guest Fee} \times \text{Nights}$$
   $$\text{Extra Bed Total} = \text{Extra Bed ? } 200 \text{ THB (Flat fee per stay, NOT per night)} : 0$$
   $$\text{Pet Total} = \text{Has Pet ? } 200 \text{ THB} \times \text{Nights (Per room per night, NOT multiplied by pet count)} : 0$$
   $$\text{Gross Total} = \text{Room Total} + \text{Extra Guests Total} + \text{Extra Bed Total} + \text{Pet Total}$$
   $$\text{Net Total} = \max(0, \text{Gross Total} - \text{Discount Amount})$$
   $$\text{Balance Due} = \max(0, \text{Net Total} - (\text{Deposit Paid ? Deposit Amount} : 0))$$

2. **Booking Date Interval**:
   - Stay intervals are half-open $[ \text{check\_in\_date}, \text{check\_out\_date} )$.
   - A room checking out on date $T$ can accept a new check-in on date $T$.
   - Two stays overlap if: $\text{Stay}_A.\text{check\_in} < \text{Stay}_B.\text{check\_out} \land \text{Stay}_A.\text{check\_out} > \text{Stay}_B.\text{check\_in}$.
   - Overlap checks apply to active bookings where $\text{status} \in \{0 \text{ (Booked)}, 1 \text{ (Checked-in)}\}$.

3. **Check-in & Check-out Protocol**:
   - Check-in requires `id_verified = true` (national ID card verified; number is not stored for privacy).
   - Check-in marks Stay `status = 1` and Room `status = 1`.
   - Cannot check-in to a room if another stay is currently active in that room (`status = 1`).
   - Check-out requires completed 5-point inspection checklist:
     1. คืนกุญแจแล้ว (Key returned)
     2. ตรวจสอบความสะอาดแล้ว (Room cleaned)
     3. อุปกรณ์ครบ (Equipment complete)
     4. ไม่พบความเสียหาย (No damage)
     5. ตรวจสอบมินิบาร์แล้ว (Minibar checked)
   - If `no_damage = false`, `inspection_note` is strictly required.
   - Check-out updates Stay `status = 2` and sets Room `status = 0` (vacant).

4. **Guest Profile Auto-linking & Regular Customer Threshold**:
   - Phone numbers are normalized by stripping all non-digit characters (`[0-9]`).
   - If normalized phone has $\ge 9$ digits, guest profile is matched or created automatically upon booking creation.
   - When a guest accumulates $\ge 3$ completed stays, system recommends upgrading to "ลูกค้าประจำ" (Regular Guest).

5. **Analytics & Occupancy Metrics**:
   - Total Room Nights Capacity in period $[ \text{start}, \text{end} ] = \text{Total Rooms} \times \text{Days in range}$.
   - Occupied Room Nights = Sum of occupied rooms on each calendar day in range.
   - Occupancy Rate = $\frac{\text{Occupied Room Nights}}{\text{Total Capacity}}$.

---

## 3. Data Storage & Schema Mapping

### 3.1 Current SQLite Storage vs Target Portable Schema

| Concept | Flutter SQLite (`sqflite`) | Target SQLite 3 (Stage 1) | Target Supabase PostgreSQL (Stage 2) |
|---|---|---|---|
| **Primary Keys** | `INTEGER PRIMARY KEY AUTOINCREMENT` | `TEXT` (PHP UUIDv4 string) | `UUID` (PostgreSQL uuid) |
| **Foreign Keys** | `INTEGER` references | `TEXT` references | `UUID` references with FK constraints |
| **Monetary Values** | `REAL` (floating point Baht) | `INTEGER` (Satang: $1\text{ THB} = 100\text{ Satang}$) | `BIGINT` (Satang: $1\text{ THB} = 100\text{ Satang}$) |
| **Booleans** | `INTEGER` (0 / 1) | `INTEGER` (0 / 1) | `BOOLEAN` (true / false) |
| **Timestamps** | `TEXT` ISO-8601 UTC | `TEXT` ISO-8601 UTC | `TIMESTAMPTZ` UTC |
| **JSON Fields** | N/A | `TEXT` | `JSONB` |
| **Audit Logs** | N/A | `audit_logs` table | `audit_logs` table |
| **Security / RLS**| None (local file) | Protected by backend & file permissions | `ROW LEVEL SECURITY` enabled on all tables, no public policies |

---

## 4. Technology & Component Mapping Table

| Flutter Component / Package | Web Application Equivalent | Implementation Details |
|---|---|---|
| `MaterialApp` & `ThemeData` | Tailwind CSS + CSS Variables | Defined in `tailwind.config.js` and `resources/css/app.css` matching brand palette (`#2585E6`, `#1565C0`, `#F6FAFE`, `#EF6C58`, etc.). |
| `IndexedStack` & `NavigationBar` | Server-rendered Layout + SPA Tab Router | Responsive layout with desktop sidebar / mobile bottom bar; seamless page transitions. |
| `GridView` (Room Map) | CSS Grid (`grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3`) | Responsive room tiles with pet tags, status indicators, and hover micro-animations. |
| `showModalBottomSheet` | Native accessible HTML `<dialog>` controlled from `resources/js/app.js` | Modal on mobile and desktop with browser focus management and Escape dismissal. |
| `showDateRangePicker` | Native HTML `<input type="date">` / JS Calendar Component | Intuitive dual-date picker with Buddhist era display and validation. |
| `SegmentedButton` | Tailwind segmented pill toggle | Vanilla JS toggles between list view and calendar grid. |
| `ValueNotifier<int> dbRevision` | Native CustomEvent / Fetch API State Updates | `window.dispatchEvent(new CustomEvent('db-changed'))` to reload sections dynamically without full-page flickers where appropriate. |
| `SnackBar` | Toast notifications in `resources/js/core/dom.js` | Floating alerts (success, warning, error) with auto-dismiss and Thai copy. |
| `CustomPainter` (Donut / Bar charts) | Pure SVG / Canvas / CSS Chart Renderer | Zero-dependency responsive SVG charts ported from Flutter's `CustomPainter` algorithms. |
| `AssetImage` (`assets/images/*.webp`) | WebP assets in `public/images/` | Migrated resort branding logos served with optimal HTTP cache headers. |

---

## 5. Native Mobile Features vs Web Equivalents

| Capability | Actual mobile source | Web implementation / decision | Limitations & mitigations |
|---|---|---|---|
| **Camera / Gallery** | Not present; no image-picker dependency or permission | Authenticated attachment input accepts JPEG, PNG, WebP, and PDF as a new web requirement | Mobile browsers can offer camera capture; server MIME-sniffs, size-limits, randomly names, and stores outside `public/`. |
| **Local Storage File** | SQLite file in app sandbox | SQLite in Docker named volume (`storage/database/`) | Mounted to non-root PHP user with WAL mode enabled. |
| **GPS / notifications / biometrics** | Not present and no related dependency | Not invented for the web migration | Could be added later with separate permission and privacy design. |
| **Printing / share** | No native print/share feature | Print-friendly CSS and CSV were added because the web brief requires reporting/export | Browser print output depends on the selected printer/PDF driver. |

---

## 6. Assumptions & Architectural Decisions

1. **UUIDv4 for All Identifiers**: All entities (`rooms`, `guests`, `stays`, `inspections`, `feedbacks`, `users`, `audit_logs`, `uploads`) use RFC 4122 UUIDv4 strings. This prevents ID collisions, permits client-side ID generation, and ensures zero schema migration breakage when transferring between SQLite and PostgreSQL.
2. **Integer Minor Units (Satang) for Money**: To avoid floating point inaccuracies (e.g., `0.1 + 0.2 != 0.3`), all prices, fees, discounts, and deposits are stored as integers representing Satang ($1\text{ THB} = 100\text{ Satang}$). Helper functions format to Baht for display (`formatBaht`).
3. **Staff Authentication & RBAC**: The web application introduces multi-user authentication with three roles:
   - `admin`: Full access to rooms, bookings, guests, reports, settings, user management, and audit logs.
   - `front_desk`: Check-in, check-out, create/edit bookings, manage guests, record inspections, record feedback.
   - `housekeeping`: Read-only room board, checkout checklist inspection recording, room clean status updating.
4. **Secure File Storage**: Guest attachments (ID cards, receipts, damage photos) are saved in non-web-accessible `storage/app/uploads/` and served exclusively through authenticated routes using Nginx `X-Accel-Redirect`.
5. **Timezone Handling**: System stores all timestamps in UTC ISO-8601 format. Presentation layer formats dates in `Asia/Bangkok` (UTC+7) using Buddhist Era ($+543$ years) for Thai text.
6. **Zero External Framework Dependency**: In compliance with directives, the PHP backend runs a lightweight, robust custom micro-framework (`App\Core\`) adhering strictly to PSR-4, PSR-7 concepts, and PDO abstraction without Laravel or Symfony.
7. **Web-only security additions**: The source application deliberately had no accounts because it ran on one counter device. The website introduces PHP sessions, roles, CSRF, throttling, audits, and protected attachments because a networked multi-user service needs a different trust boundary.
8. **Role interpretation**: `admin` has all permissions, `front_desk` can perform daily operations, and `housekeeping` can read the board, upload inspection evidence, and complete checkout inspections. These roles are a web requirement rather than a recovered mobile rule.
9. **Import source availability**: No device SQLite/Hive/JSON data file exists in the repository; `import:flutter` reports the expected device-export requirement rather than fabricating guest data. The original source remains recoverable at tag `flutter-original`.

---

## 7. Feature Parity Checklist

| # | Feature / Screen | Status | Notes |
|---|---|---|---|
| 1 | Brand Splash & Startup Initialization | [x] | Animated logo, Thai tagline, loading indicator |
| 2 | Home Layout & Responsive Navigation (5 tabs) | [x] | Room map, stays, dashboard, rooms, guests |
| 3 | Room Board (Summary stats, grouped by zone) | [x] | Vacant/occupied counts, nights left labels |
| 4 | Room Tile State Styling & Pet Friendly Tag | [x] | Exact color mapping (`AppColors`) |
| 5 | Room Details & Instant Checkout Sheet | [x] | Modal sheet with stay summary & actions |
| 6 | 5-Point Checkout Inspection Checklist | [x] | Key, cleanliness, equipment, damage, minibar |
| 7 | Mandatory Damage Note Validation | [x] | Enforced if `no_damage = false` |
| 8 | Guest Satisfaction Feedback Form (1-5 stars) | [x] | Cleanliness, service, facility, overall, return |
| 9 | Booking Management (List & Calendar Views) | [x] | Segmented toggle, full search & filters |
| 10| Buddhist Calendar Month Grid with Status Dots | [x] | Thai month-year, status dots, day agenda |
| 11| Booking Creation & Edit Form | [x] | Complete validation, real-time recalculation |
| 12| Live Guest Auto-lookup by Normalized Phone | [x] | Matches $\ge 9$ digits phone number |
| 13| Stay Interval Overlap Validation | [x] | Prevents double bookings for active stays |
| 14| Real-time Price Breakdown Calculation | [x] | Nights, extra guests, flat bed fee, pet fee, discount, deposit |
| 15| Check-in Immediate Switch with ID Check | [x] | Enforces ID verification before check-in |
| 16| Extend Stay Modal with Re-calculation | [x] | Date extension, overlap check, price delta |
| 17| Dashboard Analytics & Period Filtering | [x] | Today, 7 days, month, custom date range |
| 18| Occupancy Rate & Room Nights Calculation | [x] | Accurate day-count and capacity calculation |
| 19| Daily Revenue & Occupancy Bar Charts | [x] | Pure SVG/CSS interactive charts |
| 20| Booking & Deposit Status Donut Charts | [x] | Custom donut charts matching Flutter custom painter |
| 21| Room CRUD Management & Delete Safeguard | [x] | Warns and cascades associated stays |
| 22| Guest Registry Directory & Sorting | [x] | Sort by latest, stay count, spend, name |
| 23| Regular Customer Promotion Banner | [x] | Triggers when completed stays $\ge 3$ |
| 24| Guest Profile & Chronological History | [x] | Dossier with permanent note & preferences |
| 25| Role-based Access Control (Admin/FrontDesk/Maid)| [x] | Session auth, password hashing, throttling |
| 26| Secure Guest Photo/Attachment Uploads | [x] | MIME validation, non-public storage, X-Accel-Redirect |
| 27| CSV Report Export | [x] | UTF-8 Booking CSV with Thai support; the mobile source had no export |
| 28| Print-friendly dashboard and logs | [x] | Print stylesheet (`@media print`); the mobile source had no print feature |
| 29| Audit Logging (`audit_logs`) | [x] | Tracks mutations with before/after diffs |
| 30| Dual-driver DB Support (SQLite & PostgreSQL) | [x] | Seamless driver switching & `db:transfer` CLI |
| 31| Docker Compose Single-command Deployment | [x] | Multi-stage build, healthchecks, volumes |

## 8. Verification record (2026-10-23)

- All PHP files pass `php -l` on PHP 8.3.36.
- Tailwind compilation, content hashing, manifest generation, esbuild bundling, and JavaScript syntax checks pass.
- PHPStan passes at level 6; PSR-12/php-cs-fixer dry-run reports no changes.
- SQLite migration and idempotent seed pass from an empty database.
- PHPUnit passes pricing, unpaid-deposit, migration filename/table/column parity, migration/seed, and repository overlap tests.
- HTTP smoke verification passes login, Thai guest creation, search/status filtering, check-in, checkout inspection, feedback, CSV export, deletion, and unauthorized handling against the PHP front controller.
- Browser QA passes the compiled login, room board, booking dialog, preset/custom analytics UI, bar charts, and donut summaries.
- `docker compose up -d --build` passes on Docker Desktop. The SQLite migration and seed complete during startup, both PHP-FPM and Nginx reach `healthy`, `/health` returns 200, `/` redirects to `/login`, and the login page returns 200. Live PostgreSQL profile and SQLite-to-PostgreSQL transfer verification remain covered by CI and should be repeated against the target Supabase project before production cutover.
