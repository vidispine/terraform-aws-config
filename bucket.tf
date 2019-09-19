resource "aws_s3_bucket" "bucket" {
  count  = var.is_aggregator ? 1 : 0

  acl    = "private"
  bucket = var.bucket_name

  lifecycle_rule {
    id      = "log"
    enabled = true

    transition {
      days          = var.transition_to_glacier
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration
    }
  }
}

data "aws_iam_policy_document" "config" {
  statement {
    actions = [
      "s3:*",
    ]
    condition {
      test = "Bool"
      values = [
        "false",
      ]
      variable = "aws:SecureTransport"
    }
    effect = "Deny"
    principals {
      identifiers = [
        "*",
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.bucket[0].arn,
      "${aws_s3_bucket.bucket[0].arn}/*",
    ]
    sid = "DenyUnsecuredTransport"
  }
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.is_aggregator ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
  policy = data.aws_iam_policy_document.config.json
}