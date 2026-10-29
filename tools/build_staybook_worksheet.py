from __future__ import annotations

from pathlib import Path
from datetime import date

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs"
OUT_PATH = OUT_DIR / "ใบงานปฏิบัติงาน_Stay_Book.docx"
BUILD_DIR = OUT_DIR / ".docx_build"

FONT = "Tahoma"
BLUE = "000000"
BLUE_LIGHT = "FFFFFF"
BLUE_PALE = "FFFFFF"
GRAY = "FFFFFF"
GRAY_ALT = "FFFFFF"
BORDER = "000000"
TEXT = "000000"
MUTED = "000000"


def set_run_font(run, size=11, bold=False, color=TEXT, italic=False):
    run.font.name = FONT
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), FONT)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), FONT)
    run._element.get_or_add_rPr().rFonts.set(qn("w:eastAsia"), FONT)
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=55, start=70, bottom=55, end=70):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for m, v in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{m}"))
        if node is None:
            node = OxmlElement(f"w:{m}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(v))
        node.set(qn("w:type"), "dxa")


def set_cell_border(cell, color=BORDER, size="5"):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        el = borders.find(qn(tag))
        if el is None:
            el = OxmlElement(tag)
            borders.append(el)
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), size)
        el.set(qn("w:color"), color)


def cant_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    el = OxmlElement("w:cantSplit")
    tr_pr.append(el)


def repeat_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    el = OxmlElement("w:tblHeader")
    el.set(qn("w:val"), "true")
    tr_pr.append(el)


def set_repeat_table_header(table):
    if table.rows:
        repeat_header(table.rows[0])


