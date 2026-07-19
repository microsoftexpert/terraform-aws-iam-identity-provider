# tf-mod-aws-iam-identity-provider — SCOPE

Composite module for account-level IAM identity providers used to federate
external identities into AWS without long-lived credentials. It owns the OIDC
provider (the CI/CD federation gold standard — e.g. GitHub Actions / Azure DevOps
assuming roles via short-lived web-identity tokens) and/or a SAML provider (for
enterprise SSO into IAM). Roles trust these providers by ARN.

- **Module type:** Composite
- **Primary resource (keystone):** `aws_iam_openid_connect_provider.this`
- The SAML provider is **optional** and co-managed when SAML federation is needed.

## In-scope resources

The module manages **all** of the following (allow-list):

- `aws_iam_openid_connect_provider` — keystone (OIDC issuer URL, client IDs, thumbprints)
- `aws_iam_saml_provider` — optional (SAML metadata document)

> At least one provider must be configured. OIDC and SAML may both be enabled; each
> is independently optional via its own configuration object.

## Out-of-scope resources (consumed by reference)

Referenced by `arn`, never created here:

- IAM roles that trust this provider (their `assume_role_policy` names the provider
  ARN) — created by `tf-mod-aws-iam-role`
- The external IdP itself (the OIDC issuer / SAML IdP) — operated outside AWS

## Consumes

| Input | Type | Source module |
|---|---|---|
| (none — foundation provider) | — | — |

> **None — foundation module.** It consumes no sibling outputs; it *emits* provider
> ARNs that `tf-mod-aws-iam-role` trust policies consume.

## Required IAM permissions

| Action | Required for |
|---|---|
| `iam:CreateOpenIDConnectProvider`, `iam:DeleteOpenIDConnectProvider` | OIDC provider lifecycle |
| `iam:GetOpenIDConnectProvider`, `iam:UpdateOpenIDConnectProviderThumbprint` | OIDC read / thumbprint rotation |
| `iam:AddClientIDToOpenIDConnectProvider`, `iam:RemoveClientIDFromOpenIDConnectProvider` | OIDC audience (client ID) management |
| `iam:CreateSAMLProvider`, `iam:DeleteSAMLProvider`, `iam:UpdateSAMLProvider`, `iam:GetSAMLProvider` | SAML provider lifecycle (optional) |
| `iam:TagOpenIDConnectProvider`, `iam:UntagOpenIDConnectProvider` | OIDC tagging |
| `iam:TagSAMLProvider`, `iam:UntagSAMLProvider` | SAML tagging |

- No `iam:PassRole` needed. `iam:CreateServiceLinkedRole` not applicable.

## AWS Prerequisites

- **No service-linked role** required.
- **Global service:** IAM is region-less; no `region` variable. Provider ARNs have no region segment.
- **OIDC issuer reachability:** the OIDC issuer URL must be a valid HTTPS endpoint.
  In current AWS, IAM retrieves the issuer's CA thumbprint automatically for the major
  IdPs, but an explicit `thumbprint_list` may be supplied/pinned for control.
- **SAML metadata:** the SAML provider requires the IdP's federation metadata XML document.
- **Quotas:** default 100 OIDC providers and 100 SAML providers per account.
- **Uniqueness:** one provider per unique issuer URL / SAML metadata per account.

## Emits

| Output | Description | Consumed by |
|---|---|---|
| `id` | OIDC provider ARN (the resource id) | references |
| `arn` | OIDC provider ARN (`arn:aws:iam::<account>:oidc-provider/<issuer-host>`) — cross-resource reference type | `tf-mod-aws-iam-role` trust policies (web-identity) |
| `saml_provider_arn` | SAML provider ARN (when created) — cross-resource reference type | `tf-mod-aws-iam-role` trust policies (SAML) |
| `tags_all` | All tags incl. provider `default_tags` | governance/audit |

## Provider gotchas

- **OIDC `url` (issuer) is FORCE-NEW.** Changing the issuer URL replaces the provider.
  Likewise the SAML provider `name` is force-new.
- **`arn` is the cross-resource reference type** (no region segment — IAM is global).
  Trust policies for federated roles reference the provider ARN plus a `Condition`
  on the audience (`aud`) and subject (`sub`) claims.
- **Thumbprint drift.** If thumbprints are managed explicitly and the IdP rotates its
  CA, plan will show drift; current AWS validates major OIDC IdPs against trusted CAs,
  but pin deliberately. Document rotation in the README.
- **Order of operations.** Create the provider here, then create the trusting role in
  `tf-mod-aws-iam-role` referencing this `arn` — do not bake the role's trust into this module.
- **`tags` vs `tags_all`.** `var.tags` flows to both providers; `tags_all` is the
  computed merge over provider `default_tags` (resource tags win). `default_tags` is
  the caller's concern.

## Secure-by-default decisions

| Posture | Default | Opt-out |
|---|---|---|
| Federation model | OIDC web-identity (short-lived tokens) is the recommended path | enable SAML object for enterprise SSO |
| OIDC audiences | caller must specify `client_id_list` (no wildcard) | n/a |
| Thumbprints | optional explicit pinning; AWS auto-validates major IdPs | supply `thumbprint_list` to pin |
| Long-lived credentials | **none issued** — this module replaces static keys | n/a |

> **Why it matters:** OIDC federation is the Casey's CI/CD gold standard — pipelines
> assume roles via short-lived web-identity tokens, so no static AWS keys are stored
> anywhere.

## Design decisions

- One composite co-owns the OIDC and SAML providers because they are sibling
  account-level federation primitives, each independently optional.
- **Role trust is out of scope** — federated roles live in `tf-mod-aws-iam-role` and
  reference this module's provider ARN, keeping the federation primitive decoupled
  from the roles that consume it.
- No `region` variable — IAM is global.
