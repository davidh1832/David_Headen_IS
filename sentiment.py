from textblob import TextBlob
'''This file computes sentiment and subjectivity using VADER sentiment and textblob.'''



negative_keywords = [
    "depression", "depressed", "anxiety", "anxious", "panic", "attack",
    "self-harm", "suicidal", "suicide", "worthless", "hopeless",
    "crying", "alone", "lonely", "tired of life", "overwhelmed", "sad", "unmotivated",
    "dead", "died", "deceased", "passed away", "unhappy", "issues", "break up", "upset", "feeling down", "upset"
]



from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import re
def vader_sentiment_analysis(text: str):
    ''' This function calculates the sentiment score of user input using Vader Sentiment, and Subjectivity score with Textblob.'''
    analysis = TextBlob(text)
    analyzer = SentimentIntensityAnalyzer()
    scores = analyzer.polarity_scores(text)
    subjectivity = analysis.sentiment.subjectivity
    str()

    compound = scores["compound"] #Compound scores of negative neutral and positive sentiments

    text_lower = text.lower()
    text_clean = re.sub(r'[^\w\s]', '', text_lower)  # remove punctuation

    #Subjectivity score calculation
    if subjectivity > 0.7:
        subjectivity_category = "Highly Subjective"
    elif 0.4 < subjectivity <= 0.7:
        subjectivity_category = "Moderately Subjective"
    else:
        subjectivity_category = "Objective"



    sentiment = None
    for keyword in negative_keywords:
        if keyword in text_clean:
            sentiment = "Negative"

            break  # stop checking after the first match in negative_keywords

    # If no keyword from negative keywords is present, resort to compound score for sentiment analysis
    if sentiment is None:
        if compound >= 0.05:
            sentiment = "Positive"
        elif compound <= -0.05:
            sentiment = "Negative"
        else:
            sentiment = "Neutral"





    return {

        "Sentiment Label": sentiment,
        "Subjectivity": subjectivity_category

    }


