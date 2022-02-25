

# getting AWS Account ID of caller
data "aws_caller_identity" "current" {}

# Our API Gateway
resource "aws_api_gateway_rest_api" "api" {
    name = "CSVaaS"
}

# the Path of our API /receiveData
resource "aws_api_gateway_resource" "receiveData" {
    path_part   = "receiveData"
    parent_id   = aws_api_gateway_rest_api.api.root_resource_id
    rest_api_id = aws_api_gateway_rest_api.api.id
}

# which method should be allowed for /receiveData
resource "aws_api_gateway_method" "method" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.receiveData.id
    http_method   = "POST"
    authorization = "NONE"
}

# call the Lambda function receiveData if /receiveData is called
resource "aws_api_gateway_integration" "integration" {
    rest_api_id             = aws_api_gateway_rest_api.api.id
    resource_id             = aws_api_gateway_resource.receiveData.id
    http_method             = aws_api_gateway_method.method.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.lambda.invoke_arn
}

# Setting up the permission to allow the lambda function to get called by the api gateway
resource "aws_lambda_permission" "apigw_lambda" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = "receiveData"
    principal     = "apigateway.amazonaws.com"

    # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
    source_arn = "arn:aws:execute-api:${var.myregion}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.receiveData.path}"
}