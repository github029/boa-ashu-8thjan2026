# Automated Static Security Scanning Using Checkov

## 1️⃣ What is Checkov (simple but precise)

Checkov is a static analysis security scanner for Infrastructure as Code.

It scans:
- Terraform
- CloudFormation
- Kubernetes
- ARM
- Helm

And detects:
- Security misconfigurations
- Compliance violations
- Cloud security best-practice gaps

> 👉 No cloud access  
> 👉 No Terraform apply  
> 👉 Runs early in CI/CD

## 2️⃣ Where Checkov fits in Terraform pipeline

```
terraform fmt
terraform init
terraform validate
tflint
checkov        <-- SECURITY GATE
terraform plan
terraform apply
```

**Key difference:**
- `tflint` → correctness & best practices
- `checkov` → security & compliance

## 3️⃣ What Checkov checks (AWS-focused)

Out-of-the-box, Checkov scans:
- ❌ Public S3 buckets
- ❌ Missing encryption (S3, EBS, RDS)
- ❌ Over-permissive IAM policies (*)
- ❌ Security groups open to 0.0.0.0/0
- ❌ Missing logging
- ❌ Unrestricted EC2 metadata access

## 4️⃣ Lab Demo Setup

```
checkov-demo/
├── main.tf
```

We will intentionally write insecure Terraform code.

## 5️⃣ Insecure Terraform Code (main.tf)

### ❌ S3 without encryption + public access

```hcl
provider "aws" {
    region = "us-east-1"
}

resource "aws_s3_bucket" "bad_bucket" {
    bucket = "my-insecure-bucket-demo"
    acl    = "public-read"
}
```

### ❌ Over-permissive IAM policy

```hcl
resource "aws_iam_policy" "bad_policy" {
    name = "bad-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect   = "Allow"
            Action   = "*"
            Resource = "*"
        }]
    })
}
```

### ❌ Open Security Group

```hcl
resource "aws_security_group" "bad_sg" {
    name = "open-sg"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

## 6️⃣ Install Checkov

**Mac / Linux**

```bash
pip install checkov
```

Verify:
```bash
checkov --version
```

## 7️⃣ Run Checkov (CORE DEMO)

```bash
checkov -d .
```

## 8️⃣ Sample Output (What audience sees)

You'll get output like:

```
Check: CKV_AWS_20: "S3 Bucket has an ACL defined which allows public READ access"
FAILED for resource: aws_s3_bucket.bad_bucket

Check: CKV_AWS_62: "IAM policy should not allow full administrative privileges"
FAILED for resource: aws_iam_policy.bad_policy

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0/0 to port 22"
FAILED for resource: aws_security_group.bad_sg
```

### 🔥 Powerful teaching moment:

- No AWS call made
- No apply required
- Security risks caught early

## 9️⃣ Explain What Just Happened

Checkov:
1. Parsed Terraform files
2. Mapped resources to AWS security policies
3. Compared against CIS, NIST, AWS best practices
4. Failed build due to high-risk findings

## 🔟 Fix the Code Live (Best Demo Impact)

### ✅ Secure S3

```hcl
resource "aws_s3_bucket" "secure_bucket" {
    bucket = "my-secure-bucket-demo"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
    bucket = aws_s3_bucket.secure_bucket.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}
```

### ✅ Secure IAM Policy

```hcl
resource "aws_iam_policy" "limited_policy" {
    name = "limited-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect   = "Allow"
            Action   = [
                "s3:GetObject"
            ]
            Resource = "*"
        }]
    })
}
```

### ✅ Restricted Security Group

```hcl
resource "aws_security_group" "secure_sg" {
    name = "secure-sg"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }
}
```

## 1️⃣1️⃣ Run Checkov Again

```bash
checkov -d .
```

- ✔ Fewer issues
- ✔ Security posture improved
- ✔ Ready for deployment

## 1️⃣2️⃣ Failing CI/CD Automatically

In pipelines:

```bash
checkov -d . --quiet
```

or

```bash
checkov -d . || exit 1
```

👉 Any HIGH / CRITICAL finding blocks deployment

## 1️⃣3️⃣ Skipping a Check (Important Enterprise Topic)

Sometimes business needs exceptions.

```hcl
# checkov:skip=CKV_AWS_24: SSH allowed temporarily for troubleshooting
```

Explain:
- Skips must be justified
- Auditable
- Reviewable in PRs

## 1️⃣4️⃣ How to Explain Checkov to Customers

Use this professional explanation:

> "We use Checkov to perform static security analysis on Terraform code. It detects IAM, S3, network, and encryption risks before infrastructure is deployed, enabling security shift-left and preventing misconfigurations from reaching production."

## 1️⃣5️⃣ Checkov vs Other Tools (Clarity Table)

| Tool | Focus |
|------|-------|
| terraform validate | Syntax |
| tflint | Best practices |
| checkov | Security & compliance |
| tfsec | Security only |
| OPA / Sentinel | Policy-as-code |
