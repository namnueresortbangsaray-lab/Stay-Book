# Action Audit — Stay Book Web

วันที่ตรวจสอบ: 30 ตุลาคม 2569  
ขอบเขต: Web application ปัจจุบัน (`resources/views` และ `resources/js/app.js`) ในบทบาท Admin, Front Desk และ Housekeeping

## หลักเกณฑ์ที่ใช้

- หนึ่งหน้าหรือหนึ่งการ์ดมี Primary action ที่เด่นเพียงรายการเดียว
- งานรองใช้ Secondary/Ghost และงานระดับแถวใช้เมนู `…`
- งานลบอยู่ท้ายเมนู แยกด้วยเส้น และต้องยืนยันพร้อมข้อความผลกระทบ
- ปุ่มข้อความสูง 36/40/44 px ตามขนาด `sm/md/lg`; มือถือบังคับอย่างน้อย 44 px
- ปุ่มไอคอนต้องมี `aria-label` และ tooltip ผ่าน `title`
- รายการที่ผู้ใช้ไม่มีสิทธิ์จะไม่แสดงตามกฎเดิมของระบบ

## Global shell และ Navigation

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| Sidebar | ไปงานวันนี้ | งานวันนี้ / nav link | Navigation item / 44 px | ซ้าย desktop; bottom nav มือถือ | เส้นทางหลัก |
| Sidebar | ไปผังห้อง | ผังห้อง / nav link | Navigation item / 44 px | ซ้าย desktop; bottom nav มือถือ | เส้นทางหลัก |
| Sidebar | ไปตารางเข้าพัก | ตารางเข้าพัก / nav link | Navigation item / 44 px | ซ้าย desktop; bottom nav มือถือ | เส้นทางหลัก |
| Sidebar | ไปภาพรวม | ภาพรวม / nav link | Navigation item / 44 px | ซ้าย desktop; bottom nav มือถือ | เส้นทางหลัก |
| Sidebar | ไปห้องพัก | ห้องพัก / nav link | Navigation item / 44 px | ซ้าย desktop; เมนูเพิ่มเติมมือถือ | จำกัดสิทธิ์ manager และลด bottom nav เหลือ 5 |
| Sidebar | ไปลูกค้า | ลูกค้า / nav link | Navigation item / 44 px | ซ้าย desktop; เมนูเพิ่มเติมมือถือ | งานรองบนมือถือ |
| Sidebar | ออกจากระบบ | ออกจากระบบ / ปุ่มข้อความเล็ก | Ghost Button / md | ท้าย sidebar | ลดความเด่นแต่ยังค้นพบง่าย |
| Top bar | ค้นหาด่วน | ไอคอนค้นหา | Secondary Button / md | top bar desktop | เปิด Command palette |
| Top bar | สร้าง Booking | `+ เปิด Booking` / primary | Primary Button / md, ป้าย `สร้าง Booking` | top bar desktop | ใช้คำมาตรฐานเดียวกับ dialog |
| Mobile | สร้าง Booking | ไม่มีจุดเรียกคงที่ | Primary FAB / 44+ px | เหนือ bottom nav, safe-area aware | เข้าถึงงานหลักด้วยนิ้วโป้ง |
| Mobile bottom nav | เมนูเพิ่มเติม | เดิมมี 6 รายการ | Navigation item ลำดับที่ 5 | เปิด dialog รวมลูกค้า/ห้องพัก/ค้นหา | จำกัด navigation หลักไม่เกิน 5 |
| Command palette | เลือกหน้า | การ์ดข้อความ | Command result button / 44 px | dialog; Arrow keys/Enter/Esc | ใช้เมาส์และคีย์บอร์ดได้ |
| Command palette | เลือก Booking | ชื่อแขก/ห้อง | Command result button / 44 px | ใต้ผลลัพธ์หน้า | เปิดรายการที่เกี่ยวข้อง |
| Dialog ทุกชนิด | ปิด | ไอคอน X รูปแบบต่างกัน | IconButton / md | มุมขวาบน; `aria-label` + tooltip | มาตรฐานเดียวกัน |
| Dialog ทุกชนิด | ยกเลิก | Secondary button | Ghost Button / md | ซ้ายของปุ่มยืนยัน | ลดการแข่งขันกับ Primary |

## งานวันนี้และผังห้อง

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| งานวันนี้ header | ค้นหาทุกอย่าง | Secondary button | Secondary Button / md | ขวาบน; wrap บนจอเล็ก | เครื่องมือรอง |
| การ์ดผู้มาถึง | เช็กอิน | Primary button | Primary Button / sm (มือถือ 44 px) | ขวาการ์ด | งานหลักตามสถานะ |
| การ์ดเช็กเอาต์ | ตรวจห้อง | Primary button | Primary Button / sm (มือถือ 44 px) | ขวาการ์ด | เปิด checklist ก่อนเช็กเอาต์ |
| มัดจำค้าง | ดูรายการทั้งหมด | text link | Link Button | header ของ section | นำไปหน้ารวมโดยไม่แย่ง Primary |
| ผังห้องว่าง | สร้าง Booking | ทั้งการ์ด clickable | Interactive Card / 44+ px | grid; 1 คอลัมน์ที่ 360 px | ใช้พื้นที่การ์ดเป็น target |
| ผังห้องมีแขก | ดูรายละเอียด | ทั้งการ์ด clickable | Interactive Card / 44+ px | grid | พาไป Booking ของแขก |
| Empty room map | เพิ่มห้องพักแรก | Primary button | Primary Button / md | กลาง empty state | next step ที่ชัดเจน |

