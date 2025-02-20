data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "../lambda_function"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "sentiment_analysis_lambda" {
  function_name    = "SentimentAnalysisFunction"
  description      = "Lambda function for performing sentiment analysis using AWS Comprehend"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda_function.zip"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  # Configure memory and timeout
  memory_size = 256
  timeout     = 30

  # Enable active tracing with X-Ray
  tracing_config {
    mode = "Active"
  }

  # Environment variables
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.sentiment_table.name
      LOG_LEVEL  = "INFO"
    }
  }

  # VPC configuration if needed
  vpc_config {
    subnet_ids         = [] # Add subnet IDs if VPC access is required
    security_group_ids = [] # Add security group IDs if VPC access is required
  }

  # Configure reserved concurrent executions
  reserved_concurrent_executions = 10

  # Add relevant tags
  tags = {
    Name        = "Sentiment Analysis Lambda"
    Description = "Processes text input for sentiment analysis"
    Service     = "Sentiment Analysis"
  }

  # Lifecycle rules
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}
