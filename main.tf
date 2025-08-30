# On référence le bucket existant
data "aws_s3_bucket" "hubspot_tickets_pdf" {
  bucket = "hubspot-tickets-pdf"
}

# On référence les Lambdas existantes
data "aws_lambda_function" "hubspot_pdf_ocr_processor" {
  function_name = "hubspot-pdf-ocr-processor"
}

data "aws_lambda_function" "hubspot_llm_generate_json" {
  function_name = "hubspot-llm-generate-json"
}

data "aws_lambda_function" "hubspot_create_deal" {
  function_name = "hubspot-create-deal"
}

# Permissions Lambda pour S3
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

# Notification S3 pour les Lambdas
resource "aws_s3_bucket_notification" "triggers_hubspot_project" {
  bucket = data.aws_s3_bucket.hubspot_tickets_pdf.id

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
