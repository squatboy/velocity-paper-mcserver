resource "aws_dlm_lifecycle_policy" "ebs_snapshot_policy" {
  description        = "Hourly snapshots for ${var.project_name} EBS volumes"
  execution_role_arn = var.dlm_role_arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      "Project" = var.project_name
    }

    schedule {
      name = "HourlySnapshots"

      create_rule {
        interval      = 1
        interval_unit = "HOURS"
        times         = ["00:00"]
      }

      retain_rule {
        count = 2
      }

      tags_to_add = {
        "CreatedBy" = "DLM"
      }

      copy_tags = true
    }
  }

  tags = {
    Name = "${var.project_name}-ebs-snapshot-policy"
  }
}
