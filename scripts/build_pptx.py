"""Generate Glowly_Presentation.pptx from the defense slide content."""
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

ACCENT = RGBColor(0xE0, 0x6A, 0x8B)   # Glowly pink
DARK = RGBColor(0x22, 0x22, 0x22)
GREY = RGBColor(0x66, 0x66, 0x66)
BG = RGBColor(0xFA, 0xF8, 0xF6)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
BLANK = prs.slide_layouts[6]


def slide(title, bullets, subtitle=None, note=None, big=False):
    s = prs.slides.add_slide(BLANK)
    # background
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = BG
    # accent bar
    bar = s.shapes.add_shape(1, Inches(0), Inches(0), Inches(13.333), Inches(0.25))
    bar.fill.solid(); bar.fill.fore_color.rgb = ACCENT; bar.line.fill.background()
    # title
    tb = s.shapes.add_textbox(Inches(0.7), Inches(0.5), Inches(12), Inches(1.3))
    tf = tb.text_frame; tf.word_wrap = True
    p = tf.paragraphs[0]; p.text = title
    p.font.size = Pt(40 if big else 32); p.font.bold = True; p.font.color.rgb = DARK
    if subtitle:
        sp = tf.add_paragraph(); sp.text = subtitle
        sp.font.size = Pt(18); sp.font.color.rgb = ACCENT
    # body
    if bullets:
        bb = s.shapes.add_textbox(Inches(0.8), Inches(2.0), Inches(11.7), Inches(4.6))
        bf = bb.text_frame; bf.word_wrap = True
        for i, b in enumerate(bullets):
            p = bf.paragraphs[0] if i == 0 else bf.add_paragraph()
            lead = b.startswith("•")
            p.text = b
            p.font.size = Pt(20 if big else 18)
            p.font.color.rgb = DARK if not b.startswith("→") else ACCENT
            p.space_after = Pt(10)
    # speaker note
    if note:
        s.notes_slide.notes_text_frame.text = note
    return s


# 1 Title
s = prs.slides.add_slide(BLANK)
s.background.fill.solid(); s.background.fill.fore_color.rgb = ACCENT
t = s.shapes.add_textbox(Inches(1), Inches(2.6), Inches(11.3), Inches(2.5))
tf = t.text_frame; tf.word_wrap = True
p = tf.paragraphs[0]; p.text = "Glowly"
p.font.size = Pt(72); p.font.bold = True; p.font.color.rgb = RGBColor(0xFF,0xFF,0xFF); p.alignment = PP_ALIGN.CENTER
p2 = tf.add_paragraph(); p2.text = "AI beauty assistant — one photo → structured product intelligence"
p2.font.size = Pt(24); p2.font.color.rgb = RGBColor(0xFF,0xF0,0xF4); p2.alignment = PP_ALIGN.CENTER
p3 = tf.add_paragraph(); p3.text = "Final LLM Project"
p3.font.size = Pt(16); p3.font.color.rgb = RGBColor(0xFF,0xF0,0xF4); p3.alignment = PP_ALIGN.CENTER
s.notes_slide.notes_text_frame.text = "Glowly turns a single phone photo of a skincare product into structured, science-grounded information in ~15 seconds."

# 2 Problem
slide("Problem", [
    "• People own 10–30 skincare products and don't know what's in them",
    "• Can't tell what conflicts, what fits their skin, or how to layer them",
    "• Reading INCI lists is unreadable; Googling each product is slow",
    "",
    "User: anyone building a skincare routine who wants to understand their shelf",
], note="The pain: your bathroom shelf is a black box.")

# 3 Solution
slide("Solution", [
    "One photo →",
    "• Brand · exact product · category",
    "• Full ingredient list + active ingredients WITH their roles",
    "• Skin-type fit · concerns targeted · how to use · safety flags",
    "",
    "Editable, then saved to your collection.",
], note="Point your camera at the tube. That's the entire interaction.")

