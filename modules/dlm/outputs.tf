output "policy_id" {
  description = "The ID of the DLM lifecycle policy"
  value       = aws_dlm_lifecycle_policy.ebs_snapshot_policy.id
}
