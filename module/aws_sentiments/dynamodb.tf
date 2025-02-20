resource "aws_dynamodb_table" "sentiment_table" {
  name         = "SentimentResults"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  # Primary key attribute
  attribute {
    name = "id"
    type = "S" # String type
  }

  # Enable point-in-time recovery for disaster recovery
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Configure TTL for data lifecycle management
  ttl {
    enabled        = true
    attribute_name = "timestamp"
  }

  # Add relevant tags
  tags = {
    Name        = "Sentiment Analysis Results Table"
    Description = "Stores text sentiment analysis results"
    Service     = "Sentiment Analysis"
  }

  # Enable auto-scaling if needed in future
  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
}
