# Echo Mental Health Chat Bot
 This Project is a web & mobile Mental Health Chat Bot called Echo, which leverages natural language processing techniques, and OpenAI’s GPT-4o model to deliver empathetic conversational support to users. This program utilizes Cosine Similarity to match user input from curated mental health chatbot datasets, refinement using OpenAI’s GPT-4o model for personalized responses, and performs sentiment and subjectivity analysis to better understand the user’s emotions.
 
The web application is built using Streamlit in Python, while the mobile application is developed in Swift, the primary coding language for IOS. A Rest API connects the front-end interface to the backend logic using a Uvicorn server and Fast API, producing asynchronous communication between AI services and the user interface.

# Usage
Python
Swift
Streamlit

- Expect a longer loading time on first initialization of the model, needs to precompute embeddings for cosine similarity comparison purposes.
- 
# Installation
- Obtain your OpenAI API key from the OpenAI website.
- Clone Repository: 
 ```bash
git clone https://github.com/davidh1832/David_Headen_IS.git
```
- Required packages: pandas, numpy, scikit-learn, openai, spacy, sentence-transformers, transformers, datasets, joblib, scipy, pyarrow
- Run in terminal to access the Spacy language model: 
```bash
  python -m spacy download en_core_web_sm
  ```
 
# Files
Streamlit_app.py: Streamlit web app implementation of the Echo mental health chatbot, hosted on a web server.

Backend_logic.py: RAG retrieval backend logic for Echo. Contains data processing, TF-IDF vectorization, database handling, cosine similarity calculations, GPT-4o refinement, and religious quote handling. Utilizes Fast API to connect backend logic to Swift UI front-end application.

Sentiment.py: VADER sentiment and Textblob subjectivity analysis file - determines the sentiment and subjectivity of a user message.

ContentView.swift: Main app UI page in mobile application. Manages conversation state, message rendering, user input, and asynchronous communication with the Python backend API. Displays messages as chat bubbles with timestamps, supports optional religious quote integration (Bible, Quran, Torah), and updates the UI as the user sends and receives messages. 

API.swift: This file defines the ChatbotAPI service layer, which handles asynchronous communication between the SwiftUI app and the FastAPI backend using HTTP POST requests. It sends user messages to the chatbot endpoint, retrieves AI responses and optional religious quotes, measures request latency for performance monitoring, and performs structured error handling and JSON decoding.

credentials.swift: This file provides the login screen UI, allowing users to sign in with email and password credentials or navigate to account creation. It includes a styled authentication layout and navigation routing to the chatbot interface after login.

Sign_up_ui.swift: This file implements the user registration interface for the Echo mental health chatbot using SwiftUI, including input fields for personal information, email validation, password confirmation, and form completion errors. Upon successful account creation, the view updates the login state using @AppStorage and navigates users directly to the main chatbot interface.

TestMHCBAPP.swift: This file serves as the main entry point of the iOS application, launching the SwiftUI app and initializing the primary window scene. It manages persistent login state using @AppStorage and loads the Echo chatbot interface as the starting view.

# Datasets
Three HuggingFace datasets are combined to ground the chatbot in therapeutic information by computing semantic similarity between user input and mental health chatbot datasets. All datasets can be accessed from the Hugging Face website: https://huggingface.co/

Dataset 1: Amod/mental_health_counseling_conversations

Dataset 2: hf://datasets/ShivomH/Mental-Health-Conversations/mental-health-dataset.jsonl

Dataset 3: hf://datasets/fadodr/mental_health_dataset/


