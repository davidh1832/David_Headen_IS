import os
import pandas as pd
import numpy as np
import sqlite3
import spacy
from joblib import load, dump
from scipy import sparse
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer, util
from openai import OpenAI, RateLimitError
from sentiment import vader_sentiment_analysis
from dotenv import load_dotenv

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

load_dotenv("secrets.env")
API_KEY = os.getenv("API_KEY")

#Fast API Setup
app = FastAPI(
    title="Mental Health Chatbot API",
    version="1.0.0"
)

# Files
os.environ["TOKENIZERS_PARALLELISM"] = "false"

mental_health_dataset = "combined_dataset.parquet"
tf_idf = "tfidf_vectorizer.pkl"
context_matrix = "context_matrix.npz"
DB_FILE = "chat_history.db"

# Backend Logic
class Core:
    def __init__(self):


        self.openai_client = OpenAI(api_key=API_KEY)

        # Data Loading and Preprocessing
        self.combined_data = self.load_data()
        self.vectorizer, self.context_vector = self.load_tfidf()
        self.nlp = spacy.load("en_core_web_sm")

        # Religious Text Processing
        self.sbert_model = SentenceTransformer("all-MiniLM-L6-v2", device="cpu")
        self.religious_data, self.religious_embeddings = self.load_religious_data()

        # Database Setup
        self.create_db()



    def load_data(self):
        ''' This function loads the data file containing the mental health conversation data from Hugging Face'''

        if os.path.exists(mental_health_dataset):
            return pd.read_parquet(mental_health_dataset)
        else:
            raise FileNotFoundError("Mental health dataset not found.")


    def load_tfidf(self):
        ''' This function loads the TF-IDF vectorizer and context matrix for the cosine similarity calculation.
        If the files don't exist, it fits a new model and saves to disk for future runs.'''
        if os.path.exists(tf_idf) and os.path.exists(context_matrix):
            vect = load(tf_idf)
            context_vector = sparse.load_npz(context_matrix)
            return vect, context_vector



        vectorizer = TfidfVectorizer()
        context_vector = vectorizer.fit_transform(self.combined_data["context"])
        dump(vectorizer, tf_idf)
        sparse.save_npz(context_matrix, context_vector)
        print("TF-IDF saved to disk.")

        return vectorizer, context_vector

    def load_religious_data(self):
        '''  This function loads all religious data from the csv files, and converts it into numerical embeddings '''
        df4 = pd.read_csv("Bible_Quotes.csv").assign(Source="Bible")
        df5 = pd.read_csv("Torah_Quotes.csv").assign(Source="Torah")
        df6 = pd.read_csv("Quaran_Quotes.csv").assign(Source="Quran")

        religious_data = pd.concat([df4, df5, df6], ignore_index=True)

        # Drop blank quotes
        religious_data.dropna(subset=["Quote"], inplace=True)
        religious_data["Quote"] = religious_data["Quote"].astype(str).str.strip()
        religious_data = religious_data[religious_data["Quote"] != ""].reset_index(drop=True)

        quotes = religious_data["Quote"].tolist()

        # Compute embeddings for all religious quotes
        embeddings = self.sbert_model.encode(quotes, convert_to_tensor=True)
        return religious_data, embeddings

    def create_db(self):
        '''This function creates a database if one doesn't exist under the specific user id '''
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS chat (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            message TEXT,
            is_user INTEGER,
            timestamp TEXT DEFAULT CURRENT_TIMESTAMP
        )
        """)
        conn.commit()
        conn.close()

    def save_message(self, user_id, message, is_user=True):
        '''This function saves new messages to the database with the specific user id, the message itself, and who sent the message (User or Bot)'''
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO chat (user_id, message, is_user) VALUES (?, ?, ?)",
            (user_id, message, 1 if is_user else 0)
        )
        conn.commit()
        conn.close()

    def get_chat_history(self, user_id):
        ''' This function retrieves the chat history of a specific user from the database.'''
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute(
            "SELECT message, is_user FROM chat WHERE user_id=? ORDER BY id ASC",
            (user_id,)
        )
        rows = cursor.fetchall()
        conn.close()

        history_text = []
        for msg, is_user in rows:
            role = "user" if is_user else "assistant"
            history_text.append({"role": role, "content": msg})
        return history_text



    def most_similar_response(self, user_input):
        ''' This function retrieves the response from the dataset which is most similar to user input using cosine similarity and the TF-IDF Vectorizer'''
        user_vec = self.vectorizer.transform([user_input])
        sim = cosine_similarity(user_vec, self.context_vector).flatten()
        best_match_row = np.argmax(sim)
        return self.combined_data.iloc[best_match_row]["response"]

    def GPT_Refinement(self, user_input: str, user_id: str):
        '''  This function takes in the best match from dataset which is most similar to the user input, and sentiment and subjectivity of the user input for contextual understanding, and refines the best match to be more empathetic to user using openai GPT-4o model.'''
        if not user_input.strip():
            return "Please type a message."



        # chat history retrieval
        history_text = self.get_chat_history(user_id)

        # TF-IDF cosine similarity retrieval
        best_match = self.most_similar_response(user_input)




        # sentiment analysis

        sentiment = vader_sentiment_analysis(user_input)


        gpt_rules = [
            {"role": "system", "content": (
                "You are a supportive mental health assistant. refine the best match response using context and sentiment."
                "Use a numbered list format whenever giving advice."
                "If the user is emotional or distressed, lead with one sentence of empathy followed by 1-2 pieces of practical advice."
                "If the user input is objective or factual, provide concise credible facts with minimal empathy."
                "Use Chat History to maintain continuity between chats."
                "If distress is detected within the user input, validate their feelings and calmly suggest professional help."

            )},
            *history_text, #Unpacks the chat history list so the GPT can see the full conversation
            {"role": "user", "content": f"""
                
                User Input: {user_input}
                Best Match Response from Dataset: {best_match}
                Sentiment: {sentiment}
            """}

        ]

        # Call GPT-4o
        try:

            refined_resp = self.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=gpt_rules,
                temperature=0.7
            )


            resp = refined_resp.choices[0].message.content.strip()

            #Save to database
            self.save_message(user_id, user_input, is_user=True)
            self.save_message(user_id, resp, is_user=False)

            return resp

        except RateLimitError:
            raise HTTPException(status_code=500, detail="API limit reached! Please try again in a few minutes.")


    def religious_Quotes(self, user_input, source=""):
        ''' This function finds the most semantically similar religious quote from the dataset to the user input. Has the option to pick from the Bible, Quran, or the Torah.'''
        if not user_input.strip() or not source or source.lower() == "none":
            return "", "", ""
        # filtering the embeddings by source

        source_name = source.capitalize()
        #Goes through dataframe, checks if the source
        # matches the user's selected source
        mask = self.religious_data["Source"] == source_name
        filtered_df = self.religious_data[mask]

        if filtered_df.empty:
            return "No source required", "", ""


        filtered = filtered_df.index.tolist()
        filtered_embeddings = self.religious_embeddings[filtered] #Slice the file to keep embeddings of the selected source


        # Encoding user input
        input_embd = self.sbert_model.encode(user_input, convert_to_tensor=True)


        # Compute Similarity
        similarity = util.cos_sim(input_embd, filtered_embeddings)[0]
        best_idx = int(similarity.cpu().argmax())

        row = filtered_df.iloc[best_idx]
        return row["Quote"], row["Chapter"], row["Source"]


# Initialize the core logic object one time when the app starts
try:
    chatbot_instance = Core()
except FileNotFoundError:
    print(f"Loading failed unexpectedly! Please try again later")
    raise

# Define the messages as strings
class ChatRequest(BaseModel):
    user_input: str
    user_id: str = "default_1"

class QuoteRequest(BaseModel):
    user_input: str
    source: str  # (bible, torah, quran)

# Chatbot conversation API endpoint
@app.post("/chat", response_model=str)
def chat_endpoint(request: ChatRequest):
    try:
        resp = chatbot_instance.GPT_Refinement(
            user_input=request.user_input,
            user_id=request.user_id
        )
        return resp
    except Exception:
        raise HTTPException(status_code=500, detail= "An error occurred processing the chat request. Please try again later and/or contact support resources.")




# Religious Quote API Endpoint
# Takes in the user input from swift, then finds the most relevant religious quote using semantic search, returns back to client page.
@app.post("/quote", response_model=dict)
def quote_endpoint(request: QuoteRequest):
    try:
        quote, chapter, source_title = chatbot_instance.religious_Quotes(
            request.user_input,
            request.source
        )
        return {
            "quote": quote,
            "chapter": chapter,
            "source": source_title
        }
    except Exception:
        raise HTTPException(status_code=500, detail= "An error occurred processing the quote request. Please try again later and/or contact support resources.")


# Run:
# cd Desktop
# cd Chatbot
# uvicorn Backend_logic:app --reload