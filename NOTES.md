
# Take-Home Assignment Notes

## Task 1 — Lifecycle Block Explanation
The 'prevent_destroy' lifecycle parameter was applied specifically to the 'db-primary' instance ('io2' storage engine).
* **Why:** Primary database nodes store stateful data. Accidental destruction via 'terraform destroy' or an unintended variable update would lead to permanent data loss and major downtime. 'prevent_destroy' causes Terraform to reject any execution plan that results in deleting this resource.

---

## Task 2 — Local State Concurrency vs. Remote State & Locking
* **Local State Risk:** Without a remote backend, 'terraform.tfstate' is stored locally. If two developers run 'terraform apply' concurrently, both read the same initial state, generate conflicting execution plans, and write back to the local file simultaneously. This results in race conditions, resource duplication, and unrecoverable state file corruption.
* **S3 + DynamoDB Solution:** 
  1. **Remote S3 State:** Acts as a centralized, encrypted, versioned single source of truth for state files.
  2. **DynamoDB Locking:** Before executing any write or plan operation, Terraform acquires an exclusive lock by writing a lock ID entry to DynamoDB. If a second user runs 'apply' while the lock is held, Terraform immediately exits with an error ('Error acquiring the state lock'), preventing concurrent executions from corrupting the environment.

---

## Task 3 — IAM Architectural Questions

### 1. Long-Lived Credentials for 'engine' and 'ci'
**No, I would not issue static IAM Users with access keys in production.**

* **The Problem:** Static Access Keys ('AKIA...') are vulnerable to secret leaks (accidental Git commits, compromised build logs) and require manual rotation.
* **Modern Production Pattern:**
  * **For CI/CD (GitHub Actions, GitLab, Jenkins):** Use **Workload Identity Federation (WIF) / OpenID Connect (OIDC)**. The CI runner exchanges a short-lived OIDC token for temporary AWS STS credentials ('sts:AssumeRoleWithWebIdentity'), completely eliminating long-lived keys.
  * **For Human / Local CLI Access ('engine'):** Enforce **AWS IAM Identity Center (Single Sign-On)** paired with short-lived session tokens via 'aws sso login'.

---

### 2. Role Trust Policy: Account Root vs. Specific Role ARN
* **Trusting Account Root ('arn:aws:iam::000000000000:root'):** Delegating trust to the root delegates authority to Account A's IAM administrators. *Any* identity in Account A that has 'sts:AssumeRole' permissions granted by an Account A admin can assume 'roleC'. Account B loses granular control over which specific identity accesses its resources.
* **Trusting Specific Role ('arn:aws:iam::000000000000:role/roleB'):** Enforces a strict security boundary. Only 'roleB' inside Account A can assume 'roleC'. Even if an Account A administrator attempts to grant 'sts:AssumeRole' permissions to another user or role in Account A, Account B will explicitly reject the assumption request at the STS boundary.

---

## Task 4 — Custom CI Policy Constraints & Omissions

### What Was Intentionally Left Out & Why:
1. **ECR Destructive/Administrative Permissions ('ecr:DeleteRepository', 'ecr:BatchDeleteImage'):** CI pipelines should append new image builds, never delete existing repositories or historical tags required for deployment rollbacks.
2. **Full IAM Administrative Access ('iam:*' without constraints):** Added strict 'iam:PassRole' scoped exclusively to 'ecs.amazonaws.com' with specific execution roles. CI needs to pass execution roles to ECS tasks, but must never be allowed to attach arbitrary IAM policies or create administrative users.
3. **S3 Write & Delete Actions ('s3:PutObject', 's3:DeleteObject'):** The requirement specified *read-only* access to the build artifacts bucket. Allowing write permissions could let a compromised pipeline tamper with base artifacts or delete operational backups.

---

## Task 5 — Bug Fixes & Explanations

### Issue 1: Incorrect Principal Identifier Type in Trust Policy
* **Bug:** 'identifiers = ["arn:aws:iam::000000000000:user/roleB"]'
* **Why it Failed:** 'roleB' is an IAM Role, but the identifier used the '/user/' path prefix ('...:user/roleB'). IAM roles exist under the '/role/' path ('arn:aws:iam::000000000000:role/roleB'). AWS STS rejected role assumption because the specified IAM user ARN did not exist.
* **Fix:** Corrected the string format to 'arn:aws:iam::000000000000:role/roleB'.

### Issue 2: Overly Permissive Policy Statement
* **Bug:** 'Action = "s3:*"' with 'Resource = "*"'
* **Why it Failed:** The requirement specified full access to a **single named S3 bucket**. Using 'Resource = "*"' violated least-privilege principles by opening read, write, and delete permissions to every bucket across the entire AWS account.
* **Fix:** Constrained 'Resource' explicitly to the named bucket ARN and its objects ('arn:aws:s3:::my-single-app-bucket' and 'arn:aws:s3:::my-single-app-bucket/*').
