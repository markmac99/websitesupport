# s3 bucket used by email process

resource "aws_s3_bucket" "mailbucket"{
    provider = aws.euw1-prov
    force_destroy = false
    bucket = "marymcintyreastronomy-mail"
    tags = {
        "billingtag" = "MarysWebsite"
    }
}