def set_cell_text(cell, value, bold=False, color=TEXT, size=9.5, align=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.25
    if align is not None:
        p.alignment = align
    r = p.add_run(str(value))
    set_run_font(r, size=size, bold=bold, color=color)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    set_cell_margins(cell)
    set_cell_border(cell)


def add_table(doc, headers, rows, widths=None, font_size=9.3, header_fill="FFFFFF"):
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    table.style = "Table Grid"
    for i, h in enumerate(headers):
        set_cell_text(table.rows[0].cells[i], h, bold=True, color="000000", size=9.3, align=WD_ALIGN_PARAGRAPH.CENTER)
        if widths:
            table.rows[0].cells[i].width = widths[i]
    repeat_header(table.rows[0])
    for ridx, row_values in enumerate(rows):
        row = table.add_row()
        cant_split(row)
        for i, value in enumerate(row_values):
            set_cell_text(row.cells[i], value, size=font_size)
            if widths:
                row.cells[i].width = widths[i]
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_kv_table(doc, rows, key_width=Inches(1.85), value_width=Inches(4.75)):
    table = doc.add_table(rows=0, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    for idx, (key, value) in enumerate(rows):
        row = table.add_row()
        cant_split(row)
        set_cell_text(row.cells[0], key, bold=True, color=BLUE, size=9.5)
        set_cell_text(row.cells[1], value, size=9.5)
        row.cells[0].width = key_width
        row.cells[1].width = value_width
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_para(doc, text="", bold_lead=None, size=11, color=TEXT, italic=False, align=None, keep=False):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.keep_together = keep
    if align is not None:
        p.alignment = align
    if bold_lead and text.startswith(bold_lead):
        r1 = p.add_run(bold_lead)
        set_run_font(r1, size=size, bold=True, color=color)
        r2 = p.add_run(text[len(bold_lead):])
        set_run_font(r2, size=size, color=color, italic=italic)
    else:
        r = p.add_run(text)
        set_run_font(r, size=size, color=color, italic=italic)
    return p


def add_bullets(doc, items, level=0):
    for item in items:
        p = doc.add_paragraph(style="List Bullet" if level == 0 else "List Bullet 2")
        p.paragraph_format.left_indent = Inches(0.26 + level * 0.22)
        p.paragraph_format.first_line_indent = Inches(-0.16)
        p.paragraph_format.space_after = Pt(3)
        p.paragraph_format.line_spacing = 1.45
        r = p.add_run(item)
        set_run_font(r, size=10.5)


def add_status_line(doc, status, note=None):
    text = f"สถานะ: {status}"
    if note:
        text += f" — {note}"
    p = add_para(doc, text, size=9.5, color=TEXT, italic=False)
    p.paragraph_format.keep_with_next = True
    return p


def add_heading(doc, text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.space_before = Pt(10 if level == 1 else 7)
    p.paragraph_format.space_after = Pt(3)
    r = p.add_run(text)
    set_run_font(r, size=13 if level == 1 else 11, bold=True, color=TEXT)
    return p


def add_section_break(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(0)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("หน้า ")
    set_run_font(run, size=9, color=MUTED)
    fld = OxmlElement("w:fldSimple")
    fld.set(qn("w:instr"), "PAGE")
    paragraph._p.append(fld)


def remove_paragraph_border(paragraph):
    p_pr = paragraph._p.get_or_add_pPr()
    border = p_pr.find(qn("w:pBdr"))
    if border is not None:
        p_pr.remove(border)


def add_checklist(doc, items):
    for checked, text in items:
        mark = "☒" if checked else "☐"
        add_para(doc, f"{mark} {text}", size=10.3)


def setup_document():
    doc = Document()
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.55)
    section.bottom_margin = Inches(0.55)
    section.left_margin = Inches(0.62)
    section.right_margin = Inches(0.62)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = FONT
    normal._element.rPr.rFonts.set(qn("w:ascii"), FONT)
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), FONT)
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
    normal.font.size = Pt(11)
    normal.paragraph_format.line_spacing = 1.5
    normal.paragraph_format.space_after = Pt(6)

    for name in ("Title", "Heading 1", "Heading 2", "Heading 3"):
        s = styles[name]
        s.font.name = FONT
        s._element.rPr.rFonts.set(qn("w:ascii"), FONT)
        s._element.rPr.rFonts.set(qn("w:hAnsi"), FONT)
        s._element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
        s.font.color.rgb = RGBColor.from_string(TEXT)
        p_pr = s.element.get_or_add_pPr()
        border = p_pr.find(qn("w:pBdr"))
        if border is not None:
            p_pr.remove(border)

    return doc


def build():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    doc = setup_document()

    # Cover
    p = doc.add_paragraph(style="Title")
    remove_paragraph_border(p)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(5)
    r = p.add_run("ใบงานปฏิบัติงาน")
    set_run_font(r, size=16, bold=True, color=TEXT)
    p2 = doc.add_paragraph()
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p2.paragraph_format.space_after = Pt(6)
    r = p2.add_run("การวิเคราะห์ ออกแบบ และพัฒนาไฮบริดแอปพลิเคชัน")
    set_run_font(r, size=12, bold=True, color=TEXT)
    add_para(doc, "รายวิชา 31901-2013 การพัฒนาไฮบริดแอปพลิเคชัน", size=11, align=WD_ALIGN_PARAGRAPH.CENTER)
    add_para(doc, "ระดับประกาศนียบัตรวิชาชีพชั้นสูง (ปวส.) | ระบบทวิภาคี", size=10.5, color=TEXT, align=WD_ALIGN_PARAGRAPH.CENTER)

    add_kv_table(doc, [
        ("ชื่อผู้เรียน", "นายทัพพ์จิรัฐ กาญจนเกตุ"),
        ("ห้อง / เลขที่", "สท.5/1 / 010"),
        ("สาขาวิชา", "เทคโนโลยีสารสนเทศ"),
        ("สถานประกอบการ", "สยามโตโยต้าอุตสาหกรรม"),
        ("ชื่อโครงการ", "Stay Book — สมุดจดบันทึกผู้เข้าพักรีสอร์ท"),
        ("ผู้ควบคุมการฝึกอาชีพ", "........................................................................................"),
        ("ครูผู้สอน", "Sajee Prommas"),
        ("ระยะเวลาดำเนินงาน", "28 ตุลาคม 2569 – 18 ธันวาคม 2569"),
        ("วันนำเสนอ", "18 ธันวาคม 2569"),
    ])
    add_para(doc, "ขอบเขตเอกสาร", bold_lead="ขอบเขตเอกสาร", size=10.5)
    add_para(doc, "เอกสารฉบับนี้บันทึกผลการวิเคราะห์ ออกแบบ พัฒนา ทดสอบ และเตรียมส่งมอบเว็บแอป Stay Book โดยอ้างอิงโค้ด เอกสารระบบ และผลทดสอบที่มีอยู่จริงในโครงการ ณ วันที่ 28 ตุลาคม 2569 หัวข้อที่ต้องรอการรับรองหรือข้อเสนอแนะจากบุคคลภายนอกระบุสถานะไว้ชัดเจนเพื่อให้ผู้เรียนเติมภายหลัง", size=10.5)
    add_para(doc, "คำอธิบายสถานะ: ☒ ทำแล้ว  |  ☑ มีอยู่แล้ว  |  ☐ ยังไม่ได้ทำ/รอหลักฐาน  |  ไม่เกี่ยวข้อง = มีเหตุผลประกอบ", size=9.5, color=TEXT)

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 1 วิเคราะห์โจทย์และวางแผนการพัฒนา", 1)
    add_heading(doc, "1.1 ที่มาและลักษณะของโครงการ", 2)
    add_kv_table(doc, [
        ("ชื่อโครงการ", "เว็บแอป Stay Book — สมุดจดบันทึกผู้เข้าพักรีสอร์ท"),
        ("ลักษณะโครงการ", "☒ พัฒนาต่อยอดจากแอปพลิเคชันภาคเรียนที่ 1/2569 โดยเปลี่ยนแนวทางเป็นเว็บแอปที่เข้าถึงได้ผ่านเบราว์เซอร์"),
        ("ที่มาและปัญหา", "การจดรายชื่อลูกค้าและวันเข้าพักด้วยสมุดและปฏิทินทำให้ค้นหาข้อมูลย้อนหลังยาก เสี่ยงจองห้องทับซ้อน และสรุปรายได้หรือสถานะห้องได้ช้า ระบบจึงถูกพัฒนาเพื่อรวมข้อมูลไว้ในที่เดียวและลดความผิดพลาดจากการจดด้วยมือ"),
        ("กลุ่มเป้าหมาย", "ผู้ดูแลรีสอร์ท พนักงานหน้าฟรอนต์ แม่บ้าน และผู้จัดการ ใช้ระหว่างรับจอง เช็กอิน เช็กเอาต์ ตรวจห้อง ค้นหาประวัติลูกค้า และดูรายงาน"),
        ("วัตถุประสงค์", "1) บันทึกและค้นหารายการเข้าพักได้ง่าย 2) ป้องกันการจองห้องทับซ้อน 3) เก็บประวัติลูกค้า 4) แสดงรายได้และอัตราเข้าพักรายช่วงเวลา 5) รองรับการใช้งานจริงบนมือถือ แท็บเล็ต และคอมพิวเตอร์"),
    ])

    add_heading(doc, "1.2 วิเคราะห์ระบบเดิมและสิ่งที่ต้องพัฒนา", 2)
    add_table(doc, ["รายการ", "รายละเอียด"], [
        ("ความสามารถเดิม/สภาพก่อนพัฒนา", "แอปเดิมเป็นแอปพลิเคชันที่ต้องติดตั้งและมีข้อจำกัดด้านการต่อยอด ผู้ดูแลยังอาศัยสมุดและปฏิทินในการติดตามข้อมูลบางส่วน"),
        ("ปัญหา/ข้อจำกัด", "ต้องดาวน์โหลดแอป การอัปเดตหลายอุปกรณ์ทำได้ยาก โครงสร้างเดิมต่อยอดฟังก์ชันและฐานข้อมูลจริงค่อนข้างซับซ้อน"),
        ("สิ่งที่พัฒนาเพิ่มเติม", "เว็บแอปแบบตอบสนองทุกหน้าจอ ฐานข้อมูล SQLite ที่ย้ายไป PostgreSQL/Supabase ได้ ระบบสิทธิ์ผู้ใช้ งานจอง–เช็กอิน–เช็กเอาต์ ประวัติลูกค้า รายงาน CSV ไฟล์แนบ และบันทึกการเปลี่ยนแปลง"),
        ("ประโยชน์ที่คาดว่าจะได้รับ", "เปิดใช้งานผ่านเว็บได้ทันที ลดรายการจองซ้ำ ค้นหาข้อมูลย้อนหลังและตรวจสอบสถานะห้องได้เร็วขึ้น พร้อมข้อมูลสำหรับวิเคราะห์รายได้"),
        ("ผู้ได้รับประโยชน์", "ผู้ดูแลรีสอร์ท พนักงานหน้าฟรอนต์ แม่บ้าน ผู้จัดการ และเจ้าของกิจการ"),
    ], [Inches(2.0), Inches(4.6)])

    add_heading(doc, "1.3 ขอบเขตของแอปพลิเคชัน", 2)
    add_table(doc, ["ลำดับ", "ฟังก์ชัน", "ความสำคัญ", "ผลลัพธ์ที่คาดหวัง"], [
        ("1", "จัดการห้องและรายการจอง", "สูง", "สร้าง แก้ไข ค้นหา และป้องกันวันเข้าพักทับซ้อน"),
        ("2", "เช็กอิน เช็กเอาต์ และตรวจห้อง", "สูง", "ควบคุมสถานะการเข้าพักและบันทึกผลตรวจห้องอย่างเป็นขั้นตอน"),
        ("3", "จัดการข้อมูลและประวัติลูกค้า", "สูง", "ค้นหาลูกค้าเดิม ลดข้อมูลซ้ำ และดูสถิติการเข้าพัก"),
        ("4", "รายงาน รายได้ และส่งออก CSV", "ปานกลาง", "สรุปยอดตามช่วงเวลาและนำข้อมูลไปใช้ต่อได้"),
        ("5", "สิทธิ์ผู้ใช้ ไฟล์แนบ และบันทึกตรวจสอบ", "ปานกลาง", "จำกัดการทำงานตามบทบาทและตรวจสอบย้อนหลังได้"),
    ], [Inches(.45), Inches(2.2), Inches(.85), Inches(3.1)])
    add_para(doc, "ข้อกำหนด/ข้อจำกัด: ต้องใช้เบราว์เซอร์สมัยใหม่และเครือข่ายที่เชื่อมถึงเซิร์ฟเวอร์ การใช้งานจริงต้องตั้งรหัสผ่านและ APP_KEY ใหม่ เปิด HTTPS สำรองฐานข้อมูลและไฟล์แนบ และกำหนดสิทธิ์ตามบทบาท ระยะเวลาดำเนินงาน 28 ต.ค.–18 ธ.ค. 2569", size=10.3)

    add_heading(doc, "1.4 เครื่องมือและเทคโนโลยี", 2)
    add_table(doc, ["รายการ", "เครื่องมือ/เทคโนโลยี", "วัตถุประสงค์"], [
        ("Framework/เครื่องมือพัฒนา", "PHP 8.3, custom PSR-4 micro-framework, Docker Compose, Nginx", "รันเว็บแอป แยกบริการ และจัดการเส้นทาง/คำขอ"),
        ("ภาษาโปรแกรม", "PHP, JavaScript ES2020, HTML, CSS, SQL", "พัฒนา backend, frontend และฐานข้อมูล"),
        ("ฐานข้อมูล", "SQLite + PostgreSQL 15/Supabase-compatible migrations", "เก็บข้อมูลจริงและรองรับการย้ายไปฐานข้อมูลบนเซิร์ฟเวอร์"),
        ("เครื่องมือ UI/UX", "Tailwind CSS 3.4, Noto Sans Thai, responsive utilities", "สร้าง UI ภาษาไทยที่ใช้งานได้บนหลายขนาดหน้าจอ"),
        ("API/บริการ", "REST API ภายใน `/api/v1`, PDO, optional Supabase PostgreSQL", "รับส่งข้อมูลระหว่างหน้าจอกับเซิร์ฟเวอร์"),
        ("เครื่องมือทดสอบ", "PHPUnit 11, PHPStan, PHP-CS-Fixer, Node syntax check, browser QA", "ตรวจฟังก์ชัน คุณภาพโค้ด และการตอบสนองหน้าจอ"),
        ("เครื่องมืออื่น", "Git, Composer, npm, esbuild", "ควบคุมเวอร์ชัน จัดการแพ็กเกจ และสร้างไฟล์ production"),
    ], [Inches(1.45), Inches(2.35), Inches(2.8)])

    add_heading(doc, "1.5 แผนการดำเนินงาน", 2)
    add_table(doc, ["ลำดับ", "งาน", "ผลงานที่คาดว่าจะได้รับ", "ช่วงเวลา"], [
        ("1", "วิเคราะห์โจทย์และความต้องการ", "ขอบเขต ผู้ใช้ และปัญหาหลัก", "28–31 ต.ค. 2569"),
        ("2", "สำรวจระบบเดิมและเตรียมเครื่องมือ", "โครงสร้างโครงการและ Docker ที่รันได้", "1–5 พ.ย. 2569"),
        ("3", "ออกแบบระบบและ UI/UX", "สถาปัตยกรรม โครงสร้างข้อมูล และหน้าจอ", "6–12 พ.ย. 2569"),
        ("4", "พัฒนาฟังก์ชันและข้อมูล", "ระบบห้อง จอง ลูกค้า เช็กอิน/เอาต์", "13–27 พ.ย. 2569"),
        ("5", "เชื่อมต่อบริการและทรัพยากร", "REST API ไฟล์แนบ และฐานข้อมูล", "28 พ.ย.–3 ธ.ค. 2569"),
        ("6", "ทดสอบและปรับปรุง", "ผลทดสอบและรายการแก้ไข", "4–10 ธ.ค. 2569"),
        ("7", "คู่มือและเตรียมส่งมอบ", "คู่มือ เอกสาร และชุด Docker", "11–15 ธ.ค. 2569"),
        ("8", "สรุปและนำเสนอ", "ใบงานฉบับสมบูรณ์และสาธิต", "16–18 ธ.ค. 2569"),
    ], [Inches(.45), Inches(2.05), Inches(2.75), Inches(1.35)], font_size=8.8)

    add_heading(doc, "1.6 การปรึกษาครูพี่เลี้ยงหรือผู้ควบคุมการฝึกอาชีพ", 2)
    add_kv_table(doc, [
        ("ประเด็นที่นำไปปรึกษา", "รอผู้เรียนบันทึกประเด็นที่ปรึกษาจริง"),
        ("ข้อเสนอแนะที่ได้รับ", "ยังไม่ได้รับข้อเสนอแนะ/รอบันทึกจากผู้ให้คำแนะนำ"),
        ("แนวทางที่นำไปใช้", "รอกรอกหลังได้รับข้อเสนอแนะ"),
        ("ชื่อ/วันที่", "ชื่อผู้ให้คำแนะนำ ........................................  วันที่ ........................................"),
        ("หลักฐาน", "☐ บันทึกการปรึกษา  ☐ ข้อเสนอแนะเป็นลายลักษณ์อักษร  ☐ ภาพ/เอกสาร"),
    ])
    add_status_line(doc, "☐ ยังไม่ได้ทำ", "ต้องบันทึกจากเหตุการณ์จริง ไม่ควรสร้างข้อมูลแทนผู้ให้คำแนะนำ")

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 2 สำรวจระบบเดิมและเตรียมเครื่องมือพัฒนา", 1)
    add_table(doc, ["หัวข้อปฏิบัติงาน", "เทคนิค/วิธีการและผลการปฏิบัติงาน", "สถานะ"], [
        ("2.1 ตรวจสอบโครงสร้างโครงการ", "สำรวจ app, routes, resources, database, tests, docker และ docs; แยก Controller–Service–Repository ชัดเจน", "☒ ทำแล้ว"),
        ("2.2 เลือก Framework/เครื่องมือ", "ใช้ PHP 8.3, Nginx, Docker Compose, Tailwind, JavaScript และ PDO ตามโครงสร้างเดิม", "☑ มีอยู่แล้ว"),
        ("2.3 ติดตั้งสภาพแวดล้อม", "สร้าง image PHP/Node/Nginx และตั้งค่า .env, volumes, health checks", "☒ ทำแล้ว"),
        ("2.4 ตรวจสอบการรันแอป", "docker compose build/up และตรวจ health ของ PHP/Nginx; เปิดผ่าน localhost:8080", "☒ ทำแล้ว"),
        ("2.5 จัดระเบียบ/ควบคุมเวอร์ชัน", "แยก source, config, migrations, tests, docs; ใช้ Git และไม่เก็บ secrets", "☑ มีอยู่แล้ว"),
    ], [Inches(1.65), Inches(4.1), Inches(.85)], font_size=9)
    add_kv_table(doc, [
        ("Framework", "PHP custom PSR-4 micro-framework + Tailwind CSS"),
        ("ภาษา", "PHP 8.3, JavaScript ES2020, HTML, CSS, SQL"),
        ("IDE", "Visual Studio Code / Codex (ใช้ตรวจสอบและแก้ไขโครงการ)"),
        ("ระบบทดสอบ", "Windows + Docker Desktop; Chrome/Edge และ viewport 360, 375, 768, 1280 พิกเซล"),
        ("ปัญหา/วิธีแก้", "กรณีเปิด localhost:8080 ไม่ได้ ให้ตรวจ Docker Desktop, `docker compose ps`, logs และพอร์ต APP_PORT; หาก image เก่าให้ build ใหม่ โดยไม่ลบ named volumes"),
        ("หลักฐาน", "README.md, docker-compose.yml, docker/, app/, resources/, tests/, docs/USAGE_TH.md"),
    ])

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 3 วิเคราะห์ความต้องการและออกแบบระบบ", 1)
    add_heading(doc, "3.1 วิเคราะห์ความต้องการของผู้ใช้", 2)
    add_table(doc, ["ลำดับ", "ความต้องการ", "วิธีที่ระบบตอบสนอง", "ผลลัพธ์"], [
        ("1", "เห็นงานประจำวันและห้องว่างเร็ว", "หน้าวันนี้และผังห้องแสดงผู้เข้า/ออก ห้องว่าง/มีผู้พัก", "ลดเวลาค้นหาและตกหล่น"),
        ("2", "รับจองโดยไม่ชนกัน", "ตรวจช่วงวัน ความจุ จำนวนผู้เข้าพัก และเงื่อนไขสัตว์เลี้ยง", "ลดการจองผิดพลาด"),
        ("3", "ติดตามลูกค้าและประวัติ", "รวมข้อมูลด้วยเบอร์โทร ค้นหา แก้ไข และแสดงสถิติย้อนหลัง", "บริการลูกค้าเดิมได้ต่อเนื่อง"),
        ("4", "ดูรายได้/ผลดำเนินงาน", "รายงานตามช่วงเวลา KPI กราฟ CSV และพิมพ์", "ใช้ข้อมูลช่วยตัดสินใจ"),
    ], [Inches(.45), Inches(1.7), Inches(2.75), Inches(1.7)], font_size=9)

    add_heading(doc, "3.2 โครงสร้างและลำดับการทำงาน", 2)
    add_table(doc, ["รายการออกแบบ", "รายละเอียด/เครื่องมือ", "สถานะ"], [
        ("Flowchart/ลำดับงาน", "Browser → Nginx → Router → Session/CSRF → Controller → Service → Repository → PDO", "☒ ทำแล้ว"),
        ("UML/แบบจำลอง", "ใช้การแบ่งชั้นงานและแบบจำลองข้อมูลแทน Class Diagram เต็มรูปแบบ เพราะโครงการมีโค้ดจริงและเอกสารสถาปัตยกรรมตรวจสอบได้", "☒ ทำแล้ว"),
        ("โครงสร้างหน้าจอ/การนำทาง", "เข้าสู่ระบบ → วันนี้ → ผังห้อง → ตารางเข้าพัก → ภาพรวม → ห้องพัก → ลูกค้า; รองรับ deep link/hash", "☒ ทำแล้ว"),
        ("ฐานข้อมูล", "users, rooms, guests, stays, checkout_inspections, feedbacks, attachments, audit_logs", "☒ ทำแล้ว"),
        ("API/บริการ", "REST API `/api/v1`; JSON envelope; session/CSRF/role policy; PostgreSQL/Supabase ผ่าน backend", "☒ ทำแล้ว"),
    ], [Inches(1.55), Inches(4.15), Inches(.9)], font_size=9)
    add_para(doc, "เหตุผลในการเลือกแบบจำลอง: โครงการเน้นลำดับงานจริงและความสัมพันธ์ข้อมูล จึงใช้แผนภาพการไหล สถาปัตยกรรมแบบแบ่งชั้น โครงสร้างนำทาง และตารางข้อมูล ซึ่งสอดคล้องกับความเสี่ยงสำคัญของระบบ ได้แก่ การจองทับซ้อน วงจรสถานะเข้าพัก และสิทธิ์ผู้ใช้", size=10.3)

    add_heading(doc, "โครงสร้างข้อมูลหลัก", 2)
    add_table(doc, ["ตาราง", "ข้อมูลสำคัญ", "ความสัมพันธ์/กฎ"], [
        ("users", "ชื่อ อีเมล รหัสผ่าน บทบาท", "admin/front_desk/housekeeping; soft delete"),
        ("rooms", "ชื่อ โซน ประเภท ราคา ความจุ สัตว์เลี้ยง", "ชื่อห้องไม่ซ้ำ; สถานะว่าง/มีผู้พัก"),
        ("guests", "ชื่อ เบอร์โทร ประเภท โน้ต ความชอบ", "normalized_phone ไม่ซ้ำ"),
        ("stays", "ห้อง ลูกค้า วันเข้า–ออก จำนวนคน ราคา สถานะ", "อ้างอิง rooms/guests; วันออกต้องมากกว่าวันเข้า"),
        ("checkout_inspections", "กุญแจ ความสะอาด อุปกรณ์ ความเสียหาย มินิบาร์", "หนึ่งรายการต่อหนึ่ง stay"),
        ("feedbacks", "คะแนน 4 ด้าน กลับมาใช้บริการ ความคิดเห็น", "คะแนน 1–5; หลังเช็กเอาต์"),
        ("attachments", "ชื่อไฟล์ ชนิด ขนาด ผู้แนบ", "ไฟล์เก็บนอก public และดาวน์โหลดหลังยืนยันตัวตน"),
        ("audit_logs", "ผู้ใช้ การกระทำ entity ก่อน/หลัง IP เวลา", "ใช้ตรวจสอบการเปลี่ยนแปลงย้อนหลัง"),
    ], [Inches(1.35), Inches(2.7), Inches(2.55)], font_size=8.8)

    add_heading(doc, "3.3 ออกแบบส่วนติดต่อผู้ใช้ (UI/UX)", 2)
    add_kv_table(doc, [
        ("จำนวนหน้าจอหลัก", "6 ส่วนหลัก: วันนี้, ผังห้อง, ตารางเข้าพัก/ปฏิทิน, ภาพรวม, ห้องพัก, ลูกค้า รวมหน้าเข้าสู่ระบบและ dialog งานย่อย"),
        ("แนวทาง", "โทนสีน้ำเงิน–ขาวตามระบบเดิม ระยะห่าง 4/8 px รัศมี 12–16 px ตัวอักษรไทยอ่านง่าย ปุ่มแตะไม่น้อยกว่า 44 px ฟอร์มคอลัมน์เดียวบนมือถือ เมนูมือถือแบบแถบล่าง ตารางอยู่ในกรอบเลื่อนหรือแปลงเป็นการ์ด และมี focus ring"),
        ("Responsive", "ตรวจที่ 360, 375, 768 และ 1280 px; ป้องกันการเลื่อนแนวนอนทั้งหน้า และกำหนด input 16 px บนมือถือ"),
        ("เครื่องมือ", "Tailwind CSS, CSS utilities, vanilla JavaScript, browser responsive mode"),
        ("หลักฐาน", "resources/views/pages/dashboard/index.php, resources/js/app.js, resources/css/app.css, docs/UX_PROPOSAL.md"),
    ])

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 4 พัฒนาแอปพลิเคชันและส่วนติดต่อผู้ใช้", 1)
    add_heading(doc, "4.1 ฟังก์ชันสำคัญ", 2)
    add_table(doc, ["ฟังก์ชัน", "วิธีการ/เครื่องมือ", "ผลการทำงานและหลักฐาน"], [
        ("4.1.1 จัดการ Booking", "StayRequest ตรวจข้อมูล, ResortService ตรวจชนกัน/ความจุ, Repository ทำ transaction", "สร้าง แก้ไข ลบ ค้นหา และป้องกันวันทับซ้อน; tests/Feature/ResortServiceTest.php"),
        ("4.1.2 คำนวณราคา", "PriceCalculator ใช้จำนวนคืน คนเพิ่ม เตียงเสริม สัตว์เลี้ยง ส่วนลด และมัดจำ", "preview ฝั่งหน้าเว็บตรงกับการคำนวณฝั่ง PHP; tests/Unit/PriceCalculatorTest.php"),
        ("4.1.3 เช็กอิน/เอาต์", "state transition ฝั่ง server; ตรวจบัตรก่อนเช็กอินและ checklist ก่อนเช็กเอาต์", "ไม่ให้ client เปลี่ยนสถานะเอง; บันทึกผู้ตรวจและผลตรวจ"),
        ("4.1.4 ลูกค้า/ประวัติ", "รวมข้อมูลด้วย normalized phone และ snapshot analytics", "ค้นหา ดูประวัติ ยอดสะสม ลูกค้าประจำ และความต้องการ"),
        ("4.1.5 รายงาน/ไฟล์", "REST API, CSV escaping, upload MIME/size validation, private storage", "ดู KPI ส่งออก CSV และแนบ/ดาวน์โหลดไฟล์ตามสิทธิ์"),
    ], [Inches(1.55), Inches(2.65), Inches(2.4)], font_size=8.7)

    add_heading(doc, "4.2 การพัฒนาส่วนติดต่อผู้ใช้", 2)
    add_table(doc, ["หัวข้อ", "เทคนิค/วิธีการจริง", "สถานะ"], [
        ("สร้าง Components", "server-rendered PHP views + reusable CSS classes + JS render functions", "☒ ทำแล้ว"),
        ("การนำทาง", "เมนูเดสก์ท็อป/แถบล่างมือถือและ URL hash สำหรับย้อนกลับ/deep link", "☒ ทำแล้ว"),
        ("รับและตรวจข้อมูล", "HTML validation + inline errors + validation ฝั่ง server", "☒ ทำแล้ว"),
        ("แสดงผล/แจ้งเตือน", "loading, empty, success, retry และข้อความผิดพลาด พร้อมปิดปุ่มระหว่างส่ง", "☒ ทำแล้ว"),
        ("รองรับหน้าจอ", "mobile-first, fluid spacing/type, dialog เป็น sheet/full-screen และตารางเลื่อนในกรอบ", "☒ ทำแล้ว"),
    ], [Inches(1.65), Inches(4.05), Inches(.9)], font_size=9)

    add_heading(doc, "4.3 การจัดการฐานข้อมูลและข้อมูล", 2)
    add_table(doc, ["หัวข้อ", "เทคนิค/วิธีการจริง", "สถานะ"], [
        ("ออกแบบโครงสร้าง", "SQL migrations แยก SQLite/PostgreSQL แต่ใช้ชื่อไฟล์และคอลัมน์เทียบเท่ากัน", "☒ ทำแล้ว"),
        ("สร้าง/เชื่อมต่อ", "PDO + dialect abstraction; SQLite WAL/busy timeout; PostgreSQL SSL/prepared settings", "☒ ทำแล้ว"),
        ("CRUD", "Repository เป็นชั้นเดียวที่เข้าถึง SQL; service ตรวจสิทธิ์และกฎธุรกิจ", "☒ ทำแล้ว"),
        ("จัดการข้อผิดพลาด", "validation 422, missing 404, conflict 409 และ generic 500 พร้อม log", "☒ ทำแล้ว"),
        ("ความถูกต้อง/คงอยู่", "foreign key, unique/check constraints, transaction, audit log, backup command", "☒ ทำแล้ว"),
    ], [Inches(1.65), Inches(4.05), Inches(.9)], font_size=9)
    add_kv_table(doc, [
        ("ประเภทฐานข้อมูล", "SQLite ภายใน Docker volume เป็นค่าเริ่มต้น; รองรับ PostgreSQL 15/Supabase บนเซิร์ฟเวอร์"),
        ("ลักษณะการจัดเก็บ", "☒ ฐานข้อมูลบนเซิร์ฟเวอร์/คอนเทนเนอร์  ☒ ไฟล์แนบใน private volume  ☒ REST API ภายใน"),
        ("ตัวอย่างฟังก์ชัน", "สร้าง Booking: รับข้อมูล → ตรวจ CSRF/สิทธิ์ → validate วันและจำนวนคน → ตรวจห้องทับซ้อน → คำนวณราคา → บันทึก guest/stay ใน transaction → เขียน audit log → โหลด snapshot ใหม่"),
        ("ผลจริง", "ระบบตอบกลับข้อมูลที่บันทึกหรือแจ้งข้อผิดพลาดเป็นสถานะ 409/422 โดยไม่สร้างรายการผิดเงื่อนไข"),
        ("หลักฐาน", "app/Services/ResortService.php, app/Repositories/Database/ResortRepository.php, database/migrations/, tests/"),
    ])

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 5 ทรัพยากรอุปกรณ์และซอฟต์แวร์ภายนอก", 1)
    add_heading(doc, "5.1 การเข้าถึงทรัพยากรของอุปกรณ์", 2)
    add_kv_table(doc, [
        ("ทรัพยากร", "ตัวเลือกไฟล์ของเบราว์เซอร์สำหรับแนบ JPEG, PNG, WebP และ PDF"),
        ("วัตถุประสงค์", "แนบหลักฐานหรือเอกสารกับรายการเข้าพัก"),
        ("วิธีเข้าถึง", "HTML file input → multipart upload → UploadService ตรวจ MIME/ขนาด → เก็บนอก public"),
        ("การอนุญาต", "ผู้ใช้เลือกไฟล์ด้วยตนเอง ไม่ร้องขอสิทธิ์กล้อง/GPS; ฝั่งระบบต้องเข้าสู่ระบบและผ่าน role policy"),
        ("ผลทดสอบ", "ไฟล์ที่อนุญาตไม่เกิน 5 MB บันทึกและดาวน์โหลดผ่านเส้นทาง protected ได้"),
    ])
    add_status_line(doc, "☒ ทำแล้ว", "ไม่ใช้กล้อง GPS หรือเซ็นเซอร์เพราะไม่จำเป็นต่อขอบเขตเว็บแอป")

    add_heading(doc, "5.2 การเชื่อมต่อ API หรือซอฟต์แวร์ภายนอก", 2)
    add_kv_table(doc, [
        ("บริการ", "REST API ภายใน `/api/v1`; ฐานข้อมูล PostgreSQL/Supabase เป็นตัวเลือกสำหรับ production"),
        ("วัตถุประสงค์", "แลกเปลี่ยนข้อมูลห้อง รายการเข้าพัก ลูกค้า รายงาน และไฟล์ระหว่าง UI กับ backend"),
        ("ข้อมูลรับ–ส่ง", "JSON สำหรับข้อมูลหลัก, multipart สำหรับไฟล์ และ CSV สำหรับรายงาน"),
        ("วิธีเชื่อมต่อ", "fetch wrapper แนบ CSRF token; backend ยืนยัน session/role แล้วเรียก service/repository"),
        ("จัดการข้อผิดพลาด", "แสดง inline error/retry; แยก 404/409/422/500; transaction rollback และลบไฟล์ชดเชยเมื่อ DB บันทึกล้มเหลว"),
        ("ผลทดสอบ", "API workflow และ migration parity ผ่าน automated tests; ไม่ส่ง Supabase credential ไปเบราว์เซอร์"),
    ])
    add_status_line(doc, "☒ ทำแล้ว", "การเชื่อม Supabase cloud จริงขึ้นกับค่ารับรองของสภาพแวดล้อม production")

    add_heading(doc, "5.3 ฟีเจอร์ข้ามแพลตฟอร์ม", 2)
    add_para(doc, "ระบบเป็นเว็บแอป จึงใช้ codebase เดียวบนมือถือ แท็บเล็ต และคอมพิวเตอร์ ฟังก์ชันหลักต้องทำงานผ่านเบราว์เซอร์สมัยใหม่ โดยเน้น tap target, ฟอร์ม, dialog, ตาราง/ปฏิทิน และ safe-area บนอุปกรณ์พกพา", size=10.3)
    add_table(doc, ["แพลตฟอร์ม/อุปกรณ์", "ผลการทดสอบ", "ปัญหา/แนวทางแก้"], [
        ("มือถือ 360/375 px", "เมนูแถบล่าง ฟอร์มคอลัมน์เดียว dialog แบบ sheet และไม่มี scroll แนวนอนทั้งหน้า", "ตาราง/ปฏิทินเลื่อนภายใน container; input 16 px ป้องกัน iOS zoom"),
        ("แท็บเล็ต 768 px", "layout ปรับคอลัมน์และ dialog ใช้งานได้", "คงพื้นที่แตะและระยะห่างให้เหมาะสม"),
        ("เดสก์ท็อป 1280 px", "แสดง sidebar/ตารางเต็มและการ์ดหลายคอลัมน์", "จำกัดความกว้างเนื้อหาเพื่ออ่านง่าย"),
    ], [Inches(1.45), Inches(2.55), Inches(2.6)], font_size=9)
    add_status_line(doc, "☒ ทำแล้ว")

    add_heading(doc, "5.4 สรุปผลการเชื่อมต่อ", 2)
    add_kv_table(doc, [
        ("ปัญหาสำคัญ", "สถานะ/การโหลด API เดิมไม่ครอบคลุม retry, ไฟล์แนบอัปโหลดแล้วค้นคืนยาก และบางข้อผิดพลาดถูกตอบเป็น 500"),
        ("วิธีแก้", "เพิ่ม shared loading/error state, ข้อมูลไฟล์แนบใน snapshot, protected download link และแยกรหัสผิดพลาด 404/409/422"),
        ("ผลหลังแก้", "ผู้ใช้เห็นสถานะชัดเจน ลองใหม่ได้ และเข้าถึงไฟล์แนบจากรายการได้ตามสิทธิ์"),
        ("หลักฐาน", "docs/AUDIT_REPORT.md, resources/js/app.js, ResortController.php, UploadService.php"),
    ])

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 6 ทดสอบและประเมินคุณภาพแอปพลิเคชัน", 1)
    add_heading(doc, "6.1 การทดสอบโปรแกรมและฟังก์ชัน", 2)
    add_table(doc, ["ลำดับ", "กรณีทดสอบ", "ผลที่คาดหวัง", "ผลที่เกิดขึ้นจริง", "ผล"], [
        ("1", "เข้าสู่ระบบและเส้นทางที่ป้องกัน", "บัญชีถูกต้องเข้าได้; ผู้ไม่ผ่านยืนยันเข้าไม่ได้", "session ถูกสร้างใหม่ เส้นทาง/ไฟล์ต้องยืนยันตัวตน", "☒ ผ่าน"),
        ("2", "สร้าง Booking ทับช่วงวันเดิม", "ระบบปฏิเสธและไม่บันทึกซ้ำ", "ตอบ conflict และไม่สร้าง stay", "☒ ผ่าน"),
        ("3", "เช็กอินโดยไม่ยืนยันบัตร", "ไม่อนุญาตให้เปลี่ยนสถานะ", "service ปฏิเสธจนกว่าจะยืนยันบัตร", "☒ ผ่าน"),
        ("4", "เช็กเอาต์พร้อมตรวจห้อง", "ต้องครบ checklist; ห้องกลับว่าง", "บันทึก inspection และเปลี่ยนสถานะตามขั้นตอน", "☒ ผ่าน"),
        ("5", "รายงาน/CSV และ responsive UI", "ช่วงวันที่ถูกต้อง CSV ปลอดภัย UI ใช้งานได้หลายหน้าจอ", "ทดสอบ validation/CSV และ viewport แล้วผ่าน", "☒ ผ่าน"),
    ], [Inches(.38), Inches(1.55), Inches(1.75), Inches(2.35), Inches(.57)], font_size=8.4)

    add_heading(doc, "6.2 การประเมินคุณภาพ", 2)
    add_table(doc, ["หัวข้อ", "วิธีตรวจสอบ/ผล", "สถานะ"], [
        ("ความถูกต้องของฟังก์ชัน", "PHPUnit feature/unit tests และ browser workflow; 13 tests / 24 assertions ผ่าน", "☒ ทำแล้ว"),
        ("ความถูกต้องของข้อมูล", "constraints, overlap logic, money เป็นหน่วยสตางค์, migration parity", "☒ ทำแล้ว"),
        ("ความเร็ว", "assets hash/minify, server-rendered shell, snapshot เหมาะกับขนาดรีสอร์ทปัจจุบัน", "☒ ทำแล้ว"),
        ("ความเสถียร/ข้อผิดพลาด", "health checks, transactions, log, retry state, rollback ไฟล์", "☒ ทำแล้ว"),
        ("UI/UX", "responsive QA, focus ring, loading/empty/error state และ role-aware actions", "☒ ทำแล้ว"),
        ("ความปลอดภัย/สิทธิ์", "session HttpOnly/SameSite, CSRF, prepared statements, role policy, private uploads, audit log", "☒ ทำแล้ว"),
    ], [Inches(1.65), Inches(4.05), Inches(.9)], font_size=8.9)

    add_heading(doc, "6.3 การแก้ไขข้อผิดพลาดและปรับปรุงระบบ", 2)
    add_table(doc, ["ปัญหา", "สาเหตุ", "วิธีแก้", "ผล/หลักฐาน"], [
        ("ปุ่มปิด dialog ไม่ทำงาน", "data-close ค่าว่างถูกตีความเป็น false", "ตรวจการมีอยู่ของ attribute แทนค่าข้างใน", "ปุ่มและ Escape ปิดได้; AUD-002"),
        ("API สร้าง stay สถานะจบได้", "รับ lifecycle status จาก client", "ให้ server ควบคุม transition และเพิ่ม regression test", "ปิดช่องทางข้ามเช็กอิน/ตรวจห้อง; AUD-003"),
        ("CSV ไม่ตามช่วงวันที่/เสี่ยง formula", "URL ไม่ sync และไม่ escape prefix", "ผูก query กับช่วงรายงานและ escape =,+,-,@", "CSV ถูกช่วงและปลอดภัย; AUD-005/015"),
        ("ผู้ใช้ต่างบทบาทเห็นปุ่มเกินสิทธิ์", "UI ไม่อ่าน role", "ซ่อน action ตาม policy และยังบังคับฝั่ง server", "housekeeping เห็นเฉพาะงานที่ทำได้; AUD-008"),
        ("เปิดเว็บไม่ได้จาก image เก่า", "PHP-FPM/log หรือ asset image ไม่ตรงรุ่น", "ตรวจ logs/health และ rebuild image โดยรักษา volumes", "คู่มือแก้ปัญหาอยู่ใน docs/USAGE_TH.md"),
    ], [Inches(1.45), Inches(1.55), Inches(1.9), Inches(1.7)], font_size=8.2)

    add_heading(doc, "6.4 สรุปผลการทดสอบ", 2)
    add_kv_table(doc, [
        ("Automated tests", "ทั้งหมด 13 กรณี / 24 assertions — ผ่าน 13, ไม่ผ่าน 0"),
        ("Quality checks", "PHP syntax 66 files, PHP-CS-Fixer, PHPStan level 6, JavaScript syntax และ production build ผ่าน"),
        ("Browser QA", "งานวันนี้ command search dialog ปิด เมนูมือถือ hash deep link และ responsive baseline ผ่าน"),
        ("ประเด็นคงค้าง", "พิจารณา pagination เมื่อข้อมูลมีจำนวนมาก, อัปเดต caniuse-lite, และแทน native confirm ด้วย custom dialog/undo"),
        ("หลักฐาน", "docs/AUDIT_REPORT.md, tests/, phpunit.xml, package.json"),
    ])

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 7 เตรียมเผยแพร่ จัดทำคู่มือ และส่งมอบผลงาน", 1)
    add_heading(doc, "7.1 การเตรียมแอปพลิเคชันสำหรับใช้งาน", 2)
    add_table(doc, ["หัวข้อ", "วิธีการจริง", "สถานะ"], [
        ("เตรียมรุ่นเผยแพร่", "ใช้ docker-compose.prod.yml, production env, build hashed assets และปิด demo seed", "☒ ทำแล้ว"),
        ("สร้างไฟล์/ช่องทางเผยแพร่", "ส่งมอบ source code + Docker images ที่ build จากโครงการ; ไม่ใช้ APK/App Store", "☒ ทำแล้ว"),
        ("ตรวจสอบติดตั้ง/เปิดใช้", "Docker health checks และเปิดเว็บผ่าน APP_PORT; production ใช้ HTTPS ที่ reverse proxy", "☒ ทำแล้ว"),
        ("เตรียมทรัพยากร", "source, migrations, seed, Docker files, docs, tests, fonts/images และ storage volumes", "☒ ทำแล้ว"),
    ], [Inches(1.65), Inches(4.05), Inches(.9)], font_size=9)
    add_kv_table(doc, [
        ("แพลตฟอร์มเป้าหมาย", "เว็บเบราว์เซอร์บนมือถือ แท็บเล็ต และคอมพิวเตอร์"),
        ("รูปแบบส่งมอบ", "เว็บแอปแบบ Docker Compose พร้อม Source Code ฐานข้อมูล migrations และคู่มือ"),
        ("ช่องทางใช้งาน", "สภาพแวดล้อมท้องถิ่น http://localhost:8080; production ต้องติดตั้งบนเซิร์ฟเวอร์/คลาวด์และกำหนดโดเมน/HTTPS"),
    ])

    add_heading(doc, "7.2 คู่มือการใช้งาน", 2)
    add_table(doc, ["รายการ", "สถานะ", "รายละเอียด/หลักฐาน"], [
        ("อธิบายวัตถุประสงค์", "☒ ทำแล้ว", "README.md และ docs/USAGE_TH.md"),
        ("การติดตั้ง/เข้าใช้งาน", "☒ ทำแล้ว", "Quick start, บัญชีเริ่มต้น และ production checklist"),
        ("ฟังก์ชันสำคัญ", "☒ ทำแล้ว", "จอง เช็กอิน ต่อเวลา เช็กเอาต์ ห้อง ลูกค้า รายงาน ไฟล์"),
        ("ภาพประกอบ", "☐ ยังไม่ได้แนบ", "ควรเพิ่มภาพหน้าจอจากระบบจริงก่อนส่งฉบับสุดท้าย"),
        ("ข้อจำกัด/แก้ปัญหา", "☒ ทำแล้ว", "Docker, พอร์ต, login, assets, database lock และ PostgreSQL"),
    ], [Inches(2.05), Inches(1.05), Inches(3.5)], font_size=9)
    add_para(doc, "ชื่อไฟล์คู่มือ: docs/USAGE_TH.md  |  รูปแบบ: ☒ Markdown/Web documentation  ☐ PDF  ☐ วิดีโอ", size=10.2)

    add_heading(doc, "7.3 การติดตั้งและทดลองใช้งาน", 2)
    add_kv_table(doc, [
        ("ผู้ทดลอง", "การทดสอบภายในโดยผู้พัฒนา; รอการทดลองกับผู้ดูแลรีสอร์ทจริง"),
        ("บริบท", "Windows + Docker Desktop ผ่าน localhost:8080 และ browser responsive mode"),
        ("ผล", "workflow หลักและ responsive baseline ผ่านตามผล audit"),
        ("ข้อเสนอแนะผู้ใช้", "ยังไม่ได้รับข้อเสนอแนะจากผู้ใช้ปลายทาง"),
        ("แนวทางปรับปรุง", "นัดสาธิตกับผู้ดูแลรีสอร์ท บันทึกงานที่ใช้จริง เวลาในการทำงาน และปัญหาที่พบ แล้วปรับ backlog"),
    ])
    add_status_line(doc, "☐ ยังไม่ได้ทำครบ", "ผ่านการทดสอบภายใน แต่ยังต้องทดลองกับผู้ใช้ปลายทาง")

    add_heading(doc, "7.4 รายการส่งมอบ", 2)
    add_checklist(doc, [
        (True, "ไฟล์โครงการ/Source Code"),
        (True, "ช่องทางเข้าใช้งานเว็บแอปด้วย Docker Compose"),
        (True, "คู่มือการใช้งานภาษาไทย"),
        (True, "เอกสารสถาปัตยกรรม API ฐานข้อมูล Deployment และ Supabase"),
        (True, "หลักฐาน automated tests และ audit report"),
        (False, "ภาพหน้าจอหรือวิดีโอสาธิต — รอจัดทำก่อนส่ง"),
        (True, "บันทึกการใช้ AI และ Prompt ในหัวข้อ 8.3"),
    ])
    add_kv_table(doc, [
        ("ตำแหน่งผลงาน", r"D:\Project\Stay-Book"),
        ("โฟลเดอร์หลัก", "Stay-Book"),
        ("ลิงก์ส่งงาน", "รอผู้เรียนกรอกลิงก์ที่ส่งให้ครูผู้สอน"),
    ])

    add_section_break(doc)
    add_heading(doc, "ตอนที่ 8 ตรวจสอบ แก้ไข และสรุปผลการปฏิบัติงาน", 1)
    add_heading(doc, "8.1 ผลการตรวจสอบและข้อเสนอแนะ", 2)
    add_table(doc, ["รายการ", "บันทึกผล"], [
        ("ครูพี่เลี้ยง/ผู้ควบคุม", "ยังไม่ได้รับข้อเสนอแนะ — รอผู้เรียนบันทึกจากการปรึกษาจริง"),
        ("ครูผู้สอน", "ยังไม่ได้รับข้อเสนอแนะ — รอการตรวจงาน"),
        ("ผู้ใช้งาน", "ยังไม่ได้รับข้อเสนอแนะจากผู้ใช้ปลายทาง"),
        ("ปัญหาหลังตรวจสอบ", "พบประเด็นจาก technical audit เช่น lifecycle bypass, dialog, CSV, role visibility และ API error mapping"),
        ("วิธีแก้/แนวทาง", "แก้ตามระดับความรุนแรง เพิ่ม regression tests และทดสอบ workflow/หน้าจอซ้ำ"),
        ("ผลหลังปรับปรุง", "รายการ Critical/High ที่ระบุใน audit ได้รับการแก้ไข; เหลือข้อเสนอด้าน pagination/dependency metadata/custom confirm"),
    ], [Inches(2.0), Inches(4.6)])

    add_heading(doc, "8.2 สรุปผลการพัฒนา", 2)
    add_kv_table(doc, [
        ("1. ผลสำเร็จ", "พัฒนาเว็บแอปจัดการรีสอร์ทที่ครอบคลุมห้อง Booking เช็กอิน/เช็กเอาต์ ลูกค้า รายงาน ไฟล์แนบ บทบาท และ audit log พร้อมคู่มือและ Docker runtime"),
        ("2. สิ่งที่ต่อยอด", "เปลี่ยนจากแอปที่ต้องติดตั้งเป็นเว็บแอป responsive เพิ่มฐานข้อมูลจริงและชั้น Repository/Service รองรับ SQLite/PostgreSQL/Supabase เพิ่มความปลอดภัยและ automated tests"),
        ("3. ปัญหา/วิธีแก้", "แก้ปัญหา lifecycle จาก client, ข้อผิดพลาด API, role leakage, CSV, upload consistency และ responsive UI ด้วย validation ฝั่ง server, policy, transactions, regression tests และ browser QA"),
        ("4. สิ่งที่เรียนรู้", "การออกแบบ state transition, ข้อมูลแบบ relational, การแยกชั้นระบบ, การทดสอบก่อนแก้บั๊ก, Docker deployment, security boundary และ responsive UX"),
        ("5. พัฒนาต่อ", "ทดสอบกับผู้ใช้จริง เพิ่ม pagination ตามปริมาณข้อมูล ทำ custom confirm/undo เพิ่มเอกสารภาพ และนำขึ้น production ด้วย HTTPS/backup/monitoring"),
    ])

    add_heading(doc, "8.3 การใช้ AI ในการพัฒนา", 2)
    add_kv_table(doc, [
        ("เครื่องมือ", "OpenAI Codex"),
        ("งานที่ใช้ช่วย", "สำรวจโครงสร้างโครงการ วิเคราะห์บั๊กและความเสี่ยง ปรับ responsive UI เขียน/แก้ tests จัดทำคู่มือภาษาไทย และสรุปเอกสารโครงการ"),
        ("ตัวอย่าง Prompt", "“รัน http://localhost:8080/ ไม่ได้ ทั้งที่ docker compose up -d --build ไปแล้ว” และ “Polish the existing UI slightly and make the whole app fully responsive on mobile … Run build and lint.”"),
        ("วิธีตรวจสอบ", "อ่าน diff และโค้ดที่แก้ รัน PHPUnit/PHPStan/PHP-CS-Fixer/npm lint/build ตรวจ Docker health/logs และทดสอบ workflow กับ viewport ที่กำหนด"),
        ("ผลที่ใช้จริง", "นำข้อเสนอและโค้ดที่ผ่านการตรวจ/ทดสอบมาใช้ ผู้เรียนต้องอธิบายเหตุผลได้ และปรับข้อความ/ขอบเขตให้ตรงกับระบบจริงก่อนส่ง"),
        ("หลักฐาน", "☒ Prompt  ☒ ผลลัพธ์ AI  ☒ โค้ดก่อน–หลัง  ☒ ผลทดสอบ  |  ห้ามแนบรหัสผ่านหรือข้อมูลลูกค้าจริง"),
    ])

    add_heading(doc, "8.4 หลักฐานการนำเสนอผลงาน", 2)
    add_checklist(doc, [
        (False, "สาธิตการใช้งานจริง"),
        (False, "นำเสนอออนไลน์"),
        (False, "วิดีโอสาธิต"),
    ])
    add_para(doc, "สถานะ: รอจัดทำและนำเสนอภายในวันที่ 18 ธันวาคม 2569", size=10.2, color=MUTED, italic=True)
    add_para(doc, "ลิงก์ผลงาน/หลักฐาน: ........................................................................................................................", size=10.2)
    add_para(doc, "ประเด็นที่ควรนำเสนอ", bold_lead="ประเด็นที่ควรนำเสนอ", size=10.5)
    add_checklist(doc, [
        (True, "ที่มาและวัตถุประสงค์ของโครงการ"),
        (True, "การออกแบบและเทคโนโลยีที่ใช้"),
        (True, "ฟังก์ชันสำคัญและการสาธิต"),
        (True, "ผลการทดสอบและการแก้ไขข้อผิดพลาด"),
        (False, "ผลข้อเสนอแนะจากครู/ผู้ใช้ — เติมหลังได้รับจริง"),
        (True, "ปัญหา ข้อจำกัด และแนวทางพัฒนาต่อ"),
    ])

    add_heading(doc, "เกณฑ์การให้คะแนนสำหรับครูผู้สอน (30 คะแนน)", 2)
    add_table(doc, ["รายการประเมิน", "คะแนนเต็ม", "คะแนนที่ได้"], [
        ("1. วิเคราะห์โจทย์ ความต้องการ และขอบเขต", "4", ""),
        ("2. วางแผนและออกแบบระบบ", "4", ""),
        ("3. พัฒนาแอปพลิเคชันและฟังก์ชัน", "6", ""),
        ("4. UI/UX และการจัดการข้อมูล", "4", ""),
        ("5. ทดสอบ ประเมิน และแก้ข้อผิดพลาด", "5", ""),
        ("6. คู่มือ หลักฐาน และการส่งมอบ", "3", ""),
        ("7. นำเสนอและอธิบายแนวทางพัฒนา", "4", ""),
        ("รวม", "30", ""),
    ], [Inches(4.75), Inches(.9), Inches(.95)], font_size=9.2)
    add_para(doc, "กำหนดส่งใบงาน ผลงาน และนำเสนอภายในวันที่ 18 ธันวาคม 2569", size=10.5, bold_lead="กำหนดส่ง")

    add_section_break(doc)
    add_heading(doc, "ภาคผนวก ก — ดัชนีหลักฐานจากโครงการ", 1)
    add_table(doc, ["หลักฐาน", "ตำแหน่ง", "ใช้ยืนยัน"], [
        ("ภาพรวมโครงการ/วิธีรัน", "README.md", "ขอบเขต ระบบ และคำสั่งใช้งาน"),
        ("คู่มือภาษาไทย", "docs/USAGE_TH.md", "ติดตั้ง ใช้งาน และแก้ปัญหา"),
        ("สถาปัตยกรรม", "docs/ARCHITECTURE.md", "request lifecycle, security, frontend"),
        ("API", "docs/API.md + routes/", "เส้นทางเว็บและ REST API"),
        ("ฐานข้อมูล", "database/migrations/sqlite และ pgsql", "ตาราง constraints และ portability"),
        ("Deployment", "docs/DEPLOYMENT.md + docker-compose*.yml", "การติดตั้ง local/production"),
        ("Supabase", "docs/SUPABASE.md", "แนวทาง PostgreSQL/Supabase"),
        ("Audit/ทดสอบ", "docs/AUDIT_REPORT.md + tests/", "ปัญหา การแก้ไข และผลทดสอบ"),
        ("UI/UX", "docs/UX_PROPOSAL.md + resources/", "ผู้ใช้ งานหลัก และ responsive UI"),
        ("Source code", "app/, resources/, public/, config/", "การพัฒนาฟังก์ชันจริง"),
    ], [Inches(1.45), Inches(2.7), Inches(2.45)], font_size=8.8)

    add_heading(doc, "รายการหลักฐานที่ควรเพิ่มก่อนส่ง", 2)
    add_checklist(doc, [
        (False, "ภาพหน้าจอ Login, วันนี้, ผังห้อง, Booking, เช็กอิน/เช็กเอาต์, ลูกค้า และรายงาน"),
        (False, "ภาพ `docker compose ps` ที่บริการ healthy และภาพหน้าเว็บที่เปิดได้"),
        (False, "ภาพผล PHPUnit/lint/build ล่าสุด"),
        (False, "บันทึกการปรึกษาครูพี่เลี้ยง/ผู้ควบคุม พร้อมวันที่"),
        (False, "แบบบันทึกทดลองใช้และข้อเสนอแนะจากผู้ดูแลรีสอร์ท"),
        (False, "ลิงก์วิดีโอหรือสไลด์นำเสนอ"),
    ])
    add_para(doc, "หมายเหตุด้านข้อมูลส่วนบุคคล: ก่อนแนบภาพหรือฐานข้อมูล ให้ปกปิดชื่อ เบอร์โทร เลขบัตร เอกสารแนบ รหัสผ่าน และข้อมูลลูกค้าจริงทุกครั้ง", size=10.2, color=MUTED, italic=True)

    # Remove blank final paragraph if possible and save.
    doc.core_properties.title = "ใบงานปฏิบัติงาน Stay Book"
    doc.core_properties.subject = "การวิเคราะห์ ออกแบบ และพัฒนาไฮบริดแอปพลิเคชัน"
    doc.core_properties.author = "นายทัพพ์จิรัฐ กาญจนเกตุ"
    doc.core_properties.keywords = "Stay Book, Hybrid Application, Web Application, Resort"
    doc.save(OUT_PATH)
    print(OUT_PATH)


if __name__ == "__main__":
    build()
