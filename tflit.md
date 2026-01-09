# Automated Validation & Compliance Enforcement Using tflint (Style, Correctness, Best Practices)

## 1️⃣ Why automated validation is needed (business + tech context)

**Terraform by default:**
- Validates syntax only
- Does **NOT** enforce:
    - Best practices
    - Cloud provider standards
    - Security & cost guardrails
    - Naming conventions

**So teams introduce pre-deployment validation to:**
- Catch issues before `terraform apply`
- Enforce organizational standards
- Fail fast in CI/CD pipelines

---

## 2️⃣ Where tflint fits in Terraform lifecycle

**Typical workflow:**
```shell
terraform fmt
terraform init
terraform validate
tflint          # <-- HERE
terraform plan
terraform apply
```
👉 **tflint sits before plan/apply**

---

## 3️⃣ What exactly is tflint?

`tflint` is a static analysis tool for Terraform that:
- Analyzes Terraform code (no AWS calls needed)
- Detects:
    - Invalid arguments
    - Deprecated attributes
    - Provider best practice violations
    - Naming and style issues
    - Cost and performance risks

**Think of it as:**
> “ESLint for Terraform”

---

## 4️⃣ Demo Setup (simple EC2 example)

We’ll intentionally write bad Terraform code, then let tflint catch it.

**Demo structure:**
```
tflint-demo/
├── main.tf
└── .tflint.hcl
```

---

## 5️⃣ Intentionally BAD Terraform Code (`main.tf`)
```hcl
provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "BadEC2" {
    ami           = "ami-0abcdef1234567890"
    instance_type = "t2.micro"

    availability_zone = "us-east-1a"

    tags = {
        name = "bad-instance"
    }
}
```

🚨 **What’s wrong here (don’t explain yet in demo):**
- Resource name uses capital letters
- Tag key `name` instead of `Name`
- Hardcoded AZ
- Missing recommended metadata
- No provider-specific linting enabled yet

---

## 6️⃣ Install tflint (one-time)

**Linux / Mac:**
```shell
brew install tflint
```
or
```shell
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
```

**Verify:**
```shell
tflint --version
```

---

## 7️⃣ First Run: tflint without configuration

```shell
tflint
```

**Output (basic):**
You’ll see limited feedback.

👉 **Teaching moment:**
> “Out-of-the-box tflint is minimal.  
> Real power comes from rules and plugins.”

---

## 8️⃣ Enable AWS Best Practice Rules (CRITICAL STEP)

**Create config file:**
`.tflint.hcl`
```hcl
plugin "aws" {
    enabled = true
    version = "0.33.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

**Initialize plugins:**
```shell
tflint --init
```

---

## 9️⃣ Run tflint Again (Key Demo Moment)

```shell
tflint
```

**Sample Findings (what audience will see):**
```
ERROR: Invalid resource name
    aws_instance.BadEC2
    Resource names should be lowercase and use underscores

WARNING: Tag 'Name' is missing
    aws_instance.BadEC2
    AWS resources should have a Name tag

WARNING: Hardcoded availability_zone detected
    aws_instance.BadEC2
    Consider using variables or data sources
```

✔ Style violation  
✔ Best practice violation  
✔ Maintainability warning

---

## 🔟 Fix the Code Live (best demo impact)

**Corrected Terraform Code:**
```hcl
resource "aws_instance" "web_ec2" {
    ami           = "ami-0abcdef1234567890"
    instance_type = "t2.micro"

    tags = {
        Name = "good-instance"
    }
}
```

Run again:
```shell
tflint
```

✔ Clean  
✔ No warnings  
✔ Ready for deployment

---

## 1️⃣1️⃣ Enforcing Rules (Fail the build)

You can fail deployments automatically.

```shell
tflint --enable-rule=aws_instance_invalid_type
```
or in CI:
```shell
tflint || exit 1
```

Now:
- Any violation = pipeline failure
- No human approval needed

---

## 1️⃣2️⃣ Policy Enforcement Example (Cost Guardrail)

**Add rule to `.tflint.hcl`:**
```hcl
rule "aws_instance_invalid_type" {
    enabled = true
}
```

Now if someone uses:
```hcl
instance_type = "m5.4xlarge"
```

❌ Pipeline fails before apply  
💰 Cost explosion prevented

---

## 1️⃣3️⃣ CI/CD Integration (Real-world example)

**Jenkins / GitHub Actions step:**
```yaml
- name: Terraform Lint
    run: |
        terraform init -backend=false
        tflint --init
        tflint
```

👉 No AWS credentials required  
👉 Safe for PR checks

---

## 1️⃣4️⃣ How to explain this to stakeholders

Use this professional explanation:

> “We enforce infrastructure standards before deployment using tflint.  
> This ensures Terraform code complies with cloud best practices,  
> reduces operational risk, prevents costly misconfigurations,  
> and enables automated governance within CI/CD pipelines.”

---

## 1️⃣5️⃣ Where tflint fits vs other tools (clarity)

| Tool                | Purpose                      |
|---------------------|-----------------------------|
| terraform validate  | Syntax & structure           |
| tflint              | Best practices & correctness |
| tfsec / checkov     | Security policies            |
| OPA / Sentinel      | Enterprise governance        |
