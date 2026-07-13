from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, ListFlowable, ListItem
)

OUTPUT = "output/pdf/cadet-chat-backend-guide.pdf"
PAGE_W, PAGE_H = A4

NAVY = colors.HexColor("#17233C")
BLUE = colors.HexColor("#2878D0")
CYAN = colors.HexColor("#23A8A1")
LIGHT = colors.HexColor("#F3F7FB")
MID = colors.HexColor("#D9E4EF")
TEXT = colors.HexColor("#253044")
MUTED = colors.HexColor("#637083")
CODE_BG = colors.HexColor("#EEF3F7")
WHITE = colors.white


def header_footer(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(NAVY)
    canvas.rect(0, PAGE_H - 13*mm, PAGE_W, 13*mm, fill=1, stroke=0)
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 8.5)
    canvas.drawString(18*mm, PAGE_H - 8.4*mm, "CADET BACKEND GUIDE")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(PAGE_W - 18*mm, PAGE_H - 8.4*mm, "Chat and RAG architecture")
    canvas.setStrokeColor(MID)
    canvas.line(18*mm, 13*mm, PAGE_W - 18*mm, 13*mm)
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 8)
    canvas.drawString(18*mm, 8.5*mm, "Source Academy Cadet backend")
    canvas.drawRightString(PAGE_W - 18*mm, 8.5*mm, f"Page {doc.page}")
    canvas.restoreState()


doc = BaseDocTemplate(
    OUTPUT, pagesize=A4,
    leftMargin=18*mm, rightMargin=18*mm, topMargin=21*mm, bottomMargin=18*mm,
    title="Cadet Chat Backend Guide",
    author="Codex",
    subject="Backend flow for chat and RAG endpoints",
)
frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="body")
doc.addPageTemplates([PageTemplate(id="main", frames=frame, onPage=header_footer)])

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="TitleX", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=27, leading=32, textColor=NAVY, alignment=TA_CENTER, spaceAfter=9*mm))
styles.add(ParagraphStyle(name="Subtitle", parent=styles["Normal"], fontSize=12, leading=18, textColor=MUTED, alignment=TA_CENTER, spaceAfter=10*mm))
styles.add(ParagraphStyle(name="H1X", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=19, leading=23, textColor=NAVY, spaceBefore=3*mm, spaceAfter=4*mm))
styles.add(ParagraphStyle(name="H2X", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=13, leading=17, textColor=BLUE, spaceBefore=4*mm, spaceAfter=2*mm))
styles.add(ParagraphStyle(name="BodyX", parent=styles["BodyText"], fontSize=9.5, leading=14, textColor=TEXT, spaceAfter=2.5*mm))
styles.add(ParagraphStyle(name="Small", parent=styles["BodyText"], fontSize=8.2, leading=11.5, textColor=MUTED))
styles.add(ParagraphStyle(name="CodeX", parent=styles["Code"], fontName="Courier", fontSize=7.8, leading=11, textColor=TEXT, backColor=CODE_BG, borderPadding=7, spaceBefore=1.5*mm, spaceAfter=3*mm))
styles.add(ParagraphStyle(name="Callout", parent=styles["BodyText"], fontSize=9.3, leading=13.5, textColor=TEXT, backColor=LIGHT, borderColor=CYAN, borderWidth=0, borderPadding=8, leftIndent=3, spaceBefore=2*mm, spaceAfter=3*mm))
styles.add(ParagraphStyle(name="TOC", parent=styles["BodyText"], fontSize=10.5, leading=17, textColor=TEXT, leftIndent=6*mm, bulletIndent=0))


def p(text, style="BodyX"):
    return Paragraph(text, styles[style])


def bullets(items):
    return ListFlowable(
        [ListItem(p(item), leftIndent=4*mm) for item in items],
        bulletType="bullet", start="circle", leftIndent=5*mm, bulletFontSize=6,
        bulletColor=BLUE, spaceAfter=2*mm,
    )


