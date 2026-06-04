"""Generate Glowly_Presentation.pdf — 10 landscape slides."""
from reportlab.lib.pagesizes import landscape
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.pdfgen import canvas

PAGE = (13.333 * inch, 7.5 * inch)
W, H = PAGE
ACCENT = HexColor("#E06A8B")
DARK = HexColor("#222222")
GREY = HexColor("#666666")
BG = HexColor("#FAF8F6")
WHITE = HexColor("#FFFFFF")
PINKBG = HexColor("#FFF0F4")

c = canvas.Canvas("Glowly_Presentation.pdf", pagesize=PAGE)


def wrap(text, font, size, max_w):
    c.setFont(font, size)
    words, lines, cur = text.split(" "), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if c.stringWidth(trial, font, size) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def content_slide(title, bullets, subtitle=None):
    c.setFillColor(BG); c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(ACCENT); c.rect(0, H - 0.18 * inch, W, 0.18 * inch, fill=1, stroke=0)
    # title
    c.setFillColor(DARK); c.setFont("Helvetica-Bold", 30)
    c.drawString(0.7 * inch, H - 0.85 * inch, title)
    y = H - 1.25 * inch
    if subtitle:
        c.setFillColor(ACCENT); c.setFont("Helvetica-Oblique", 15)
        c.drawString(0.7 * inch, y, subtitle); y -= 0.35 * inch
    # bullets
    y -= 0.25 * inch
    for b in bullets:
        if b == "":
            y -= 0.18 * inch; continue
        arrow = b.startswith("→")
        col = ACCENT if arrow else DARK
        font = "Helvetica-Bold" if arrow else "Helvetica"
        for i, line in enumerate(wrap(b, font, 16, W - 1.6 * inch)):
            c.setFillColor(col); c.setFont(font, 16)
            c.drawString((0.8 if i == 0 else 1.05) * inch, y, line)
            y -= 0.34 * inch
        y -= 0.07 * inch
    c.showPage()


# Slide 1 — title
c.setFillColor(ACCENT); c.rect(0, 0, W, H, fill=1, stroke=0)
c.setFillColor(WHITE); c.setFont("Helvetica-Bold", 64)
c.drawCentredString(W / 2, H / 2 + 0.5 * inch, "Glowly")
c.setFillColor(PINKBG); c.setFont("Helvetica", 22)
c.drawCentredString(W / 2, H / 2 - 0.35 * inch,
                    "AI beauty assistant — one photo → structured product intelligence")
c.setFont("Helvetica", 15)
c.drawCentredString(W / 2, H / 2 - 0.95 * inch, "Final LLM Project")
c.showPage()

content_slide("Problem", [
    "• People own 10–30 skincare products and don't know what's in them",
    "• Can't tell what conflicts, what fits their skin, or how to layer them",
    "• Reading INCI lists is unreadable; Googling each product is slow",
    "",
    "User: anyone building a skincare routine who wants to understand their shelf",
])

content_slide("Solution", [
    "One photo →",
    "• Brand · exact product · category",
    "• Full ingredient list + active ingredients WITH their roles",
    "• Skin-type fit · concerns targeted · how to use · safety flags",
    "",
    "Editable, then saved to your collection.",
])

content_slide("Live Demo", [
    "Scan the Dr.Jart+ Dermaclear →",
    "• reading label → identifying brand → scraping full INCI → structuring",
    "• ~15s, then the filled confirmation screen",
    "",
    "Result: Dr.Jart+ · cleanser · 61 ingredients · actives with roles",
    "Backup: screenshots + curl output if Wi-Fi fails",
])

content_slide("Architecture", [
    "iOS upload → FastAPI → LangGraph state machine → response",
    "",
    "image_analysis → confidence_check →",
    "   ├─ confidence < 0.75 → human confirmation (review screen)",
    "   └─ confidence ≥ 0.75 → save → recommendation generation",
    "",
    "Services: Vision (Sonnet) · Scraper (INCIDecoder) · RAG (Qdrant) · MCP tools",
    "Every LLM call traced in LangSmith",
], subtitle="One request, traced end-to-end")

content_slide("The 5-step AI pipeline", [
    "1. Vision — Claude Sonnet 4.6, single multimodal call (OCR + brand ID + JSON)",
    "2. Vector cache — Qdrant, cosine ≥ 0.88 → instant repeat scans",
    "3. Web scraping — INCIDecoder for the full INCI list",
    "4. Embed & store — self-populating product database",
    "5. Structured response — strict Pydantic → camelCase → Swift",
    "",
    "→ Collapsing 3 lossy calls into 1 fixed our worst bug: 'Dr.Jart+' read as 'Mac'",
])

content_slide("Required modules — all load-bearing", [
    "• LangGraph workflow + conditional branch + human-in-the-loop",
    "• Custom MCP server — 3 tools (analyze / categorize / recommend)",
    "• Custom Skill — cosmetic-advisor with SKILL.md + triggers",
    "• RAG — Qdrant + all-MiniLM-L6-v2, 63-doc knowledge base",
    "• Web scraping — INCIDecoder (dynamic HTML)",
    "• Multimodality — vision OCR is the core feature",
    "• LangSmith tracing on every LLM call",
])

content_slide("Metrics & A/B experiment", [
    "Golden dataset: 41 examples · classification accuracy + LLM-as-judge",
    "",
    "A/B — Haiku 4.5 vs Sonnet 4.6 (classification):",
    "   Pass rate: 92%  vs  96%      Avg score: 0.888 = 0.888      Cost: 1× vs ~8×",
    "",
    "→ Decision: Sonnet for vision, Haiku for text — same quality, 1/8 the cost",
    "→ Failures are missing categories (hand cream, brow), NOT model errors",
], subtitle="We measured, then decided")

content_slide("Engineering trade-offs", [
    "• One combined vision call vs three — accuracy + cost, fixed misID",
    "• Public /analyze inline vs full LangGraph — simpler client path",
    "• Cache-first + scrape-fallback — fast, cheap, degrades gracefully",
    "• Confidence threshold 0.75 — honest uncertainty → human review",
    "",
    "Cost: ~1–3¢ per fresh scan; cached scans ≈ free",
])

content_slide("Conclusion & next steps", [
    "A complete, measured LLM product:",
    "• vision + RAG + web scraping + LangGraph, observable in LangSmith",
    "• evaluated on a 41-example golden dataset with an A/B experiment",
    "",
    "Next: expand category taxonomy (from evals) · scrape ranking ·",
    "model fallback · on-device routine recommendations",
    "",
    "→ One photo in, structured product intelligence out.",
])

c.save()
print("saved Glowly_Presentation.pdf")
