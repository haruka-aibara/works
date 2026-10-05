# trivy:ignore:GIT-0001
# trivy:ignore:GIT-0003
resource "github_repository" "this" {
  name         = var.repository_name
  description  = var.description
  homepage_url = var.homepage_url
  visibility   = var.visibility
  auto_init    = var.auto_init

  has_issues = var.has_issues
  # Wikis are only available on private repositories with GitHub Pro or above.
  # GitHub silently keeps them disabled otherwise, which would make every plan
  # show a false -> true diff that never converges.
  has_wiki     = var.visibility == "public" ? var.has_wiki : false
  has_projects = var.has_projects

  allow_merge_commit     = var.allow_merge_commit
  allow_squash_merge     = var.allow_squash_merge
  allow_rebase_merge     = var.allow_rebase_merge
  delete_branch_on_merge = var.delete_branch_on_merge

  topics = var.topics

  dynamic "security_and_analysis" {
    for_each = var.visibility == "public" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  # The repositories absorbed into this monorepo have all been destroyed, and the
  # only one left is works itself -- the repository this configuration runs
  # from. Removing its module call must not delete it on an auto-applied run.
  # To destroy a repository on purpose, lift this in the same PR.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
}

# build_type = "legacy" matches the pre-existing setup: a plain
# deploy-from-branch site with a .nojekyll file disabling Jekyll processing,
# not a GitHub Actions-built Pages deployment. A separate resource because
# github_repository's own pages argument is deprecated.
resource "github_repository_pages" "this" {
  count = var.pages != null ? 1 : 0

  repository = github_repository.this.name
  build_type = "legacy"

  source {
    branch = var.pages.branch
    path   = var.pages.path
  }
}

# Branch protection is only available on private repositories with GitHub Pro or
# above, so guard on visibility the same way security_and_analysis does. Creating
# it on a private repository under GitHub Free fails with HTTP 403.
# trivy:ignore:GIT-0004
resource "github_branch_protection" "this" {
  count = var.enable_branch_protection && var.visibility == "public" ? 1 : 0

  repository_id = github_repository.this.node_id
  pattern       = var.protected_branch_pattern

  allows_force_pushes = false
  allows_deletions    = false
  enforce_admins      = var.enforce_admins

  dynamic "required_status_checks" {
    for_each = var.require_up_to_date_branch ? [1] : []
    content {
      strict   = true
      contexts = var.required_status_checks
    }
  }

  dynamic "required_pull_request_reviews" {
    for_each = var.require_pull_request_reviews ? [1] : []
    content {
      required_approving_review_count = var.required_approving_review_count
      dismiss_stale_reviews           = true
    }
  }
}

# GITHUB_TOKEN defaults to read-only; workflows ask for more per job.
# Actions may not approve pull requests, so a workflow cannot satisfy review
# requirements on its own.
resource "github_workflow_repository_permissions" "this" {
  repository = github_repository.this.name

  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}

# Every action and reusable workflow from another repository must be pinned to
# a full commit SHA, so a moved tag cannot change what runs. Local references
# (./.github/...) are not affected.
resource "github_actions_repository_permissions" "this" {
  repository = github_repository.this.name

  enabled              = true
  allowed_actions      = "all"
  sha_pinning_required = var.actions_sha_pinning_required
}
