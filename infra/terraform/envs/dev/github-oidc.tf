# Lets GitHub Actions deploy to AWS WITHOUT storing long-lived access keys as
# GitHub secrets. GitHub issues a short-lived OIDC token per workflow run; AWS
# trusts it only for your repo's main branch and hands back temporary creds.
# This is the pattern most companies use - worth being able to explain.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Recent AWS provider versions don't need thumbprint_list for GitHub.
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${local.name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# Least privilege: push to our two ECR repos, and describe the cluster.
data "aws_iam_policy_document" "github_deploy" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
    ]
    resources = module.ecr.repository_arns
  }
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["*"] # TODO: narrow to the cluster ARN
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy.json
}

# TODO(stage 5): IAM lets the role *reach* EKS; Kubernetes RBAC decides what it
# can *do* inside. Add an EKS access entry for this role (in modules/eks via
# `access_entries`) scoped to the job-tracker namespace.
# (Skip this entirely if you move to Argo CD - then CI never touches the cluster.)

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy.arn
}
