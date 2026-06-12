# oyd-exercise-8-2 — OIDC Federation + Secrets Manager

> Exercise 8.2 · Optimizaciones y Desempeño — Cloud Deployment Automation · June 11, 2026

Replaces long-lived AWS access keys in CI with keyless OIDC authentication via GitHub Actions. Also stores a database connection string in AWS Secrets Manager for secure retrieval at runtime.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions (CI)                      │
│                                                             │
│  push → main                                                │
│      │                                                      │
│      ▼                                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  configure-aws-credentials (OIDC — no stored keys)  │   │
│  │  role-to-assume: andre-media-ci-runner               │   │
│  └───────────────────────┬──────────────────────────────┘   │
└──────────────────────────│──────────────────────────────────┘
                           │ sts:AssumeRoleWithWebIdentity
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      AWS (us-east-1)                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  aws_iam_openid_connect_provider                    │    │
│  │  url: https://token.actions.githubusercontent.com   │    │
│  └────────────────────────┬────────────────────────────┘    │
│                           │ validates sub + aud             │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  aws_iam_role: andre-media-ci-runner                │    │
│  │  Trust: repo:gitcombo/oyd-exercise-8-2:ref:refs/   │    │
│  │         heads/main  (StringEquals — no wildcards)  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  aws_secretsmanager_secret: andre-media-db-password │    │
│  │  lifecycle: ignore_changes = [secret_string]        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Repository structure

```
oyd-exercise-8-2/
├── main.tf                        # OIDC provider, CI role, Secrets Manager
├── outputs.tf                     # ci_runner_role_arn, db_secret_arn
├── .github/
│   └── workflows/
│       └── ci.yml                 # Keyless OIDC auth (no stored keys)
└── evidence/
    └── ci-run.png                 # Screenshot of passing Actions run
```

---

## Resources created

| Resource | Name |
|---|---|
| `aws_iam_openid_connect_provider` | GitHub OIDC |
| `aws_iam_role` | `andre-media-ci-runner` |
| `aws_iam_policy` | `andre-media-ci-runner-policy` |
| `aws_iam_role_policy_attachment` | — |
| `aws_secretsmanager_secret` | `andre-media-db-password` |
| `aws_secretsmanager_secret_version` | — |

---

## Setup & deploy

### 1. Apply infrastructure

```bash
terraform init
terraform apply -auto-approve
```

Toma nota del output `ci_runner_role_arn`.

### 2. Configurar GitHub Actions Variable

En el repo de GitHub → **Settings → Secrets and variables → Actions → Variables**:

```
Name:  CI_RUNNER_ROLE_ARN
Value: <valor de ci_runner_role_arn del output>
```

### 3. Push a main para disparar CI

```bash
git add .
git commit -m "feat: OIDC federation + Secrets Manager"
git push origin main
```

### 4. Destruir recursos

```bash
terraform destroy -auto-approve
```

---

## Outputs

| Output | Descripción |
|---|---|
| `ci_runner_role_arn` | ARN del rol IAM para el CI runner |
| `db_secret_arn` | ARN del secret en Secrets Manager |

---

## Acceptance criteria

- [x] `aws_iam_openid_connect_provider` con `url = https://token.actions.githubusercontent.com`
- [x] Trust policy usa `StringEquals` (no `StringLike`) en el claim `sub`
- [x] `sub` apunta exactamente a `repo:gitcombo/oyd-exercise-8-2:ref:refs/heads/main`
- [x] `aud` condition es `sts.amazonaws.com`
- [x] `aws_secretsmanager_secret` con `ignore_changes = [secret_string]`
- [x] Secret ARN expuesto como output
- [x] `ci.yml` usa `role-to-assume` y no contiene `aws-access-key-id` ni `aws-secret-access-key`
- [x] `ci.yml` incluye `id-token: write` en el bloque `permissions`
- [ ] `evidence/ci-run.png` muestra el Actions run exitoso

---

## Evidence

<!-- Pegar screenshot del Actions run exitoso en evidence/ci-run.png y hacer commit -->
