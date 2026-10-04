
# -------------------------------------------------------------
# ACCOUNT A (000000000000) CONFIGURATION
# -------------------------------------------------------------

# Task 3: Group 1 (Programmatic access only)
resource "aws_iam_group" "group1" {
  name = "group1"
}

resource "aws_iam_user" "engine" {
  name = "engine"
}

resource "aws_iam_user" "ci" {
  name = "ci"
}

resource "aws_iam_group_membership" "group1_members" {
  name  = "group1-membership"
  users = [aws_iam_user.engine.name, aws_iam_user.ci.name]
  group = aws_iam_group.group1.name
}

# Task 3: Group 2 (Console + CLI access)
resource "aws_iam_group" "group2" {
  name = "group2"
}

resource "aws_iam_user" "alice" {
  name = "alice"
}

resource "aws_iam_user" "bob" {
  name = "bob"
}

resource "aws_iam_group_membership" "group2_members" {
  name  = "group2-membership"
  users = [aws_iam_user.alice.name, aws_iam_user.bob.name]
  group = aws_iam_group.group2.name
}

# Task 3: roleA (Admin excluding IAM)
resource "aws_iam_role" "roleA" {
  name = "roleA"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::000000000000:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "roleA_policy" {
  name        = "roleA-admin-no-iam"
  description = "Admin access excluding IAM service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Effect   = "Deny"
        Action   = "iam:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "roleA_attach" {
  role       = aws_iam_role.roleA.name
  policy_arn = aws_iam_policy.roleA_policy.arn
}

# Task 3: roleB (Can only assume roleC in Account B)
resource "aws_iam_role" "roleB" {
  name = "roleB"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::000000000000:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "roleB_policy" {
  name = "roleB-assume-roleC-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::111111111111:role/roleC"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "roleB_attach" {
  role       = aws_iam_role.roleB.name
  policy_arn = aws_iam_policy.roleB_policy.arn
}

# -------------------------------------------------------------
# ACCOUNT B (111111111111) CONFIGURATION — TASK 5 FIXES APPLIED
# -------------------------------------------------------------

# Fix Issue 1: Trust policy identifier must point to the IAM role, not user
data "aws_iam_policy_document" "roleC_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::000000000000:role/roleB"]
    }
  }
}

resource "aws_iam_role" "roleC" {
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

# Fix Issue 2: Scoped specifically to a single named bucket instead of Resource = "*"
resource "aws_iam_role_policy" "roleC_s3" {
  name = "roleC-s3-access"
  role = aws_iam_role.roleC.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = [
          "arn:aws:s3:::my-single-app-bucket",
          "arn:aws:s3:::my-single-app-bucket/*"
        ]
      }
    ]
  })
}