def flow_box(lines):
    data = []
    for i, line in enumerate(lines):
        data.append([p(f"<b>{line}</b>", "Small")])
        if i < len(lines) - 1:
            data.append([p("&#8595;", "Small")])
    t = Table(data, colWidths=[doc.width * 0.72], hAlign="CENTER")
    t.setStyle(TableStyle([
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("BACKGROUND", (0,0), (-1,-1), LIGHT),
        ("BOX", (0,0), (-1,-1), 0.6, MID),
        ("INNERGRID", (0,0), (-1,-1), 0.3, colors.white),
        ("TOPPADDING", (0,0), (-1,-1), 5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 5),
    ]))
    return t


story = []
story += [Spacer(1, 18*mm), p("Cadet Chat Backend Guide", "TitleX"), p("A practical walkthrough of API-key configuration, normal chat, RAG chat, prompt construction, persistence, and backend behavior.", "Subtitle")]
summary = Table([
    [p("NORMAL CHAT", "Small"), p("RAG CHAT", "Small")],
    [p("Paragraph-aware SICP tutor", "H2X"), p("Course-document assistant", "H2X")],
    [p("Frontend supplies section and visible paragraph."), p("Backend routes to files and attaches them to the answer request.")],
    [p("<b>POST</b> /v2/chats<br/><b>POST</b> /v2/chats/message", "CodeX"), p("<b>POST</b> /v2/rag_chat<br/><b>POST</b> /v2/rag_chat/message", "CodeX")],
], colWidths=[doc.width/2 - 3*mm, doc.width/2 - 3*mm], hAlign="CENTER")
summary.setStyle(TableStyle([
    ("VALIGN", (0,0), (-1,-1), "TOP"), ("BACKGROUND", (0,0), (-1,-1), LIGHT),
    ("BOX", (0,0), (-1,-1), 0.8, MID), ("INNERGRID", (0,0), (-1,-1), 0.5, MID),
    ("LEFTPADDING", (0,0), (-1,-1), 10), ("RIGHTPADDING", (0,0), (-1,-1), 10),
    ("TOPPADDING", (0,0), (-1,-1), 8), ("BOTTOMPADDING", (0,0), (-1,-1), 8),
]))
story += [summary, Spacer(1, 14*mm), p("Contents", "H1X")]
for item in ["1. API-key configuration", "2. Shared request pipeline", "3. Normal chat endpoints", "4. RAG chat endpoints", "5. Prompt locations", "6. Persistence and error behavior", "7. Implementation notes and endpoint reference"]:
    story.append(p(item, "TOC"))
story += [Spacer(1, 13*mm), p("Based on the repository state inspected on 11 July 2026.", "Small"), PageBreak()]

story += [p("1. API-key configuration", "H1X"), p("For local development, the OpenAI client can read its key directly from <font name='Courier'>config/dev.secrets.exs</font>. This file is ignored by Git in the repository.")]
story += [p("config :openai,<br/>  api_key: &quot;YOUR_NEW_OPENAI_API_KEY&quot;,<br/>  encryption_key: &quot;a-separate-random-secret-at-least-32-characters&quot;", "CodeX")]
story += [p("<b>These are different secrets.</b> <font name='Courier'>api_key</font> authenticates requests to OpenAI. <font name='Courier'>encryption_key</font> encrypts course-level LLM keys before storing them. Never reuse the OpenAI API key as the encryption key.", "Callout")]
story += [bullets(["Restart <font name='Courier'>mix phx.server</font> after changing the configuration; the OpenAI library reads configuration when the application starts.", "Never commit the secrets file or paste a live key into logs, tickets, or chat.", "If a key is exposed, revoke it in the OpenAI dashboard and create a replacement."])]

story += [p("2. Shared request pipeline", "H1X"), p("Both endpoint groups are declared in <font name='Courier'>lib/cadet_web/router.ex</font> and pass through the same request protections.")]
story += [flow_box(["JSON API pipeline", "JWT authentication", "Assign current_user", "Rate limit", "Controller action"]), Spacer(1, 4*mm)]
story += [bullets(["All four endpoints require an authenticated user.", "The rate limiter allows 500 requests per user per 24-hour period.", "Initialization and message requests both count toward the same rate limit.", "The backend obtains the user from <font name='Courier'>conn.assigns.current_user</font>; the frontend does not select an arbitrary user."])]
story += [PageBreak()]

