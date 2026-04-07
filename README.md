# Mental-Health-Chat-Bot
 This Project is a Mental Health Chat Bot that leverages natural language processing techniques, and Openai's GPT-4o model. This program uses Cosine Similarity to compare data from mental health chatbot datasets to user input to find a most similar row to user input, and Openai's GPT 4-o model to tailor the most similar response to be more empathetic to the needs of the user. Also computes sentiment and subjectivity analysis of the user input to recognize feelings and emotions.

# Usage
Python
Swift
# Installation
- Obtain your OpenAI API key from the OpenAI website.
- Clone Repository: 
 ```bash
git clone https://github.com/davidh1832/David_Headen_IS.git
```
# Files
app2.py: Streamlit web app implementation of the Echo mental health chatbot

quote_api.py: RAG retrieval backend logic for Echo. Utilizes Fast API to connect backend logic to Swift UI front end application

Sentiment.py: VADER sentiment analysis file

ContentView.swift: Main app UI page in mobile application. Manages conversation state, message rendering, user input, and asynchronous communication with Python backend API. Displays messages as chatbubbles with timestamps, supports optional religious quote integration (Bible, Quran, Torah), and updates the UI as the user sends and recieves messages. 

API.swift:

credentials.swift:

Sign_up_ui.swift:

chatbot.py: finalized python code to execute in terminal
# Datasets
Combined three hugging face datasets to compute semantic similarity between user input mental health chat bot datasets


