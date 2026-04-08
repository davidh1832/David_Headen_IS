# This page is the Echo Streamlit web application that is hosted on a web browser, where users can submit queries and/or select religious quotes, 
#and receive theraputic advice and religious quotes to their mental health queries

import streamlit as st
import sentiment
import Backend_logic

from datetime import datetime

st.set_page_config(page_title="Echo: Mental Health Chatbot", layout="centered")
st.title("Echo Chatbot")
st.write("Hello! My name is Echo, and i'm here to listen and offer support. How are you feeling today?")

#Style and Formatting
st.markdown(
    """
    <style>
    .stApp {
        background-color: white;
        color: black;
    }

    section[data-testid="stSidebar"] {
        background-color: #192e5b;
        color: white;
    }
    </style>
    """,
    unsafe_allow_html=True
)

if "chat_history" not in st.session_state:
    st.session_state.chat_history = []
if "quote_source" not in st.session_state:
    st.session_state.quote_source = None

#Sacred text selection tool
st.sidebar.title("Quote Settings")
quote_choice = st.sidebar.radio(
    "Select Religious Quote Source",
    ("None", "Bible", "Torah", "Quran"),
    index=0
)
st.session_state.quote_source = quote_choice if quote_choice != "None" else None

# User input area
with st.form(key="chat_form"):
    column1, column2 = st.columns([4.5, 1])
    with column1:
        user_input = st.text_input(
            "Enter your message",
            placeholder="I've been feeling overwhelmed lately..."
        )
    with column2:
        send_button = st.form_submit_button("Send", use_container_width=True)

if user_input and send_button:

    # Save user message to session display history
    st.session_state.chat_history.append({
        "role": "user",
        "content": user_input,
        "time": datetime.now().isoformat()
    })

    # TF-IDF, Cosine Similarity, and GPT-4o refinement step
    refined_response = Backend_logic.refine_response_with_gpt(user_input, user_id="default_user")
    response = refined_response

    # Append religious quote if a source is selected
    if st.session_state.quote_source:
        quote, chapter, source_title = Backend_logic.recommend_quotes(
            user_input, source=st.session_state.quote_source
        )
        if quote:
            response += f"\n\n> *{quote}* — {chapter} ({source_title})"

    st.subheader("Echo:")
    st.markdown(response)

    # Sentiment analysis display
    sent = sentiment.vader_sentiment_analysis(user_input)
    st.subheader("Sentiment Analysis:")
    st.json(sent)

    # Save bot response to session display history
    st.session_state.chat_history.append({
        "role": "chatbot",
        "content": response,
        "time": datetime.now().isoformat()
    })

# Sidebar chat history
st.sidebar.title("Chat History")
for msg in st.session_state.chat_history:
    role = "You" if msg["role"] == "user" else "Echo"
    st.sidebar.markdown(f"**{role}:** {msg['content']}")

st.markdown("---")
st.markdown("This tool is **not a replacement** for professional help. If you're in crisis, please call a mental health hotline or emergency services.")

# Run: streamlit run Streamlit_app.py
