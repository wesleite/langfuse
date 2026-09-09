resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc.cluster.local"
  kubernetes_ca_cert     = var.kubernetes_ca_cert
  disable_iss_validation = "true"
}

resource "vault_jwt_auth_backend" "oidc" {
  path               = "oidc"
  type               = "oidc"
  description        = "oidc-config"
  oidc_discovery_url = "https://accounts.google.com"
  oidc_client_id     = var.vault_oidc_client_id
  oidc_client_secret = var.vault_oidc_client_secret
  bound_issuer       = "https://accounts.google.com"
  default_role       = "gmail"
  disable_remount    = false

  tune {
    allowed_response_headers     = []
    audit_non_hmac_request_keys  = []
    audit_non_hmac_response_keys = []
    default_lease_ttl            = "768h"
    listing_visibility           = "hidden"
    max_lease_ttl                = "768h"
    passthrough_request_headers  = []
    token_type                   = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "gmail_role" {
  backend        = vault_jwt_auth_backend.oidc.path
  role_name      = "gmail"
  token_policies = ["limited"]
  token_ttl      = 3600
  user_claim     = "email"
  role_type      = "oidc"
  oidc_scopes    = ["openid email profile"]

  bound_audiences = var.vault_oidc_bound_audiences

  allowed_redirect_uris = [
    "${var.vault_address}/ui/vault/auth/oidc/oidc/callback"
  ]

  disable_bound_claims_parsing = false

  depends_on = [
    vault_jwt_auth_backend.oidc
  ]
}

resource "vault_policy" "gitlab_runner" {
  name = "cicd_gitlab-runner"

  policy = <<EOT
path "cicd/data/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "gitlab_runner" {
  backend                          = "kubernetes"
  role_name                        = "cicd_gitlab-runner"
  bound_service_account_names      = ["gitlab-runner"]
  bound_service_account_namespaces = ["cicd"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.gitlab_runner.name]
  audience                         = "https://kubernetes.default.svc"
}

resource "vault_mount" "k8s" {
  path = "k8s"
  type = "kv"
  options = {
    version = "2"
    type    = "kv-v2"
  }
  description = "This is k8s secrets"
}

resource "vault_mount" "cicd" {
  path = "cicd"
  type = "kv"
  options = {
    version = "2"
    type    = "kv-v2"
  }
  description = "This is cicd secrets"
}

resource "vault_policy" "reader" {
  name = "reader"

  policy = <<EOT
path "/k8s/*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_policy" "editor" {
  name = "editor"

  policy = <<EOT
path "k8s/*" {
  capabilities = ["read", "update", "list"]
}
EOT
}

resource "vault_policy" "admin" {
  name = "admin"

  policy = <<EOT
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "/k8s/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}


resource "vault_policy" "limited" {
  name = "limited"

  policy = <<EOT
path "/k8s/*" {
  capabilities = ["list"]
}
EOT
}
