# IAM role for Lambda function execution
resource "aws_iam_role" "lambda_role" {
  name = "lambda_sentiment_analysis_role"

  # Allow Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "Lambda Sentiment Analysis Role"
    Description = "IAM role for sentiment analysis Lambda function"
  }
}

# Custom IAM policy for Lambda permissions
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_sentiment_analysis_policy"
  description = "Allows Lambda function to use AWS Comprehend and DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ComprehendAccess"
        Effect   = "Allow"
        Action   = ["comprehend:DetectSentiment"]
        Resource = "*"
      },
      {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.sentiment_table.arn
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = {
    Name        = "Lambda Sentiment Analysis Policy"
    Description = "Policy for sentiment analysis Lambda permissions"
  }
}

# Attach the custom policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}