## ตารางเข้าพักและปฏิทิน

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| Page header | สร้าง Booking | `+ เปิด Booking` | Primary Button / md, `สร้าง Booking` | header desktop; FAB มือถือ | Primary ของหน้า |
| View switcher | รายการ/ปฏิทิน | ปุ่มพื้นหลังสลับเอง | SegmentedControl / `aria-pressed` | header | สื่อสถานะเลือกอย่างถูกต้อง |
| Filters | ค้นหา Booking | text input | Input / 40 px, 16 px บนมือถือ | toolbar; เต็มแถวมือถือ | ป้องกัน iOS zoom |
| Filters | สถานะทั้งหมด | native select | Select / 40 px | ข้าง search; stack มือถือ | รูปแบบ filter มาตรฐาน |
| Booking รอเช็กอิน | เช็กอิน | Primary | Primary Button / sm | ซ้ายแถว action | หนึ่ง Primary ตามสถานะ |
| Booking กำลังพัก | เช็กเอาต์ | Primary | Primary Button / sm | ซ้ายแถว action | หนึ่ง Primary ตามสถานะ |
| Booking เสร็จแล้ว | บันทึกแบบประเมิน | Secondary | Secondary Button / sm | ซ้ายแถว action | next useful action แต่ไม่ใช่งานเสี่ยง |
| Booking card | เมนูเพิ่มเติม | เดิมไม่มี; แสดงหลายปุ่มพร้อมกัน | IconButton `…` / sm | ขวาสุด; bottom sheet มือถือ | ลด visual noise |
| Booking menu | แก้ไข Booking | Secondary button บนการ์ด | Dropdown item | รายการแรกเมื่อสถานะรอ | งานรองระดับรายการ |
| Booking menu | ต่อระยะเวลาเข้าพัก | Secondary button บนการ์ด | Dropdown item | เมื่อกำลังพัก | งานรองตามสถานะ |
| Booking menu | แนบไฟล์ | Secondary button บนการ์ด | Dropdown item | ทุกสถานะ | ใช้ไม่บ่อย |
| Booking menu | ลบ Booking | ปุ่มแดงบนการ์ด | Destructive menu item; แยกเส้น; อยู่ท้าย | dropdown / mobile sheet | ลดการกดพลาดและรักษาลำดับอันตราย |
| เอกสารแนบ | เปิดไฟล์ | ชื่อไฟล์เป็น link | Inline link | ใต้ข้อมูลการเงิน | เปิดแท็บใหม่พร้อม `noopener` |
| Empty bookings | สร้าง Booking | มีแต่ข้อความ | Primary Button / md | กลาง empty state | บอก next step |
| Calendar header | เดือนก่อนหน้า | ปุ่มไอคอน | IconButton / sm | ซ้ายชื่อเดือน | target/label สม่ำเสมอ |
| Calendar header | เดือนถัดไป | ปุ่มไอคอน | IconButton / sm | ขวาชื่อเดือน | target/label สม่ำเสมอ |
| Calendar header | วันนี้ | Secondary button | Secondary Button / sm | ขวา header | กลับบริบทปัจจุบัน |
| Calendar grid | เลือกวัน | day cell | Interactive calendar cell | scroll ภายใน container บนมือถือ | ไม่ทำให้ทั้งหน้าล้นแนวนอน |

## ภาพรวมและรายงาน

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| Range presets | วันนี้/7 วันล่าสุด/เดือนนี้ | ปุ่มเล็ก 3 ปุ่ม | SegmentedControl / `aria-pressed` | 3 คอลัมน์มือถือ | เห็นค่าที่เลือกชัด |
| Custom range | วันเริ่มต้น/วันสิ้นสุด | date input | Input / 44 px mobile | stack มือถือ | แตะง่าย |
| Custom range | แสดงผล | Primary button | Primary Button / md | หลังช่วงวันที่ | Primary ของ toolbar |
| Export | ส่งออก CSV | Secondary link button | Secondary Button / md | toolbar | download ไม่เปลี่ยนข้อมูล |
| Print | พิมพ์รายงาน | Secondary button | Secondary Button / md | toolbar | งานรอง |

