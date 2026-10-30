# Stay Book UI Guide

คู่มือนี้เป็นมาตรฐาน UI สำหรับ Web application ปัจจุบัน โดยคง quiet-luxury palette และ business behavior เดิม

## 1. Action hierarchy

1. หนึ่ง view หรือ dialog ใช้ Primary action เด่นได้หนึ่งรายการ
2. งานรองที่ใช้บ่อยใช้ Secondary
3. ยกเลิก/ปิด/งานเบาใช้ Ghost หรือ Link
4. งานระดับแถวที่ไม่ใช่งานหลักอยู่ในเมนู `…`
5. Destructive action อยู่ท้ายเมนู แยกด้วย separator และต้องยืนยัน

## 2. Button API

ฟังก์ชัน reusable อยู่ใน `resources/js/core/ui.js`:

- `button({ label, variant, size, iconName, attributes })`
- `iconButton({ label, iconName, size, attributes })`
- `menuTriggerButton({ context, id, label, size })`
- `openDropdownMenu(trigger, items, label)` / `closeDropdownMenu()`
- `segmentedControl({ label, options, value, dataAttribute })`
- `selectControl({ name, label, value, options })`
- `splitButton(...)` สำหรับกรณีที่ primary เดียวมีทางเลือกใกล้เคียงกันจริง ๆ; ไม่ควรใช้แทน overflow menu ทั่วไป
- `setButtonLoading(button, loading, label)`

CSS variants:

| Variant | Class | ใช้เมื่อ |
|---|---|---|
| Primary | `.btn-primary` | งานหลักของ view/dialog |
| Secondary | `.btn-secondary` | งานรองที่ใช้บ่อย |
| Ghost | `.btn-ghost` | ยกเลิก ปิด หรืองานเบา |
| Destructive | `.btn-destructive` | ยืนยันการลบหลังผ่าน confirmation |
| Link | `.btn-link` | navigation/action ในเนื้อหา |

ขนาด:

| Size | Class | ความสูง | ใช้เมื่อ |
|---|---|---:|---|
| sm | `.btn-sm` / `.icon-button-sm` | 36 px | dense row/card บน desktop |
| md | `.btn-md` / `.icon-button-md` | 40 px | ค่าเริ่มต้น |
| lg | `.btn-lg` / `.icon-button-lg` | 44 px | login และ action สำคัญ |

บนหน้าจอต่ำกว่า 768 px ปุ่ม sm/md และ icon button ต้องมี tap target อย่างน้อย 44 px

## 3. Placement rules

- Page header: ชื่อหน้าอยู่ซ้าย, Primary action อยู่ขวา; มือถือให้ stack หรือใช้ FAB เมื่อเป็นงานหลักที่เกิดบ่อย
- Card/row: Primary ตามสถานะอยู่ซ้ายของ action zone, เมนู `…` อยู่ขวาสุด
- Form/dialog footer: Cancel (Ghost) ก่อน Primary submit
- Filter toolbar: Search ก่อน Select/Toggle; Apply เป็น Primary เฉพาะเมื่อ filter ไม่ทำงานทันที
- Empty state: ข้อความสั้น + next step หนึ่งปุ่ม
- Mobile bottom nav: ไม่เกิน 5 รายการ; งานรองอยู่ “เพิ่มเติม”

## 4. Dropdown menu และ mobile sheet

- เมนูถูก render ที่ `document.body` เพื่อไม่ถูกตัดด้วย `overflow`
- Desktop วางชิด trigger และจำกัดความกว้าง 240 px
- มือถือแสดงเป็น bottom sheet พร้อม backdrop และ safe-area spacing
- Keyboard: `ArrowUp`, `ArrowDown`, `Home`, `End`, `Escape`; เปิดแล้ว focus รายการแรก และคืน focus ให้ trigger เมื่อปิดด้วย Escape/backdrop
- ปุ่ม trigger ต้องมี `aria-haspopup="menu"` และอัปเดต `aria-expanded`

## 5. Segmented control, Select และ Form

- Segmented control ใช้เมื่อเลือกโหมดจากตัวเลือก 2–3 ค่า เช่น รายการ/ปฏิทิน หรือช่วงรายงาน
- แต่ละ segment ใช้ `aria-pressed` เพื่อสื่อ selected state
- Select ใช้ `.field.select-field` และมี label ที่มองเห็นได้
- Input บนมือถือมี font-size อย่างน้อย 16 px เพื่อป้องกัน iOS zoom
- Error แสดงใต้ field พร้อม `aria-invalid="true"`; toast ใช้เป็นสรุปเท่านั้น
- Submit แสดง spinner, `aria-busy="true"` และ disabled ระหว่าง request

## 6. Naming glossary

| ความหมาย | ป้ายมาตรฐาน |
|---|---|
| สร้างรายการเข้าพัก | สร้าง Booking |
| แก้รายการเข้าพัก | แก้ไข Booking |
| บันทึกในโหมดแก้ไข | บันทึกการเปลี่ยนแปลง |
| เริ่มเข้าพัก | เช็กอิน |
| จบการเข้าพัก | เช็กเอาต์ |
| เพิ่มระยะเวลา | ต่อระยะเวลาเข้าพัก |
| เพิ่มเอกสาร | แนบไฟล์ |
| ลบรายการเข้าพัก | ลบ Booking |
| ออกจากหน้าต่างโดยไม่บันทึก | ยกเลิก |

หลีกเลี่ยงคำกว้าง ๆ เช่น “ตกลง”, “ดำเนินการ”, “บันทึก” เมื่อสามารถระบุผลลัพธ์ได้

## 7. Accessibility checklist

- Focus ring ต้องมองเห็นได้บนทุก interactive element
- Icon-only button ต้องมี `aria-label`, `title` และข้อความ `sr-only`
- Status ใช้สีร่วมกับ label/icon เสมอ
- Dialog ปิดได้ด้วย Escape และ focus เริ่มที่ control ที่เกี่ยวข้อง
- Command palette ใช้ Arrow keys, Enter และ Escape ได้
- ไม่มี horizontal overflow ระดับหน้า; calendar เลื่อนใน container ของตนเอง
- ความคมชัดและลำดับ tab ต้องตรวจที่ 360, 375, 768 และ 1280 px

## 8. Loading, empty และ confirmation

- Loading: skeleton ใช้กับข้อมูลที่กำลังโหลด; ปุ่ม submit ใช้ spinner
- Empty: บอกสถานะและ next step ไม่เกินหนึ่ง Primary action
- Destructive: แสดงชื่อสิ่งที่จะลบ ผลกระทบ และปุ่ม Destructive ที่มีป้ายเฉพาะ
- High-stakes transition เช่น Check-in ใช้ confirmation ที่สรุปชื่อแขกและห้อง
- Undo ต้องมี API restore รองรับก่อน; ห้ามจำลอง Undo ที่กู้ข้อมูลจริงไม่ได้
