# SES rules to manage email forwarding

resource "aws_ses_receipt_rule_set" "main" {
  provider      = aws.euw1-prov
  rule_set_name = "default-rule-set"
}

resource "aws_ses_receipt_rule" "fwder" {
  provider      = aws.euw1-prov
  name          = "website-email-fwd"
  rule_set_name = "default-rule-set"
  recipients    = flatten(regexall("\"(.*)\"", file("files/recips.txt")))
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = aws_s3_bucket.mailbucket.id
    object_key_prefix = "mail/"
    position          = 1
  }
  lambda_action {
    function_arn    = aws_lambda_function.emailfwd.arn
    invocation_type = "Event"
    position        = 2
  }
}
