# 🌍 Terraform AWS Infrastructure Deployment

## Project Overview
This project automates the deployment of a **highly available infrastructure** on AWS using Terraform. It provisions **Proxy Servers** and **Backend Servers** across two Availability Zones and stores the Terraform state file in an **S3 backend** for remote state management.

## 🏗️ Architecture Overview
### ✅ Components:
- **Load Balancers:**
  - Public and private Application Load Balancers (ALB) to manage traffic distribution.
- **EC2 Instances:**
  - Proxy servers (NGINX) forwarding requests to backend servers.
- **Networking:**
  - **VPC, Subnets, Route Tables, and Security Groups** configured for high availability.
- **State Management:**
  - Terraform **state file stored in an S3 bucket** with versioning enabled.

---

## 📌 Prerequisites
Ensure you have the following installed before running the project:
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (`terraform -version` to check)
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- SSH key pair for remote access

---

## 🛠️ Setup & Deployment

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/your-repo.git
cd your-repo
```

### 2️⃣ Initialize Terraform
```bash
terraform init
```

### 3️⃣ Plan & Apply Configuration
```bash
terraform plan
terraform apply -auto-approve
```

### 4️⃣ Verify Deployment
Check the Load Balancer URL:
```bash
echo "http://$(terraform output -raw public_lb_dns_name)"
```
Confirm EC2 instances are running:
```bash
aws ec2 describe-instances --query 'Reservations[*].Instances[*].State.Name'
```

---

## 🖼️ Infrastructure Diagram
_(Add an architecture diagram here if available)_

---

## 🧹 Cleanup
To **destroy all resources**, run:
```bash
terraform destroy -auto-approve
```

---



