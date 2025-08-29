provider "aws" {
  region = "eu-central-1"
}

data "aws_lambda_function" "hubspot_pdf_ocr_processor" {
  function_name = "hubspot-pdf-ocr-processor"
}

data "aws_lambda_function" "hubspot_llm_generate_json" {
  function_name = "hubspot-llm-generate-json"
}

data "aws_lambda_function" "hubspot_create_deal" {
  function_name = "hubspot-create-deal"
}

# === Permissions S3 → Lambda ===
resource "aws_lambda_permission" "allow_s3_pdf_ocr" {
  statement_id  = "AllowExecutionFromS3BucketPDF"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.hubspot_pdf_ocr_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::hubspot-tickets-pdf"
}

resource "aws_lambda_permission" "allow_s3_llm_generate" {
  statement_id  = "AllowExecutionFromS3BucketOCR"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.hubspot_llm_generate_json.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::hubspot-tickets-pdf"
}

resource "aws_lambda_permission" "allow_s3_create_deal" {
  statement_id  = "AllowExecutionFromS3BucketDeals"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.hubspot_create_deal.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::hubspot-tickets-pdf"
}


# === Notifications S3 pour les autres lambdas ===
resource "aws_s3_bucket_notification" "triggers_hubspot_project" {
  bucket = "hubspot-tickets-pdf"

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.hubspot_pdf_ocr_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "PDF_TEST/"
  }

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.hubspot_llm_generate_json.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "PDF_OCR/"
  }

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.hubspot_create_deal.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "DEAL_JSON/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_pdf_ocr,
    aws_lambda_permission.allow_s3_llm_generate,
    aws_lambda_permission.allow_s3_create_deal
  ]
}