# 4 Demo
slide("Live Demo", [
    "Scan the Dr.Jart+ Dermaclear →",
    "• reading label → identifying brand → scraping full INCI → structuring",
    "• ~15s, then the filled confirmation screen",
    "",
    "Result: Dr.Jart+ · cleanser · 61 ingredients · actives with roles",
    "Backup: screenshots + curl output if Wi-Fi fails",
], note="Brand correctly identified — not a keyword guess. All from one photo.")

# 5 Architecture
slide("Architecture", [
    "iOS upload → FastAPI → LangGraph state machine → response",
    "",
    "image_analysis → confidence_check →",
    "   ├─ confidence < 0.75 → human confirmation (review screen)",
    "   └─ confidence ≥ 0.75 → save → recommendation generation",
    "",
    "Services: Vision (Sonnet) · Scraper (INCIDecoder) · RAG (Qdrant) · MCP tools",
    "Every LLM call traced in LangSmith",
], subtitle="One request, traced end-to-end", note="Low-confidence results branch to human review instead of guessing.")

# 6 Pipeline
slide("The 5-step AI pipeline", [
    "1. Vision — Claude Sonnet 4.6, single multimodal call (OCR + brand ID + JSON)",
    "2. Vector cache — Qdrant, cosine ≥ 0.88 → instant repeat scans",
    "3. Web scraping — INCIDecoder for the full INCI list",
    "4. Embed & store — self-populating product database",
    "5. Structured response — strict Pydantic → camelCase → Swift",
    "",
    "→ Collapsing 3 lossy calls into 1 fixed our worst bug: 'Dr.Jart+' read as 'Mac'",
], note="One combined call fixed the misidentification and cut latency and cost.")

# 7 Required modules
slide("Required modules — all load-bearing", [
    "• LangGraph workflow + conditional branch + human-in-the-loop",
    "• Custom MCP server — 3 tools (analyze / categorize / recommend)",
    "• Custom Skill — cosmetic-advisor with SKILL.md + triggers",
    "• RAG — Qdrant + all-MiniLM-L6-v2, 63-doc knowledge base",
    "• Web scraping — INCIDecoder (dynamic HTML)",
    "• Multimodality — vision OCR is the core feature",
    "• LangSmith tracing on every LLM call",
], note="Every mandatory module is used in the real flow, not bolted on.")

# 8 Metrics + A/B
slide("Metrics & A/B experiment", [
    "Golden dataset: 41 examples · classification accuracy + LLM-as-judge",
    "",
    "A/B — Haiku 4.5 vs Sonnet 4.6 (classification):",
    "   Pass rate: 92%  vs  96%        Avg score: 0.888 = 0.888",
    "   Cost: 1×  vs  ~8×",
    "",
    "→ Decision: Sonnet for vision, Haiku for text — same quality, 1/8 the cost",
    "→ Failures are missing categories (hand cream, brow), NOT model errors",
], subtitle="We measured, then decided", note="The fix is taxonomy, not a bigger model — we'd have missed that without evals.")

# 9 Trade-offs
slide("Engineering trade-offs", [
    "• One combined vision call vs three — accuracy + cost, fixed misID",
    "• Public /analyze inline vs full LangGraph — simpler client path",
    "• Cache-first + scrape-fallback — fast, cheap, degrades gracefully",
    "• Confidence threshold 0.75 — honest uncertainty → human review",
    "",
    "Cost: ~1–3¢ per fresh scan; cached scans ≈ free",
], note="Each choice is a deliberate trade-off between quality, latency and cost.")

# 10 Conclusion
slide("Conclusion & next steps", [
    "A complete, measured LLM product:",
    "• vision + RAG + web scraping + LangGraph, observable in LangSmith",
    "• evaluated on a 41-example golden dataset with an A/B experiment",
    "",
    "Next: expand category taxonomy (from evals) · scrape ranking ·",
    "model fallback · on-device routine recommendations",
    "",
    "→ One photo in, structured product intelligence out.",
], big=False, note="Not a demo — a complete, measured LLM product.")

out = "Glowly_Presentation.pptx"
prs.save(out)
print("saved", out, "—", len(prs.slides.__iter__.__self__._sldIdLst), "slides")
