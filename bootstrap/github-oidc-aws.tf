resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"


}

data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # CRITICAL SECURITY CONTROL: Restrict assumption strictly to your GitHub organization/repository
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # REPLACE 'YOUR_GITHUB_ORG/YOUR_REPO' with your actual repository path
      # The trailing ':*' matches any branch, environment, or pull request within that repository.
      values = ["repo:github.com/maheshwari2876/aws_with_terraform_21Oct26:*"]
    }
  }
}

# 3. Create IAM role to be assumed by github deployer
resource "aws_iam_role" "github_actions_deployer" {
  name               = "github-actions-deployer-role"
  description        = "Short-lived temporary role assumed by GitHub Actions pipelines"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json
}


# 4. Attach a specific policy to the role
resource "aws_iam_role_policy_attachment" "deployer_permission" {
  policy_arn = aws_iam_openid_connect_provider.github.arn
  role       = aws_iam_role.github_actions_deployer.name
}


# ==============================================================================
# OUTPUTS
# Copy this Role ARN and paste it into your GitHub Actions workflow file!
# ==============================================================================
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_deployer.arn
  description = "The ARN of the IAM role to use in your GitHub Actions YAML workflow"
}
