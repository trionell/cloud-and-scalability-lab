variable "environment" {
  description = "The environment short name"
  type        = string
  default     = "lab"
}

variable "location_long" {
  description = "The location where to place resources"
  type        = string
  default     = "west europe"
}

variable "location" {
  description = "The location short name"
  type        = string
  default     = "we"
}

variable "name" {
  description = "The name to use for the different parts of the deployment"
  type        = string
  default     = "rakebergwebapp3"
}

variable "container_name" {
  description = "The name of the container that will be deployed to the Azure Web App"
  type        = string
  default     = "azure-lab"
}

variable "github_repository" {
  description = "The GitHub repository to use"
  type        = string
}

variable "github_owner" {
  description = "The GitHub username to use (Use the following environment variable to inject: TF_VAR_github_owner)"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "The GitHub token to use (Use the following environment variable to inject: TF_VAR_github_token)"
  type        = string
  sensitive   = true
}