import json
import uuid
import boto3
from datetime import datetime

# AWS Clients
comprehend = boto3.client("comprehend")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("SentimentResults")


def lambda_handler(event, context):
    body = json.loads(event["body"])
    text = body.get("text", "")

    if not text:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "error": "No text provided"
                })
        }

    # Get sentiments analysis
    response = comprehend.detect_sentiment(Text=text, LanguageCode="en")
    sentiment = response["Sentiment"]

    # Store result in DynamoDB
    item = {
        "id": str(uuid.uuid4()),
        "text": text,
        "sentiment": sentiment,
        "timestamp": datetime.now(datetime.timezone.utc).isoformat()
    }
    table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": json.dumps({"sentiment": sentiment, "id": item["id"]})
    }
