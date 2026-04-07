# Mental-Health-Chat-Bot
 This Project is a web & mobile Mental Health Chat Bot called Echo, that leverages natural language processing techniques, and Openai's GPT-4o model to deliver empathetic conversational support to users. This program uses Cosine Similarity to match user input from curated mental health chatbot datasets, refinement using Openai's GPT-4o model for personalized responses, and performs sentiment and subjectivity analysis to better understand the user's emotions.  
 The web application is built using Streamlit in Python, while the mobile applicaton is developed in Swift, the primary coding language for IOS. A Rest API connects the front-end interface to the backend logic using a Uvicorn server and Fast API, producing asynchronous communication between AI services and the user interface. 

# Usage
Python
Swift
Streamlit
# Installation
- Obtain your OpenAI API key from the OpenAI website.
- Clone Repository: 
 ```bash
git clone https://github.com/davidh1832/David_Headen_IS.git
```
- Required packages: pandas, numpy, scikit-learn, openai, spacy, sentence-transformers, transformers, datasets, joblib, scipy, pyarrow
- Run in terminal to access spacy language model: "python -m spacy download en_core_web_sm"
# Files
app2.py: Streamlit web app implementation of the Echo mental health chatbot

quote_api.py: RAG retrieval backend logic for Echo. Utilizes Fast API to connect backend logic to Swift UI front end application

Sentiment.py: VADER sentiment analysis file

ContentView.swift: Main app UI page in mobile application. Manages conversation state, message rendering, user input, and asynchronous communication with Python backend API. Displays messages as chatbubbles with timestamps, supports optional religious quote integration (Bible, Quran, Torah), and updates the UI as the user sends and recieves messages. 

API.swift: This file defines the ChatbotAPI service layer, which handles asynchronous communication between the SwiftUI app and the FastAPI backend using HTTP POST requests. It sends user messages to the chatbot endpoint, retrieves AI responses and optional religious quotes, measures request latency for performance monitoring, and performs structured error handling and JSON decoding.

credentials.swift: This file provides the login screen UI, allowing users to sign in with email and password credentials or navigate to account creation. It includes a styled authentication layout, navigation routing to the chatbot interface after login.

Sign_up_ui.swift: This file implements the user registration interface for the Echo mental health chatbot using SwiftUI, including input fields for personal information, email validation, password confirmation, and form feedback. Upon successful account creation, the view updates login state using @AppStorage and navigates users directly to the main chatbot interface.

TestMHCBAPP.swift: This file serves as the main entry point of the iOS application, launching the SwiftUI app and initializing the primary window scene. It manages persistent login state using @AppStorage and loads the Echo chatbot interface as the starting view with a smooth transition effect.


# Datasets
Combined three hugging face datasets to compute semantic similarity between user input mental health chat bot datasets. All datasets can be accessed from the Hugging Face website.

Dataset 1: Amod/mental_health_counseling_conversations

Dataset 2: hf://datasets/ShivomH/Mental-Health-Conversations/mental-health-dataset.jsonl

Dataset 3: hf://datasets/fadodr/mental_health_dataset/