story += [p("3. Normal chat: /v2/chats", "H1X"), p("Normal chat is a paragraph-aware SICP tutor. Its controller is <font name='Courier'>lib/cadet_web/controllers/chat_controller.ex</font>.")]
story += [p("POST /v2/chats - initialize or load", "H2X"), p("The backend calls <font name='Courier'>LlmConversations.get_or_create_conversation(user.id)</font>. It identifies a normal conversation by <font name='Courier'>prepend_context == []</font>.")]
story += [p("POST /v2/chats<br/>Authorization: Bearer &lt;login JWT&gt;<br/>Content-Type: application/json<br/><br/>{}", "CodeX")]
story += [bullets(["If no row exists, the backend creates one with the assistant greeting: 'Ask me something about this paragraph!'", "Calling initialization again returns the existing conversation, including its stored messages.", "The response contains <font name='Courier'>conversationId</font>, <font name='Courier'>messages</font>, and <font name='Courier'>maxContentSize</font>."])]
story += [p("POST /v2/chats/message - send a question", "H2X"), p("The endpoint requires three string fields:")]
story += [p('{<br/>  "message": "Why does this function call itself?",<br/>  "section": "1.2.1",<br/>  "initialContext": "A recursive process is characterized by..."<br/>}', "CodeX")]
story += [flow_box(["Validate message (maximum 1000 characters)", "Find normal conversation by authenticated user", "Save user message", "Build system prompt", "Take latest 10 stored messages", "Call OpenAI using gpt-4", "Save assistant response", "Return conversationId and response"])]
story += [Spacer(1, 3*mm), p("The request does not need a conversation ID. The server selects the conversation through the authenticated user.", "Callout")]

story += [p("Normal-chat OpenAI payload", "H2X"), p("The final message list begins with a generated system prompt, followed by up to ten recent stored messages in chronological order.")]
story += [p('[<br/>  {"role": "system", "content": "Tutor instructions + summary + paragraph"},<br/>  {"role": "assistant", "content": "Previous answer..."},<br/>  {"role": "user", "content": "Why does this function call itself?"}<br/>]', "CodeX")]
story += [PageBreak()]

story += [p("4. RAG chat: /v2/rag_chat", "H1X"), p("RAG means Retrieval-Augmented Generation. The backend selects relevant course files before asking the model for a final answer. The controller is <font name='Courier'>lib/cadet_web/controllers/rag_chat_controller.ex</font>.")]
story += [p("POST /v2/rag_chat - initialize or load", "H2X"), p("RAG uses the same <font name='Courier'>llm_chats</font> table but marks its conversation with:")]
story += [p('prepend_context == [%{"chat_type" =&gt; "rag"}]', "CodeX")]
story += [p("The initial assistant message welcomes the user as a course assistant. Repeating initialization returns the same RAG conversation.")]
story += [p("POST /v2/rag_chat/message - course-aware question", "H2X"), p('{"message": "What did lecture 4 say about recursion?"}', "CodeX")]
story += [bullets(["The backend gets the course from <font name='Courier'>user.latest_viewed_course_id</font>.", "The course must have <font name='Courier'>pixelbot_routing_prompt</font> and <font name='Courier'>pixelbot_answer_prompt</font>.", "The model is <font name='Courier'>course.llm_model</font>, falling back to <font name='Courier'>gpt-4o</font>.", "No <font name='Courier'>section</font> or <font name='Courier'>initialContext</font> is accepted."])]
story += [flow_box(["Save user question", "Load course document metadata", "Routing OpenAI call selects document IDs", "Fetch selected files from S3", "Base64-encode file attachments", "Answer OpenAI call uses prompt + history + files", "Save and return assistant answer"])]
story += [Spacer(1, 3*mm), p("A RAG message can cause two OpenAI calls: one for document selection and another for the answer.", "Callout")]
story += [PageBreak()]