## ห้องพักและลูกค้า

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| ห้องพัก header | เพิ่มห้องพัก | Primary button | Primary Button / md | ขวาบน | Primary ของหน้า |
| Room row | แก้ไข | Secondary button | Secondary Button / sm | ขวาแถว | งานหลักระดับรายการ |
| Room row | เมนูเพิ่มเติม | เดิมไม่มี | IconButton `…` / sm | ถัดจากแก้ไข | รวมงานเสี่ยง |
| Room menu | ลบห้องพัก | ปุ่มแดงบนแถว | Destructive menu item | menu item ท้ายสุด | ลดการลบโดยไม่ตั้งใจ |
| Guest toolbar | ค้นหา | input | Input / 40 px | เต็มแถวมือถือ | ค้นหาหลัก |
| Guest toolbar | เรียงลำดับ | select | Select / 40 px | toolbar | รูปแบบมาตรฐาน |
| Guest toolbar | เฉพาะลูกค้าประจำ | checkbox | Checkbox filter | toolbar | filter แบบ boolean |
| Guest card | ดู/แก้ไขรายละเอียด | ทั้งการ์ด clickable | Interactive Card / 44+ px | grid responsive | target ใหญ่และไม่เพิ่มปุ่มซ้ำ |
| Guest dialog | บันทึกการเปลี่ยนแปลง | Primary submit | Primary Button / md | footer ขวา | action หลักของฟอร์ม |

## ฟอร์มและ High-stakes actions

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| Booking dialog | สร้าง Booking | `บันทึก Booking` | Primary Button / md, dynamic label | sticky-like footer ของ dialog; full width เมื่อจำเป็น | ป้ายระบุผลลัพธ์ |
| Booking dialog | แก้ไข Booking | `บันทึก Booking` | Primary Button / md, `บันทึกการเปลี่ยนแปลง` | footer | แยก create/edit ชัด |
| Room dialog | เพิ่มห้องพัก | `บันทึกห้องพัก` | Primary Button / md, dynamic label | footer | ป้ายระบุผลลัพธ์ |
| Room dialog | แก้ไขห้องพัก | `บันทึกห้องพัก` | Primary Button / md, `บันทึกการเปลี่ยนแปลง` | footer | ลดความกำกวม |
| Checkout dialog | ยืนยันเช็กเอาต์ | `ยืนยันและบันทึก` | Primary Button / md | หลัง checklist | ระบุ irreversible transition |
| Extend dialog | บันทึกวันเช็กเอาต์ใหม่ | `ยืนยันและบันทึก` | Primary Button / md | footer | ระบุสิ่งที่เปลี่ยน |
| Feedback dialog | บันทึกแบบประเมิน | `ยืนยันและบันทึก` | Primary Button / md | footer | ระบุผลลัพธ์ |
| Upload dialog | แนบไฟล์ | `ยืนยันและบันทึก` | Primary Button / md | footer | ระบุผลลัพธ์ |
| Confirm check-in | ยืนยันเช็กอิน | native `confirm()` | Confirmation dialog + Primary | modal | ทบทวนตัวตน/การชำระก่อนเปลี่ยนสถานะ |
| Confirm delete booking | ลบ Booking | native `confirm()` | Confirmation dialog + Destructive | modal; focus ที่ปุ่มยืนยัน | บอกชื่อแขก/ห้องและผลกระทบ |
| Confirm delete room | ลบห้องพัก | native `confirm()` | Confirmation dialog + Destructive | modal | บอกข้อจำกัดเมื่อมีประวัติ |
| ทุกฟอร์ม | Submit ขณะบันทึก | disabled อย่างเดียว | Loading button + spinner + `aria-busy` | ตำแหน่งเดิม | ป้องกัน submit ซ้ำและแสดงสถานะ |
| ทุกฟอร์ม | Validation error | toast รวม | Inline error + `aria-invalid` และ toast สรุป | ใต้ field | แก้ไขได้ตรงจุด |

## Authentication และ Error

| หน้า/ตำแหน่ง | Action | ก่อนปรับ: ป้าย/รูปแบบ | หลังปรับ: Pattern/Variant/Size | Placement และ responsive | เหตุผล |
|---|---|---|---|---|---|
| Login | เข้าสู่ระบบ | Primary full width | Primary Button / lg | เต็มความกว้างฟอร์ม | Primary เดียวของหน้า |
| Error page | กลับหน้าหลัก | Primary full width | Primary Button / md | ใต้ข้อความผิดพลาด | recovery path ที่ชัดเจน |
| Loading error | ลองอีกครั้ง | Primary button | Primary Button / md | กลาง error state | recovery action |

## รายการที่ต้องตัดสินใจเพิ่มเติม

- ระบบปัจจุบันไม่มี route/ข้อมูลสำหรับหน้า Payments, Housekeeping, Settings และ Notifications แบบแยกหน้า จึงไม่สร้าง navigation หรือ behavior ใหม่โดยพลการ
- Housekeeping ยังคงใช้หน้า “งานวันนี้” และ Checkout checklist ตามสิทธิ์เดิม
- การยกเลิก Booking ปัจจุบันใช้ endpoint ลบเดิมและไม่มี API สำหรับ Undo/Restore จึงใช้ confirmation ที่ชัดเจนแทน เพื่อไม่เปลี่ยน business logic
- โค้ด Flutter ใน `stay_book_app/` เป็น legacy client แยกจาก Web application และไม่ได้รวมใน audit รอบนี้
