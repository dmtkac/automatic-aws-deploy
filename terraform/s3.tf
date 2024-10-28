resource "aws_s3_bucket" "web_app_bucket" {
  bucket = "web-app-bucket-${random_id.bucket_id.hex}"

  force_destroy = true

  tags = {
    Name = "web-app-s3-bucket"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 8
}