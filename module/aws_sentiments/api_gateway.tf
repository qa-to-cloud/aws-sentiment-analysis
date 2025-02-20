resource "aws_api_gateway_rest_api" "sentiment_api" {
  name        = "SentimentAPI"
  description = "API for sentiment analysis"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # Enable logging and metrics
  tags = {
    Name        = "Sentiment Analysis API"
    Description = "REST API for text sentiment analysis"
    Service     = "Sentiment Analysis"
  }
}

resource "aws_api_gateway_resource" "sentiment_resource" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  parent_id   = aws_api_gateway_rest_api.sentiment_api.root_resource_id
  path_part   = "analyze"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.sentiment_resource.id
  http_method   = "POST"
  authorization = "AWS_IAM" # Enable IAM authorization

  # Request validation
  request_validator_id = aws_api_gateway_request_validator.validator.id
  request_models = {
    "application/json" = aws_api_gateway_model.request_model.name
  }
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = "sentiment-validator"
  rest_api_id                 = aws_api_gateway_rest_api.sentiment_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "request_model" {
  rest_api_id  = aws_api_gateway_rest_api.sentiment_api.id
  name         = "SentimentRequest"
  description  = "JSON Schema for sentiment analysis request"
  content_type = "application/json"

  schema = jsonencode({
    type     = "object"
    required = ["text"]
    properties = {
      text = {
        type      = "string"
        minLength = 1
        maxLength = 5000
      }
    }
  })
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.sentiment_resource.id
  http_method = aws_api_gateway_method.post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sentiment_analysis_lambda.invoke_arn

  # Enable request/response transformation if needed
  request_parameters = {
    "integration.request.header.X-Amz-Invocation-Type" = "'Event'"
  }

  timeout_milliseconds = 29000 # Set timeout just under Lambda's 30s limit
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.sentiment_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.response_200
  ]

  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  stage_name    = "prod"

  # Enable detailed CloudWatch metrics and logging
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/sentiment-api"
  retention_in_days = 30

  tags = {
    Environment = "prod"
    Application = "sentiment-analysis"
  }
}
