# copyright mark mciontyre, 2024-

# create the batch server

data "aws_security_group" "ec2publicsg" {
    name        = "ec2PublicSG"
}

data "aws_kms_key" "container_key" {
    key_id = "arn:aws:kms:eu-west-2:317976261112:key/e9b72945-eaac-4452-9708-93963b09976d"
}

resource "aws_instance" "batchserver" {
  ami                  = "ami-0e58172bedd62916b" # "ami-0fe87e3ed54a170ce"
  instance_type        = "t3a.micro"
  iam_instance_profile = data.aws_iam_instance_profile.s3fullaccess.name
  key_name             = data.aws_key_pair.marks_key.key_name
  security_groups      = [data.aws_security_group.ec2publicsg.name]
  # associate_public_ip_address = false # cant do this in a public subnet

  root_block_device {
    tags = {
      "Name"       = "BatcherverRootDisk"
      "billingtag" = "MarksWebsite"
    }
    volume_size = 8
    volume_type = "gp3"
    throughput = 125
    iops = 3000
    encrypted = true
    kms_key_id = data.aws_kms_key.container_key.arn
  }
  private_dns_name_options {
     hostname_type  = "resource-name"
  }

    metadata_options {
        http_tokens = "required"
        instance_metadata_tags = "enabled"
    }

  tags = {
    "Name"       = "batchserver"
    "billingtag" = "MarksWebsite"
  }
}

data "aws_route53_zone" "mjmmwebsite" {
  zone_id = "Z2RFZ6MC0ICDVH"
}

resource "aws_route53_record" "batchserver" {
  zone_id   = data.aws_route53_zone.mjmmwebsite.zone_id
  type      = "A"
  name      = "batchserver"
  records   = [aws_instance.batchserver.public_ip]
  ttl       = 300
}
