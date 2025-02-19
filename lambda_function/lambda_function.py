import json
import uuid
import boto3
from datetime import datetime

# Initialize AWS clients
comprehend = boto3.client("comprehend")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("SentimentResults")


def lambda_handler(event, context):
    """
    AWS Lambda handler that performs sentiment analysis on provided text
    and stores the results in DynamoDB.
    """
    # Parse and validate input
    body = json.loads(event["body"])
    text = body.get("text", "")

    if not text:
        return create_error_response("No text provided")

    # Perform sentiment analysis
    sentiment = get_sentiment(text)
    
    # Store analysis results
    item = create_dynamodb_item(text, sentiment)
    table.put_item(Item=item)

    # Return success response
    return create_success_response(sentiment, item["id"])


def get_sentiment(text):
    """Analyze text sentiment using AWS Comprehend."""
    response = comprehend.detect_sentiment(Text=text, LanguageCode="en")
    return response["Sentiment"]


def create_dynamodb_item(text, sentiment):
    """Create a DynamoDB item with analysis results."""
    return {
        "id": str(uuid.uuid4()),
        "text": text,
        "sentiment": sentiment,
        "timestamp": datetime.now(datetime.timezone.utc).isoformat()
    }


def create_error_response(message):
    """Create an error response with given message."""
    return {
        "statusCode": 400,
        "body": json.dumps({"error": message})
    }


def create_success_response(sentiment, item_id):
    """Create a success response with analysis results."""
    return {
        "statusCode": 200,
        "body": json.dumps({"sentiment": sentiment, "id": item_id})
    }
