#!/bin/bash
set -e

# -----------------------------
# CONFIGURATION
# -----------------------------
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="eu-west-2"

GITHUB_ORG="mdevendr"
GITHUB_REPO="aws-powertuning"   # <-- update this to the repo where CI/CD lives

OIDC_PROVIDER="token.actions.githubusercontent.com"

EKS_ROLE_NAME="github-eks-deploy-role"
ECR_ROLE_NAME="github-ecr-pull-role"   # Optional (usually not required)
# -----------------------------


echo "🔍 Checking OIDC Provider..."
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER \
  >/dev/null 2>&1 || {

  echo " Creating OIDC Provider..."
  aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "6938ef5d6138fbb87b3b0b1dd5d2efb0d282cc4a"
}

echo "---------------------------------------"
echo "📄 Creating trust policy for EKS deploy"
echo "---------------------------------------"

cat > eks-deploy-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$GITHUB_REPO:*"
        },
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

echo "🛠 Creating / Updating IAM Role: $EKS_ROLE_NAME..."
aws iam create-role \
  --role-name $EKS_ROLE_NAME \
  --assume-role-policy-document file://eks-deploy-trust-policy.json \
  >/dev/null 2>&1 || aws iam update-assume-role-policy \
  --role-name $EKS_ROLE_NAME \
  --policy-document file://eks-deploy-trust-policy.json


echo "---------------------------------------"
echo " Attaching EKS Deployment Permissions"
echo "---------------------------------------"

cat > eks-deploy-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSDeploy",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:AccessKubernetesApi",
        "eks:DescribeNodegroup",
        "eks:DescribeFargateProfile"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRReadPull",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name $EKS_ROLE_NAME \
  --policy-name eks-deployment-policy \
  --policy-document file://eks-deploy-policy.json


echo ""
echo "-------------------------------------------------"
echo " OPTIONAL: ECR Pull Role (Workloads) "
echo " Only needed if your Pods pull from *another account’s* ECR "
echo "-------------------------------------------------"

cat > ecr-pull-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$GITHUB_REPO:*"
        },
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name $ECR_ROLE_NAME \
  --assume-role-policy-document file://ecr-pull-trust-policy.json \
  >/dev/null 2>&1 || true


cat > ecr-pull-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name $ECR_ROLE_NAME \
  --policy-name ecr-pull-policy \
  --policy-document file://ecr-pull-policy.json


echo ""
echo "--------------------------------------------------"
echo " DONE — GitHub OIDC Roles Ready "
echo "--------------------------------------------------"
echo ""
echo "Use this in your *CD deploy workflow*:"
echo ""
echo "  role-to-assume: arn:aws:iam::$ACCOUNT_ID:role/$EKS_ROLE_NAME"
echo "  aws-region: $REGION"
echo ""
