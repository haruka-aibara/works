variable "repository_name" {
  description = "The name of the repository"
  type        = string
}

variable "description" {
  description = "A description of the repository"
  type        = string
  default     = ""
}

variable "homepage_url" {
  description = "The website URL shown next to the repository description, e.g. a GitHub Pages site"
  type        = string
  default     = ""
}

variable "visibility" {
  description = "The visibility of the repository. Can be public or private"
  type        = string
  default     = "public"
}

variable "auto_init" {
  description = "Whether to create an initial commit with empty README"
  type        = bool
  default     = true
}

variable "has_issues" {
  description = "Whether to enable GitHub Issues on the repository"
  type        = bool
  default     = true
}

variable "has_wiki" {
  description = "Whether to enable GitHub Wiki on the repository. Forced to false for private repositories, where wikis require GitHub Pro or above"
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Whether to enable GitHub Projects on the repository"
  type        = bool
  default     = true
}

variable "allow_merge_commit" {
  description = "Whether to allow merge commits"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Whether to allow squash merges"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Whether to allow rebase merges"
  type        = bool
  default     = true
}

variable "delete_branch_on_merge" {
  description = "Whether to delete the branch after merging"
  type        = bool
  default     = true
}

variable "topics" {
  description = "The list of topics of the repository"
  type        = list(string)
  default     = []
}

variable "enable_branch_protection" {
  description = "Whether to enable branch protection on the repository. Ignored for private repositories, where branch protection requires GitHub Pro or above"
  type        = bool
  default     = true
}

variable "protected_branch_pattern" {
  description = "The branch name pattern to protect"
  type        = string
  default     = "main"
}

variable "enforce_admins" {
  description = "Whether to enforce branch protection rules for repository administrators"
  type        = bool
  default     = false
}

variable "require_pull_request_reviews" {
  description = "Whether to require pull request reviews before merging"
  type        = bool
  default     = false
}

variable "required_approving_review_count" {
  description = "The number of approving reviews required when pull request reviews are enabled"
  type        = number
  default     = 0
}

variable "require_up_to_date_branch" {
  description = "Whether to require branches to be up to date before merging"
  type        = bool
  default     = true
}

variable "required_status_checks" {
  description = "Status check contexts that must pass before merging. Only applied when require_up_to_date_branch is true. Leave out checks whose workflow is filtered by paths: a check that never reports blocks the PR forever"
  type        = list(string)
  default     = []
}

variable "pages" {
  description = "GitHub Pages configuration. Set to null (default) to leave Pages unmanaged/disabled. path is the folder within the branch to publish, either \"/\" or \"/docs\""
  type = object({
    branch = string
    path   = optional(string, "/")
  })
  default = null
}
