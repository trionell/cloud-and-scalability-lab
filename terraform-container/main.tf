terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.45.1"
    }
    github = {
      source  = "integrations/github"
      version = "4.3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

locals {
  resource_group_name           = "rg-${var.environment}-${var.location}-${var.name}"
  app_service_plan_name         = "asp-${var.environment}-${var.location}-${var.name}"
  app_service_name              = "wa-${var.environment}-${var.location}-${var.name}"
  azure_container_registry_name = "acr${var.environment}${var.location}${var.name}"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location_long
}

resource "azurerm_app_service_plan" "this" {
  name                = local.app_service_plan_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "this" {
  name                = local.app_service_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  app_service_plan_id = azurerm_app_service_plan.this.id

  site_config {
    app_command_line = ""
    linux_fx_version = "DOCKER|${azurerm_container_registry.this.login_server}/${var.container_name}:latest"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.this.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.this.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.this.admin_password
    "DOCKER_ENABLE_CI"                    = "TRUE"
    "WEBSITES_PORT"                       = "8080"
    "PORT"                                = "8080"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].linux_fx_version,
    ]
  }
}

resource "azurerm_container_registry" "this" {
  name                = local.azure_container_registry_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_registry_webhook" "this" {
  name                = "webapp${replace(azurerm_app_service.this.name, "-", "")}"
  registry_name       = azurerm_container_registry.this.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  service_uri = "https://${azurerm_app_service.this.site_credential[0].username}:${azurerm_app_service.this.site_credential[0].password}@${azurerm_app_service.this.name}.scm.azurewebsites.net/docker/hook"
  status      = "enabled"
  scope       = "${var.container_name}:latest"
  actions     = ["push"]
}

resource "github_actions_secret" "acr_username" {
  repository      = var.github_repository
  secret_name     = "ACR_USERNAME"
  plaintext_value = azurerm_container_registry.this.admin_username
}

resource "github_actions_secret" "acr_password" {
  repository      = var.github_repository
  secret_name     = "ACR_PASSWORD"
  plaintext_value = azurerm_container_registry.this.admin_password
}

resource "github_actions_secret" "acr_hostname" {
  repository      = var.github_repository
  secret_name     = "ACR_HOSTNAME"
  plaintext_value = azurerm_container_registry.this.login_server
}

resource "github_actions_secret" "container_name" {
  repository      = var.github_repository
  secret_name     = "CONTAINER_NAME"
  plaintext_value = var.container_name
}