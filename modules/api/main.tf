resource "aws_ecr_repository" "this" {
  name = "${var.product_name}-api"
}
