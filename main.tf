###############################################################################
# OIDC identity provider (keystone)
#
# Guarded via for_each (no count): the "this" key materializes only when the
# caller supplies an oidc object. url is FORCE-NEW. thumbprint_list is omitted
# when null so IAM auto-retrieves/validates the thumbprint for major IdPs.
###############################################################################

resource "aws_iam_openid_connect_provider" "this" {
 for_each = var.oidc != null ? { this = var.oidc }: {}

 url = each.value.url
 client_id_list = each.value.client_id_list
 thumbprint_list = try(each.value.thumbprint_list, null)

 tags = merge(var.tags, try(each.value.tags, {}))
}

###############################################################################
# SAML identity provider (optional sibling)
#
# Co-managed when enterprise SSO into IAM is needed. name is FORCE-NEW.
###############################################################################

resource "aws_iam_saml_provider" "saml" {
 for_each = var.saml != null ? { this = var.saml }: {}

 name = each.value.name
 saml_metadata_document = each.value.saml_metadata_document

 tags = merge(var.tags, try(each.value.tags, {}))
}
