# the Lambda's body is being uploaded via a Zip file
# this block creates a zip file from the contents of files/src

data "archive_file" "emailfwdzip" {
  type        = "zip"
  source_dir  = "${path.root}/files/emailfwd/"
  output_path = "${path.root}/files/emailfwd.zip"
}

resource "aws_lambda_function" "emailfwd" {
  provider         = aws.euw1-prov
  function_name    = "emailForwarderV2"
  description      = "Forwards email from marys website"
  filename         = data.archive_file.emailfwdzip.output_path
  source_code_hash = data.archive_file.emailfwdzip.output_base64sha256
  handler          = "emailForwarder.lambda_handler"
  runtime          = "python3.11"
  memory_size      = 128
  timeout          = 250
  role             = "arn:aws:iam::317976261112:role/lambda-s3-full-access-role"
  publish          = false
  environment {
    variables = {
      SES_INCOMING_BUCKET = "marymcintyreastronomy-mail"
      S3_PREFIX           = "mail/"
      SUBJECT_PREFIX      = ""
      VERIFIED_FROM_EMAIL = "no-reply@marymcintyreastronomy.co.uk"
      RECIPS              = file("files/recips.txt")
      FWDS                = file("files/forwards.txt")
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
      log_format = "Text"
      log_group  = "/aws/lambda/emailForwarderV2"
    }  
  tags = {
    Name       = "emailForwarderV2"
    billingtag = "MarysWebsite"
  }
}

resource "aws_lambda_permission" "allow_ses" {
  provider      = aws.euw1-prov
  statement_id  = "allowSESInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.emailfwd.function_name
  principal     = "ses.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "emailforwarderv2" {
  provider      = aws.euw1-prov
  name = "/aws/lambda/emailForwarderV2"
  retention_in_days = 30
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }
}