story += [p("5. Inside the RAG pipeline", "H1X"), p("The orchestration lives in <font name='Courier'>lib/cadet/chatbot/rag_pipeline.ex</font>.")]
story += [p("Document map", "H2X"), p("<font name='Courier'>CourseDocuments</font> loads <font name='Courier'>priv/course_documents/document_map.json</font> and exposes metadata such as ID, title, description, document type, year, and week. It strips the S3 key before sending the map to the model.")]
story += [p("Routing prompt", "H2X"), p("The course's routing prompt must contain <font name='Courier'>%DOCUMENT_MAP%</font>. <font name='Courier'>PromptBuilder.build_routing_prompt/2</font> replaces that placeholder with the JSON document map. The routing model is expected to return a JSON array of IDs, for example:")]
story += [p('["lecture-04", "tutorial-04"]', "CodeX")]
story += [p("Document retrieval", "H2X"), p("<font name='Courier'>DocumentStore</font> fetches selected objects from S3, with up to five concurrent fetches and a 30-second timeout. Successful files are Base64-encoded. The code assigns media types for PDF, PPTX, DOCX, and generic binary files.")]
story += [p("Answer request", "H2X"), p("The final user message becomes multimodal content: one text block followed by file blocks. The payload also includes the answer system prompt and up to ten recent conversation messages.")]
story += [p('{"role":"user","content":[<br/>  {"type":"text","text":"What did lecture 4 say?"},<br/>  {"type":"file","file":{"filename":"Lecture 4.pdf",<br/>   "file_data":"data:application/pdf;base64,..."}}<br/>]}', "CodeX")]
story += [p("Fallback behavior", "H2X"), p("If routing or retrieval cannot provide usable documents, the endpoint falls back to an ordinary answer call without attachments. This covers an empty document map, missing placeholder, failed routing call, unparseable output, no selected IDs, unknown IDs, or failed S3 downloads.")]

story += [PageBreak(), p("6. Where each prompt lives", "H1X")]
prompt_table = Table([
    [p("Prompt", "Small"), p("Location", "Small"), p("Used by", "Small")],
    [p("Normal chat fixed tutor prompt"), p("<font name='Courier'>PromptBuilder.@prompt_prefix</font>"), p("/v2/chats/message")],
    [p("SICP section summaries"), p("<font name='Courier'>SicpNotes</font> module attributes"), p("/v2/chats/message")],
    [p("Visible paragraph"), p("Frontend <font name='Courier'>initialContext</font>"), p("/v2/chats/message")],
    [p("RAG routing prompt"), p("Course <font name='Courier'>pixelbot_routing_prompt</font>"), p("/v2/rag_chat/message")],
    [p("RAG answer prompt"), p("Course <font name='Courier'>pixelbot_answer_prompt</font>"), p("/v2/rag_chat/message")],
], colWidths=[48*mm, 72*mm, 50*mm])
prompt_table.setStyle(TableStyle([
    ("BACKGROUND", (0,0), (-1,0), NAVY), ("TEXTCOLOR", (0,0), (-1,0), WHITE),
    ("VALIGN", (0,0), (-1,-1), "TOP"), ("GRID", (0,0), (-1,-1), 0.5, MID),
    ("ROWBACKGROUNDS", (0,1), (-1,-1), [WHITE, LIGHT]),
    ("LEFTPADDING", (0,0), (-1,-1), 7), ("RIGHTPADDING", (0,0), (-1,-1), 7),
    ("TOPPADDING", (0,0), (-1,-1), 7), ("BOTTOMPADDING", (0,0), (-1,-1), 7),
]))
story += [prompt_table, Spacer(1, 4*mm)]
story += [p("The normal-chat 'Louis standard prompt' is the <font name='Courier'>@prompt_prefix</font> string in <font name='Courier'>lib/cadet/chatbot/prompt_builder.ex</font>. No string named 'Louis' exists in this backend. The complete normal-chat prompt is:", "BodyX")]
story += [p("@prompt_prefix + section summary + @query_prefix + initialContext", "CodeX")]
story += [p("The RAG placeholder code in <font name='Courier'>build_routing_prompt/2</font> is only used by the RAG endpoint. It is not involved in normal <font name='Courier'>/v2/chats/message</font> requests.", "Callout")]

