# s3 bucket used by email process

resource "aws_s3_bucket" "mailbucket" {
  provider      = aws.euw1-prov
  #force_destroy = false
  bucket        = "marymcintyreastronomy-mail"
  tags = {
    "billingtag" = "MarysWebsite"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mainbucket_enc" {
  provider      = aws.euw1-prov
  bucket = aws_s3_bucket.mailbucket.id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mb_lifecycle_rule" {
  provider = aws.euw1-prov
  bucket   = aws_s3_bucket.mailbucket.id
  rule {
    id     = "email purge"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    expiration {
      days                         = 30
      expired_object_delete_marker = false
    }
  }
}

resource "aws_s3_bucket" "mlm-backup" {
  force_destroy = false
  bucket        = "mlm-website-backups"
  tags = {
    "billingtag" = "MarysWebsite"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mlmbkp_lifecycle_rule" {
  bucket = aws_s3_bucket.mlm-backup.id
  rule {
    id     = "expire old files"
    status = "Enabled"
    expiration {
      days                         = 180
      expired_object_delete_marker = false
    }
  }
  rule {
    id     = "delete expired object"
    status = "Enabled"

    #filter {
    #}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket" "mjmm-backup" {
  #force_destroy = false
  bucket        = "mjmm-website-backups"
  tags = {
    "billingtag" = "MarksWebsite"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mjmmbkp_lifecycle_rule" {
  bucket = aws_s3_bucket.mjmm-backup.id
  rule {
    id     = "expire old files"
    status = "Enabled"
    expiration {
      days                         = 180
      expired_object_delete_marker = false
    }
  }
  rule {
    id     = "delete expired object"
    status = "Enabled"

    #filter {
    #}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mjmm_backup_enc" {
  bucket = aws_s3_bucket.mjmm-backup.id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

