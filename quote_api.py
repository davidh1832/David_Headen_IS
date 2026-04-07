import os
import time
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

DATA_FILE = "combined_dataset.parquet"
VECTORIZER_FILE = "tfidf_vectorizer.pkl"
CONTEXT_MATRIX_FILE = "context_matrix.npz"
DB_FILE = "chat_history.db"

# Backend Logic
class ChatbotCore:
    def __init__(self):
        print("Creating Chatbot Core")

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

        print("Chatbot Core ready.")

    # This function loads the data file containing the mental health conversation data from Hugging Face
    def load_data(self):
        if os.path.exists(DATA_FILE):
            return pd.read_parquet(DATA_FILE)
        else:
            raise FileNotFoundError("Combined dataset not found.")

    # This function loads the TF-IDF vectorizer and context matrix for the cosine similarity calculation.
    # If the files don't exist, it fits a new model and saves to disk for future runs.
    def load_tfidf(self):
        if os.path.exists(VECTORIZER_FILE) and os.path.exists(CONTEXT_MATRIX_FILE):
            print("Loading cached TF-IDF vectorizer & context matrix...")
            vectorizer = load(VECTORIZER_FILE)
            context_vector = sparse.load_npz(CONTEXT_MATRIX_FILE)
            return vectorizer, context_vector

        print("Fitting TF-IDF model")

        vectorizer = TfidfVectorizer()
        context_vector = vectorizer.fit_transform(self.combined_data["context"])
        dump(vectorizer, VECTORIZER_FILE)
        sparse.save_npz(CONTEXT_MATRIX_FILE, context_vector)
        print("TF-IDF model saved to disk.")

        return vectorizer, context_vector

    # This function loads all religious data from the csv files, and converts it into numerical embeddings
    def load_religious_data(self):
        df4 = pd.read_csv("Bible_Quotes.csv").assign(Source="Bible")
        df5 = pd.read_csv("Torah_Quotes.csv").assign(Source="Torah")
        df6 = pd.read_csv("Quaran_Quotes.csv").assign(Source="Quran")

        religious_data = pd.concat([df4, df5, df6], ignore_index=True)

        # Drop blank quotes so embeddings stay in sync with rows
        religious_data.dropna(subset=["Quote"], inplace=True)
        religious_data["Quote"] = religious_data["Quote"].astype(str).str.strip()
        religious_data = religious_data[religious_data["Quote"] != ""].reset_index(drop=True)

        quotes = religious_data["Quote"].tolist()

        # Compute embeddings for all religious quotes
        embeddings = self.sbert_model.encode(quotes, convert_to_tensor=True)
        return religious_data, embeddings

    # This function creates a database if one doesn't exist under the specific user id
    def create_db(self):
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

    # This function saves new messages to the database with the specific user id, the message itself, and who sent the message (User or Bot)
    def save_message(self, user_id, message, is_user=True):
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO chat (user_id, message, is_user) VALUES (?, ?, ?)",
            (user_id, message, 1 if is_user else 0)
        )
        conn.commit()
        conn.close()

    # This function retrieves the chat history of a specific user from the database.
    def get_chat_history(self, user_id):
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute(
            "SELECT message, is_user FROM chat WHERE user_id=? ORDER BY id ASC",
            (user_id,)
        )
        rows = cursor.fetchall()
        conn.close()

        history_text = ""
        for msg, is_user in rows:
            role = "User" if is_user else "Bot"
            history_text += f"{role}: {msg}\n"
        return history_text.strip()



    # This function retrieves the response from the dataset which is most similar to user input using cosine similarity and the TF-IDF Vectorizer
    def most_similar_response(self, user_input):
        input_vector = self.vectorizer.transform([user_input])
        similarity = cosine_similarity(input_vector, self.context_vector).flatten()
        best_match_row = np.argmax(similarity)
        return self.combined_data.iloc[best_match_row]["response"]

    # This function takes in the best match from dataset which is most similar to the user input, and sentiment and subjectivity of the user input for contextual understanding, and refines the best match to be more empathetic to user using openai GPT-4o model.
    def refine_response_with_gpt(self, user_input: str, user_id: str):
        if not user_input.strip() or user_input.lower() == "exit":
            return "Have a great day!"

        timings = {} #Dictionary that Holds all time measurements
        start = time.perf_counter() #clock time before all operations

        # Time chat history retrieval
        t0 = time.perf_counter()
        history_text = self.get_chat_history(user_id)
        #current time - start time * 1000 for milliseconds, round to two and save to dictionary
        timings["chat history ms"] = round((time.perf_counter() - t0) * 1000, 2)



        # Time TF-IDF cosine similarity retrieval
        t0 = time.perf_counter()
        best_match = self.most_similar_response(user_input)
        timings["cosine similarity retrieval ms"] = round((time.perf_counter() - t0) * 1000, 2)



        # Time sentiment analysis
        t0 = time.perf_counter()
        sentiment = vader_sentiment_analysis(user_input)
        timings["sentiment ms"] = round((time.perf_counter() - t0) * 1000, 2)

        Instructions = [
            {"role": "system", "content": (
                f"You are a supportive mental health assistant. refine the {best_match} response using context and sentiment."
                "1. If input is emotional/distressed, lead with one sentence of empathy followed by 1-2 pieces of practical advice. "
                "2. If input is objective/factual, provide concise, credible facts with minimal empathy."
                "3. Use Chat History to maintain continuity."
                "4. No emojis. Be concise and to the point."
                "5. If distress is detected, validate feelings and calmly suggest professional help."
                "6. Use a numbered list format when giving advice."
            )},
            {"role": "user", "content": f"""
                
                User Input: {user_input}
                Best Match Response from Dataset: {best_match}
                Sentiment: {sentiment}
                Chat History: {history_text}
            """}
        ]

        # Call GPT-4o
        try:
            t0 = time.perf_counter()
            response = self.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=Instructions,
                temperature=0.7
            )
            timings["GPT-4o ms"] = round((time.perf_counter() - t0) * 1000, 2)

            chatbot_response = response.choices[0].message.content.strip()

            # Time DB save
            t0 = time.perf_counter()
            self.save_message(user_id, user_input, is_user=True)
            self.save_message(user_id, chatbot_response, is_user=False)
            timings["db save ms"] = round((time.perf_counter() - t0) * 1000, 2)

            timings["total chat logic ms"] = round((time.perf_counter() - start) * 1000, 2)
            print(f"\n chat Timings \n")
            for key, val in timings.items():
                print(f"  {key}: {val}ms")

            return chatbot_response

        except RateLimitError:
            raise HTTPException(status_code=503, detail="OpenAI API quota limit reached. Please try again later.")


    # This function finds the most semantically similar religious quote from the dataset to the user input. Has the option to pick from the Bible, Quran, or the Torah.
    def recommend_Quotes(self, user_input, source=""):
        if not user_input.strip() or not source or source.lower() == "none":
            return "", "", ""

        timings = {}
        start = time.perf_counter()

        # Time filtering the pre-computed data and embeddings by source
        t0 = time.perf_counter()
        source_name = source.capitalize()
        #Goes through dataframe, checks if the source
        # matches the user's selected source (T,F)
        mask = self.religious_data["Source"] == source_name
        filtered_df = self.religious_data[mask] #Keep rows where source matches the user's source

        if filtered_df.empty:
            return "No source found", "", ""


        filtered_indices = filtered_df.index.tolist() #Gets row numbers of selected source
        filtered_embeddings = self.religious_embeddings[filtered_indices] #Slice the file to keep embeddings of the selected source
        timings["filtering ms"] = round((time.perf_counter() - t0) * 1000, 2)

        # Encoding user input
        t0 = time.perf_counter() # Start timer
        input_embedding = self.sbert_model.encode(user_input, convert_to_tensor=True)
        timings["encoding ms"] = round((time.perf_counter() - t0) * 1000, 2) #

        # Compute Similarity
        t0 = time.perf_counter()
        similarity = util.cos_sim(input_embedding, filtered_embeddings)[0]
        best_idx = int(similarity.cpu().argmax())
        timings["similarity calculation ms"] = round((time.perf_counter() - t0) * 1000, 2)

        timings["total quote logic ms"] = round((time.perf_counter() - start) * 1000, 2)
        print(f"\n quote Timings \n ")
        for key, val in timings.items():
            print(f"  {key}: {val}ms")

        quote_row = filtered_df.iloc[best_idx]
        return quote_row["Quote"], quote_row["Chapter"], quote_row["Source"]


# Initialize the core logic object one time when the app starts
try:
    chatbot_instance = ChatbotCore()
except FileNotFoundError as e:
    print(f"Startup failed: {e}")
    raise

# Define the messages as strings
class ChatRequest(BaseModel):
    user_input: str
    user_id: str = "default_user"

class QuoteRequest(BaseModel):
    user_input: str
    source: str  # (bible, torah, quran)

# Chatbot conversation API endpoint
@app.post("/chat", response_model=str)
def chat_endpoint(request: ChatRequest):
    try:
        response = chatbot_instance.refine_response_with_gpt(
            user_input=request.user_input,
            user_id=request.user_id
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))




# Religious Quote API Endpoint
# Takes in the user input from swift, then finds the most relevant religious quote using semantic search, returns back to client page.
@app.post("/quote", response_model=dict)
def quote_endpoint(request: QuoteRequest):
    try:
        quote, chapter, source_title = chatbot_instance.recommend_Quotes(
            request.user_input,
            request.source
        )
        return {
            "quote": quote,
            "chapter": chapter,
            "source": source_title
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Run:
# cd Desktop
# cd Chatbot
# uvicorn quote_api:app --reload