story += [p("7. Persistence and failure behavior", "H1X"), p("Both systems store conversations in the <font name='Courier'>llm_chats</font> table. A row has <font name='Courier'>user_id</font>, <font name='Courier'>prepend_context</font>, a JSON array named <font name='Courier'>messages</font>, and timestamps.")]
story += [bullets(["Messages are not separate database rows. Adding one message rewrites the conversation's complete messages array.", "The full history remains stored, but only the latest ten messages are sent to OpenAI.", "The user message is saved before the OpenAI call.", "If OpenAI fails or returns no choice, the user message remains and the backend appends a system error message.", "There is no reset or delete-chat endpoint in the inspected code."])]

story += [PageBreak(), p("8. Endpoint reference", "H1X")]
endpoint_table = Table([
    [p("Method and path", "Small"), p("Body", "Small"), p("Purpose", "Small")],
    [p("POST /v2/chats"), p("{}", "CodeX"), p("Load/create normal chat")],
    [p("POST /v2/chats/message"), p("message, section, initialContext", "CodeX"), p("Paragraph-aware tutor answer")],
    [p("POST /v2/rag_chat"), p("{}", "CodeX"), p("Load/create RAG chat")],
    [p("POST /v2/rag_chat/message"), p("message", "CodeX"), p("Course-document answer")],
], colWidths=[56*mm, 64*mm, 50*mm])
endpoint_table.setStyle(TableStyle([
    ("BACKGROUND", (0,0), (-1,0), NAVY), ("TEXTCOLOR", (0,0), (-1,0), WHITE),
    ("VALIGN", (0,0), (-1,-1), "TOP"), ("GRID", (0,0), (-1,-1), 0.5, MID),
    ("ROWBACKGROUNDS", (0,1), (-1,-1), [WHITE, LIGHT]),
    ("LEFTPADDING", (0,0), (-1,-1), 7), ("RIGHTPADDING", (0,0), (-1,-1), 7),
    ("TOPPADDING", (0,0), (-1,-1), 7), ("BOTTOMPADDING", (0,0), (-1,-1), 7),
]))
story += [endpoint_table, Spacer(1, 5*mm)]
story += [p("Notable implementation observations", "H2X"), bullets(["Both chat systems use the global <font name='Courier'>config :openai, api_key: ...</font> configuration.", "The RAG chat currently does not use the course's encrypted <font name='Courier'>llm_api_key</font> or <font name='Courier'>llm_api_url</font>.", "Normal chat hardcodes the model as <font name='Courier'>gpt-4</font>.", "RAG selects its model from the course and defaults to <font name='Courier'>gpt-4o</font>.", "RAG course selection is based on the user's latest viewed course, not a URL course ID.", "The Swagger annotation in ChatController mentions <font name='Courier'>PUT /chat</font>, but the real router defines <font name='Courier'>POST /v2/chats/message</font>."])]
story += [Spacer(1, 6*mm), p("Key source files", "H2X")]
story += [p("lib/cadet_web/router.ex<br/>lib/cadet_web/controllers/chat_controller.ex<br/>lib/cadet_web/controllers/rag_chat_controller.ex<br/>lib/cadet/chatbot/prompt_builder.ex<br/>lib/cadet/chatbot/llm_conversations.ex<br/>lib/cadet/chatbot/rag_conversations.ex<br/>lib/cadet/chatbot/rag_pipeline.ex<br/>lib/cadet/chatbot/course_documents.ex<br/>lib/cadet/chatbot/document_store.ex<br/>lib/cadet/chatbot/conversation.ex", "CodeX")]

doc.build(story)
print(OUTPUT)
