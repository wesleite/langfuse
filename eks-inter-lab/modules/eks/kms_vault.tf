locals {
  create_vault_kms_key = var.vault_enabled && trimspace(var.vault_aws_kms_key_arn) == ""
  vault_kms_key_arn    = var.vault_enabled ? (local.create_vault_kms_key ? aws_kms_key.vault[0].arn : trimspace(var.vault_aws_kms_key_arn)) : ""
}

resource "aws_kms_key" "vault" {
  count                    = local.create_vault_kms_key ? 1 : 0
  description              = "Key used for Vault encryption"
  deletion_window_in_days  = 10
  enable_key_rotation      = true
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "vault" {
  count         = local.create_vault_kms_key ? 1 : 0
  name          = "alias/vault/${var.cluster_name}"
  target_key_id = aws_kms_key.vault[0].id
}
