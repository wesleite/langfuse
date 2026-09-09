variable "vault_address" {
  description = "The public URL of the HashiCorp Vault server (e.g., https://vault.example.com)."
  type        = string
}

variable "vault_root_token" {
  description = "Initial root token for Vault authentication. Used to configure backend auth and roles."
  type        = string
  sensitive   = true
}

variable "vault_oidc_client_secret" {
  description = "Client secret for the OIDC provider integration (e.g., Google OAuth client secret)."
  type        = string
  sensitive   = true
}

variable "vault_oidc_client_id" {
  description = "Client ID for the OIDC provider integration."
  type        = string
}

variable "vault_oidc_bound_audiences" {
  description = "A list of allowed audiences for OIDC authentication."
  type        = list(string)
}

variable "kubernetes_ca_cert" {
  description = "The CA certificate (PEM format) used by the Kubernetes cluster for Vault to verify connections."
  type        = string
}
