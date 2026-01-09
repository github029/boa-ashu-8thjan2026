# Terraform State Lock Force Release Demo

## 1️⃣ Pre-requisites (Important for Realism)

This lab requires a remote backend with locking, otherwise the demo has no value.

**Backend choice (recommended):**

- **S3** → state storage
- **DynamoDB** → state locking

---

## 2️⃣ Backend Configuration (`main.tf`)

```hcl
terraform {
    backend "s3" {
        bucket         = "terraform-demo-state-lock"
        key            = "ec2/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "terraform-lock-table"
        encrypt        = true
    }
}
```

**📌 Explain:**

- `dynamodb_table` enables distributed locking
- Only one terraform operation allowed at a time

---

## 3️⃣ Simple EC2 Resource (`main.tf`)

```hcl
provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "demo" {
    ami           = "ami-0abcdef1234567890"
    instance_type = "t2.micro"

    tags = {
        Name = "state-lock-demo"
    }
}
```

---

## 4️⃣ Initialize Backend

```sh
terraform init
```

Terraform will:

- Connect to S3
- Register lock table
- Prepare remote state

---

## 5️⃣ Simulating a State Lock Conflict (Key Part)

**🔴 Terminal 1 (User A):**

Run:

```sh
terraform apply
```

When prompted:

> Do you want to perform these actions? yes

⏸ **Do NOT press enter immediately.**  
Leave it running.  
Terraform now holds the state lock.

---

**🔴 Terminal 2 (User B / same user, another shell):**

Run:

```sh
terraform apply
```

❌ You will get this error:

```
Error: Error acquiring the state lock

Lock Info:
    ID:        3d0f7c2e-9f5c-42a7-bc1f-xxxx
    Path:      ec2/terraform.tfstate
    Operation: OperationTypeApply
    Who:       user@machine
    Version:   1.x.x
    Created:   2026-01-07 09:41:22
```

✅ **This is your teaching moment**

**Explain:**

- Terraform prevents concurrent writes
- Lock exists in DynamoDB
- Second operation is blocked to avoid corruption

---

## 6️⃣ Simulating a Stale / Orphan Lock

Now simulate a real failure scenario.

- 🔴 Kill Terminal 1 forcefully
- Close terminal
- Or `CTRL + C`
- Or kill the process

👉 Terraform never released the lock.

---

## 7️⃣ Try Running Terraform Again

```sh
terraform apply
```

❌ Still fails:

```
Error acquiring the state lock
```

**Because:**

- Lock record still exists
- Terraform thinks another operation is running

---

## 8️⃣ Inspect the Lock (Advanced Explanation)

Terraform already told you:

- **Lock ID:** `3d0f7c2e-9f5c-42a7-bc1f-xxxx`

This ID is critical.

---

## 9️⃣ Recover Using `terraform force-unlock` (Core Demo)

⚠️ **WARNING:**  
`force-unlock` should be used only when you are 100% sure no other Terraform process is running.

✅ Run the command:

```sh
terraform force-unlock 3d0f7c2e-9f5c-42a7-bc1f-xxxx
```

You’ll see:

```
Do you really want to force-unlock?
    Terraform will remove the lock on the remote state.
    This could cause corruption.

    Enter 'yes' to continue:
```

Type:

```
yes
```

✅ Lock removed from DynamoDB

---

## 🔟 Verify Recovery

Run:

```sh
terraform apply
```

- ✔ Terraform works again
- ✔ State recovered safely
- ✔ No corruption

---

## 1️⃣1️⃣ What Actually Happened (Deep Explanation)

Behind the scenes:

- Terraform stores a lock item in DynamoDB
- `force-unlock` deletes that lock record
- Terraform can now proceed normally

---

## 1️⃣2️⃣ When to Use `force-unlock` (Very Important)

✅ **Use when:**

- Terraform process crashed
- CI/CD job was killed
- Laptop lost power
- You confirmed no one else is running Terraform

❌ **Never use when:**

- Another engineer is applying changes
- A pipeline is actively running
- You are unsure about lock ownership

---

## 1️⃣3️⃣ How to Explain This to a Customer

Use this exact professional statement:

> “Terraform uses distributed state locking to prevent concurrent infrastructure changes.  
> In rare cases such as crashed jobs or terminated pipelines, locks can remain orphaned.  
> The `terraform force-unlock` command allows controlled recovery by manually releasing  
> the lock, ensuring continued safe operations.”

---

## 1️⃣4️⃣ Bonus: CI/CD Real-World Tip

In pipelines:

Always enable:

- `-lock=true`
- `-lock-timeout=5m`

**Example:**

```sh
terraform apply -lock-timeout=5m
```

This avoids unnecessary `force-unlock` usage.
