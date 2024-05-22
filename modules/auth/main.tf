resource "aws_cognito_user_pool" "this" {
  name = var.product_name
}

resource "aws_cognito_identity_provider" "this" {
  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = "EntraID"
  provider_type = "SAML"
  provider_details = {
    MetadataURL = var.metadata_url
  }
  attribute_mapping = {
    email       = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    family_name = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
    given_name  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
    name        = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  }

  lifecycle {
    ignore_changes = [provider_details]
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.product_name
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_pool_client" "this" {
  name                                 = var.product_name
  user_pool_id                         = aws_cognito_user_pool.this.id
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  supported_identity_providers         = [aws_cognito_identity_provider.this.provider_name]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
}
