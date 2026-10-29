# Stay Book — UX/UI Reimagining Proposal

## Users and jobs-to-be-done

| Persona | Highest-frequency jobs |
|---|---|
| Front desk | See today’s arrivals/departures, find availability, create a booking, check in/out, collect/verify deposit |
| Manager | Watch occupancy/revenue, resolve conflicts, review guest history, configure rooms, export reports |
| Housekeeping | See occupied/departing rooms, complete inspection, attach evidence |
| Owner | Read a compact operating summary, revenue trends, unpaid balances, and guest satisfaction |

The five most frequent tasks should take no more than three actions from the home screen: create booking, check in, check out, find a guest/booking, and see available rooms.

## Current pain points

- The product opens on a passive room grid rather than the work that needs attention today.
- Important actions are distributed across room map, booking list, and analytics without a shared task summary.
- Every role sees the same controls even when the server will deny the action.
- Search is page-specific; staff cannot quickly jump to a guest, booking, or room.
- Dialog close/cancel controls are broken, error feedback is toast-only, and submit buttons allow duplicate actions.
- Calendar status depends on tiny color dots and does not provide timeline density or clear arrival/departure cues.
- Attachments can be uploaded but not rediscovered from the interface.
- Browser Back and deep links do not retain the selected workspace.

## Concept directions

### A. Today-first operations desk — recommended

A calm command center organizes arrivals, departures, in-house guests, unpaid balances, and room availability into actionable queues. A global search/command palette is always one shortcut away.

**Pros:** matches front-desk rhythm, fastest daily actions, useful to every role, can be built from existing data without schema changes.  
**Cons:** detailed multi-week planning remains a separate booking view.

### B. Timeline-first booking board

The default view is a horizontal room-by-date timeline with drag/drop movement and inline extension.

**Pros:** strongest planning visibility and direct manipulation.  
**Cons:** dense on phones; drag/drop needs undo, concurrency controls, and a deliberate policy for room moves. Those decisions touch booking behavior and need a separate approval.

### C. Visual room-map concierge

The room/villa map remains central, enriched with status, guest, departure, balance, and one-tap actions.

**Pros:** familiar, visual, excellent for small properties.  
**Cons:** less effective for future demand, arrivals, reporting, and guest-centric work.

## Recommended direction

Choose **Today-first operations desk**, while retaining the visual room map and booking calendar as focused workspaces. It solves the most frequent staff tasks with existing data, avoids unapproved schema/business changes, and adapts cleanly by role.

## Information architecture

```text
Stay Book
├── งานวันนี้ (default)
│   ├── arrivals / departures / in-house
│   ├── available rooms
│   └── unpaid deposits and balances
├── การจอง
│   ├── task list
│   └── monthly calendar
├── ห้องพัก
│   ├── live room map
│   └── room configuration (authorized roles)
├── ลูกค้า
│   └── Guest 360 profile
├── รายงาน
│   ├── KPIs and charts
│   └── CSV / print
└── บัญชีผู้ใช้
    └── session identity and logout
```

Global `Ctrl/Cmd+K`: search guest, booking, room, or launch “เปิดรายการเข้าพัก”. Navigation state is stored in the URL hash so Back/Forward and deep links work.

## Key wireframes

### App shell and Today

```text
┌ Sidebar ─────────┐ ┌ งานวันนี้ ──────────────── [ค้นหา ⌘K] [+ Booking] ┐
│ งานวันนี้        │ │  ว่าง 12   เข้าพัก 8   เข้า 3   ออก 2             │
│ การจอง           │ ├───────────────────────────────────────────────────┤
│ ห้องพัก           │ │ ต้องทำก่อน        │ กำลังเข้าพัก │ ยอดค้างชำระ     │
│ ลูกค้า            │ │ [เช็กอิน Somchai] │ [ห้อง 4 ...] │ [Booking ...]    │
│ รายงาน            │ │ [ตรวจห้อง 2]      │              │                  │
└──────────────────┘ └───────────────────────────────────────────────────┘
```

### Booking workspace

```text
┌ การจอง ── [รายการ | ปฏิทิน] ── [ค้นหา] [สถานะ] [+ Booking] ┐
│ รอเช็กอิน  Guest · Room · Dates · Balance  [เช็กอิน] [แก้ไข] │
│ กำลังพัก   Guest · Room · Departure        [เช็กเอาต์] [ต่อ]  │
│ เสร็จแล้ว  Guest · Room · Rating           [Feedback]         │
└───────────────────────────────────────────────────────────────┘
```

### Quick-create drawer/dialog

```text
ข้อมูลลูกค้า → วันที่/ห้อง → เสริม/มัดจำ → ยืนยัน
[โทรศัพท์] [ชื่อ]   [เข้า] [ออก]   [ห้องที่ว่างและราคา]
                           ┌ Price summary ┐
                           │ room / extras │
                           │ net / balance │
                           └───────────────┘
                                  [บันทึก Booking]
```

### Mobile

```text
Header: งานวันนี้                         [+]
Cards: urgent tasks → arrivals → in-house → balances
Bottom nav: วันนี้ | การจอง | ห้อง | ลูกค้า | รายงาน
```

## Design system

- Preserve the existing blue/ink/coral palette and derive only tints/opacity.
- Noto Sans Thai as the single UI family; weights 400/500/600 where possible.
- Spacing on a 4/8px base, 12px controls, 16px cards, 20px dialogs.
- Hairline borders and three shadow levels already centralized in Tailwind tokens.
- Every status pairs color with an icon and text label.
- Minimum 44px targets, visible focus rings, native semantic controls, reduced-motion support.
- Skeleton/empty/error/retry states share one consistent pattern.

## Implementation boundary

This pass implements the Today workspace, global command palette, role-adaptive controls, URL-aware navigation, reliable dialog/form states, attachment discovery, report consistency, and accessibility improvements.

Dedicated housekeeping states (`Dirty → Cleaning → Inspected → Ready`), payment ledger/invoices, and user/settings management are **Needs decision** items because they require schema, migration, authorization, and business-rule decisions covered by the project’s Ask First policy. Existing checkout inspections, balance display, role enforcement, reports, and CLI user management remain intact.

## Implemented in this pass

- Today-first operations desk with arrivals, departures, in-house rooms, and deposit follow-up counts.
- Global command palette (`Ctrl/Cmd + K`) covering workspaces, guests, bookings, phone numbers, and rooms.
- Role-aware controls so housekeeping sees inspection/upload work without dead-end administrative actions.
- Hash-based navigation for Back/Forward and direct workspace links.
- Responsive bottom navigation, scroll-safe dialogs, visible inline validation, retry states, and duplicate-submit protection.
- Existing blue/white resort palette, typography, information density, PHP stack, and vanilla JavaScript architecture retained.

