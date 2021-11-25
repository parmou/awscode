
provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}


resource "aws_s3_bucket" "staticFilesJoveoInterview" {
  bucket = "staticfilesjoveointerview"
  acl    = "private"

}

resource "aws_s3_bucket" "dbBackupJoveoInterview" {
  bucket = "dbbackupjoveointerview"
  acl    = "private"

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"

    tags = {
      rule      = "log"
      autoclean = "true"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}




