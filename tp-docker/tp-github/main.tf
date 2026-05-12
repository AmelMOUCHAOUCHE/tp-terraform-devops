resource "github_repository" "app" {
  name        = "${var.project_name}-demo"
  description = "Dépôt géré par Terraform - DevOps S8"
  visibility  = "public"
  has_issues  = true
  auto_init   = true
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.app.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
  }
}

resource "github_actions_secret" "db_url" {
  repository      = github_repository.app.name
  secret_name     = "DATABASE_URL"
  plaintext_value = var.db_url
}