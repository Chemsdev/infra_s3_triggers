provider "aws" {
  region = "eu-central-1"
}

# === Résolution des ARN des lambdas par nom ===
data "aws_lambda_function" "hubspot-get-pdf-of-day" {
  function_name = "hubspot-get-pdf-of-day"
}

data "aws_lambda_function" "hubspot-pdf-ocr-processor" {
  function_name = "hubspot-pdf-ocr-processor"
}

data "aws_lambda_function" "hubspot-llm-generate-json" {
  function_name = "hubspot-llm-generate-json"
}

# data "aws_lambda_function" "hubspot-create-deals" {
#   function_name = "hubspot-create-deals"
# }

# === Permissions S3 → Lambda ===
resource "aws_lambda_permission" "allow_s3_pdf_ocr" {
  statement_id  = "AllowExecutionFromS3BucketPDF"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.hubspot-pdf-ocr-processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::matching-project"
}

resource "aws_lambda_permission" "allow_s3_llm_generate" {
  statement_id  = "AllowExecutionFromS3BucketOCR"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.hubspot-llm-generate-json.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::matching-project"
}

# resource "aws_lambda_permission" "allow_s3_create_deals" {
#   statement_id  = "AllowExecutionFromS3BucketDeals"
#   action        = "lambda:InvokeFunction"
#   function_name = data.aws_lambda_function.hubspot-create-deals.function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = "arn:aws:s3:::matching-project"
# }

# === Permission CloudWatch → Lambda pour cron ===
resource "aws_lambda_permission" "allow_cloudwatch_get_pdf" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.hubspot-get-pdf-of-day.function_name
  principal     = "events.amazonaws.com"
}

# === Déclencheur cron pour hubspot-get-pdf-of-day ===
resource "aws_cloudwatch_event_rule" "get_pdf_daily" {
  name                = "get-pdf-of-day-daily"
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "target_get_pdf_daily" {
  rule      = aws_cloudwatch_event_rule.get_pdf_daily.name
  target_id = "hubspot-get-pdf-of-day"
  arn       = data.aws_lambda_function.hubspot-get-pdf-of-day.arn
}

# === Notifications S3 pour les autres lambdas ===
resource "aws_s3_bucket_notification" "triggers_hubspot_project" {
  bucket = "hubspot-tickets-pdf"

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.hubspot-pdf-ocr-processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "PDF_TEST/"
  }

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.hubspot-llm-generate-json.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "OCR_PDF/"
  }

  # lambda_function {
  #   lambda_function_arn = data.aws_lambda_function.hubspot-create-deals.arn
  #   events              = ["s3:ObjectCreated:*"]
  #   filter_prefix       = "DEAL_JSON/"
  # }

  depends_on = [
    aws_lambda_permission.allow_s3_pdf_ocr,
    aws_lambda_permission.allow_s3_llm_generate,
    # aws_lambda_permission.allow_s3_create_deals,
  ]
}