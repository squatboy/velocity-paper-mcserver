variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "discord_webhook_url" {
  description = "The Discord webhook URL for sending notifications"
  type        = string
  sensitive   = true
}


