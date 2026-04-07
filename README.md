# Mental-Health-Chat-Bot
 This Project is a Mental Health Chat Bot that leverages natural language processing techniques, and Openai's GPT-4o model. This program uses Cosine Similarity to compare data from mental health chatbot datasets to user input to find a most similar row to user input, and Openai's GPT 4-o model to tailor the most similar response to be more empathetic to the needs of the user. Also computes sentiment and subjectivity analysis of the user input to recognize feelings and emotions.

# Usage
Python
# Installation
- Obtain your OpenAI API key from the OpenAI website.
- Replace 'your_openai_api_key' in the code with your actual API key.
- Clone Repository: 
 ```bash
git clone https://github.com/davidh1832/Mental-Health-Chat-Bot.git
```
# Files
app2.py: Streamlit web app implementation of the Echo mental health chatbot
quote_api.py: RAG retrieval backend logic for Echo. Utilizes Fast API to connect backend logic to Swift UI front end application
Sentiment.py: VADER sentiment analysis file

chatbot.py: finalized python code to execute in terminal
# Datasets
Combined three hugging face datasets to compute semantic similarity between user input mental health chat bot datasets


