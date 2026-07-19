###############################################################################
# Primary outputs (id + arn)
#
# The OIDC provider is the keystone, so id/arn surface it. Both are null when no
# oidc object is configured (SAML-only deployment); use saml_provider_arn then.
###############################################################################

output "id" {
 description = "The OIDC provider id (its ARN). Null when no oidc object is configured."
 value = try(aws_iam_openid_connect_provider.this["this"].id, null)
}

output "arn" {
 description = <<EOT
The ARN of the OIDC identity provider (cross-resource reference type:
arn:aws:iam::<account>:oidc-provider/<issuer-host>, no region segment — IAM is
global). Consumed by tf_mod_aws_iam_role web-identity trust policies, paired with
Conditions on the aud (audience) and sub (subject) claims. Null when no oidc
object is configured.
EOT
 value = try(aws_iam_openid_connect_provider.this["this"].arn, null)
}

###############################################################################
# OIDC attributes
###############################################################################

output "oidc_url" {
 description = "The issuer URL of the OIDC provider. Null when no oidc object is configured."
 value = try(aws_iam_openid_connect_provider.this["this"].url, null)
}

output "oidc_client_id_list" {
 description = "The list of client IDs (audiences) registered with the OIDC provider."
 value = try(aws_iam_openid_connect_provider.this["this"].client_id_list, null)
}

output "oidc_thumbprint_list" {
 description = "The server-certificate thumbprints associated with the OIDC provider (auto-retrieved by IAM when not pinned)."
 value = try(aws_iam_openid_connect_provider.this["this"].thumbprint_list, null)
}

###############################################################################
# SAML attributes
###############################################################################

output "saml_provider_arn" {
 description = <<EOT
The ARN of the SAML identity provider (cross-resource reference type:
arn:aws:iam::<account>:saml-provider/<name>, no region segment). Consumed by
tf_mod_aws_iam_role SAML trust policies. Null when no saml object is configured.
EOT
 value = try(aws_iam_saml_provider.saml["this"].arn, null)
}

output "saml_provider_id" {
 description = "The SAML provider id (its ARN). Null when no saml object is configured."
 value = try(aws_iam_saml_provider.saml["this"].id, null)
}

output "saml_provider_name" {
 description = "The name of the SAML provider. Null when no saml object is configured."
 value = try(aws_iam_saml_provider.saml["this"].name, null)
}

output "saml_provider_valid_until" {
 description = "Expiration date/time of the SAML provider metadata (RFC1123). Null when no saml object is configured."
 value = try(aws_iam_saml_provider.saml["this"].valid_until, null)
}

###############################################################################
# Tags
###############################################################################

output "tags_all" {
 description = <<EOT
All tags on the configured provider(s), including those inherited from provider
default_tags (resource tags win on key conflict). Resolves to the OIDC provider's
tags_all when present, otherwise the SAML provider's.
EOT
 value = try(aws_iam_openid_connect_provider.this["this"].tags_all, try(aws_iam_saml_provider.saml["this"].tags_all, null))
}

output "saml_provider_tags_all" {
 description = "All tags on the SAML provider (incl. default_tags). Null when no saml object is configured."
 value = try(aws_iam_saml_provider.saml["this"].tags_all, null)
}
