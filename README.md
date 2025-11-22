# Secure CI/CD Signing with GitHub Actions and HashiCorp Vault Transit

### Multi-Cloud Architect & DevOps Leader | AWS | Azure | GCP | Kubernetes | CKA & Terraform Certified | GenAI & Automation

LinkedIn : https://www.linkedin.com/in/mahesh-devendran-83a3b214/
---

This repository demonstrates the architectural pattern for building **Zero‑Trust, identity‑driven CI/CD signing pipelines** using:

- **GitHub Actions OIDC** (no long‑lived credentials)
- **HashiCorp Vault Transit Engine** (non‑exportable signing keys)
- **Vault JWT Auth** (workflow → Vault identity mapping)
- **Docker image digest signing** via Transit

The goal is *not* to provide a full production implementation, but to show the **secure design pattern** behind modern enterprise‑grade software supply‑chain signing.

---

## 🔐 Why This Matters

Modern supply-chain attacks target:

- build systems  
- artifact repositories  
- unaudited signing keys  
- CI/CD credentials  
- tampering between build → registry → deployment  

This pattern integrates **OIDC identity**, **non‑exportable keys**, and **Vault auditability** to enforce:

- No static credentials  
- No exposed private keys  
- No runner secrets  
- No trust-on-first-use  
- Every signature tied to:  
  `{repository → branch → actor → workflow → commit}`  

These are direct requirements from:

- **SLSA** (Supply‑chain Levels for Software Artifacts)  
- **NIST SSDF** (Secure Software Development Framework)  
- **CNCF Secure Supply Chain** (cloud‑native integrity model)  

---

## 🧩 Architecture Summary

### 1. GitHub → OIDC Token  
The workflow obtains a **short‑lived identity token** scoped to repo/branch/environment.

### 2. Vault → JWT Auth  
Vault validates the OIDC token and issues a short‑lived **client token**.

Policies ensure:
- Workflow can *only* call `transit/sign/<key>`
- No ability to read, export, or manage keys

### 3. Docker → Digest Extraction  
A demo image is built and its SHA‑256 digest is derived.

### 4. Vault Transit → Signature  
Digest is converted to base64 and signed using an **ECDSA P‑256 Transit key**.

The private key **never leaves Vault**.

### 5. Output → Signature Provenance  
The resulting signature can be published, stored, or verified in downstream systems.

---

## 🔒 Root of Trust (Optional Architectural Note)

In production deployments, Vault is typically bootstrapped with **AWS KMS Auto‑Unseal**, ensuring:

- Vault’s *master key* is encrypted under a KMS CMK  
- No human Shamir shares required  
- Hardware‑backed root‑of‑trust  
- Full audit logging via CloudTrail  

This is a separate operational concern from the signing workflow, but worth understanding for securing the Vault platform.

---

## 📁 Workflow Overview

This repository contains a GitHub Actions workflow that demonstrates:

- Fetching an OIDC token  
- Authenticating to Vault  
- Building a demo Docker image  
- Producing a SHA‑256 digest  
- Converting it to base64  
- Signing it using Transit  
- Outputting the signature  

It is intentionally minimal to focus on the **security architecture**, not productizing a full CI/CD system.

---

## 📎 Appendix — Quick Definitions (with Official Links)

### **SLSA (Supply‑chain Levels for Software Artifacts)**  
A software supply‑chain security framework defining integrity, provenance, and tamper‑resistant builds.  
🔗 https://slsa.dev

### **NIST SSDF (Secure Software Development Framework)**  
The U.S. guideline for secure software development and CI/CD integrity.  
🔗 https://csrc.nist.gov/publications/detail/sp/800-218/final

### **CNCF Secure Supply Chain Framework**  
A cloud‑native architecture blueprint for artifact signing and runtime verification.  
🔗 https://tag-security.cncf.io/supply-chain/

### **HashiCorp Vault Transit Engine**  
Cryptographic service for encryption, signing, and verification using non‑exportable keys.  
🔗 https://developer.hashicorp.com/vault/docs/secrets/transit

---

## 📝 License

This repository is provided as a conceptual and educational reference for secure CI/CD architectures.  
Use at your own discretion in production environments.

