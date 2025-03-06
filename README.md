---

# SmartResume Terraform Project

SmartResume is a serverless application that allows users to sign in via AWS Cognito, save skills and job descriptions to DynamoDB, and generate tailored resumes stored in S3. This project uses Terraform to deploy the infrastructure, including CloudFront, API Gateway v2, Lambda functions, DynamoDB, S3, and Cognito.

## Prerequisites

- **AWS CLI**: Installed and configured with credentials (`aws configure`).
- **Terraform**: Installed (v1.5+ recommended).

## Project Structure

```
SmartResume/
├── API.tf                   # API Gateway v2 config
├── Cognito.tf              # Cognito User Pool config
├── DynamoDB.tf             # DynamoDB table config
├── Lambda.tf               # Lambda functions config
├── S3.tf                   # S3 buckets config (frontend and resumes)
├── save_profile_lambda.py  # Source for SaveProfileLambda
├── generate_resume_lambda.py  # Source for GenerateResumeLambda
├── save_profile_lambda.zip  # Pre-zipped SaveProfileLambda
├── generate_resume_lambda.zip  # Pre-zipped GenerateResumeLambda
├── index.html              # Frontend HTML
└── README.md               # This file
```

## Setup Instructions

### 1. Clone the Repository
- Clone or download the project:
  ```
  git clone <repository-url>
  cd SmartResume
  ```
- Or copy files into a local directory (e.g., `~/Desktop/Smart2/SmartResume`).

### 2. Deploy Infrastructure with Terraform
1. **Initialize Terraform**:
   ```
   terraform init
   ```

2. **Apply Terraform**:
   ```
   terraform apply
   ```
   - Approve the changes.

3. **Capture Outputs**:
   ```
   terraform output
   ```
   - Save these for `index.html`:
     - `cognito_domain`
     - `cognito_app_client_id`
     - `frontend_website_url`
     - `save_profile_endpoint`
     - `generate_resume_endpoint`

### 3. Update and Upload `index.html`
1. **Edit `index.html`**:
   - Update these lines with Terraform outputs:
     ```javascript
     const COGNITO_DOMAIN = "<cognito_domain>";
     const CLIENT_ID = "<cognito_app_client_id>";
     const REDIRECT_URI = "<frontend_website_url>";
     const SAVE_PROFILE_API = "<save_profile_endpoint>";
     const GENERATE_RESUME_API = "<generate_resume_endpoint>";
     ```


2. **Upload to S3**:
   - Apply Terraform to upload:
     ```
     terraform apply
     ```

3. **Invalidate CloudFront Cache (If Needed)**:
   - If the frontend doesn’t update:
     ```
     aws cloudfront create-invalidation --distribution-id <distribution-id> --paths "/*"
     ```
   - Replace `<distribution-id>` with your CloudFront ID (from `terraform output` or AWS Console).

## Troubleshooting
- **CORS Errors**: Verify `cors_configuration` in `API.tf` matches `frontend_website_url`.
- **500 Errors**: Check Lambda logs (`aws logs tail "/aws/lambda/<function-name>"`).
- **404 Errors**: Ensure DynamoDB table name (`UserProfiles`) matches Lambda code.

## Cleanup
- Destroy resources:
  ```
  terraform destroy
  ```

---

### Notes
- Replace `<distribution-id>` with your CloudFront ID.
- Adjust bucket names in `S3.tf` if different.
