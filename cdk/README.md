# Interacting Bear Static Website CDK Deployment

This CDK project deploys the infrastructure for the Interacting Bear static website at `interactingbear.jackjapar.com`.

## Infrastructure Components

- **S3 Bucket**: Stores the static website files
- **CloudFront Distribution**: CDN for global content delivery
- **SSL Certificate**: Automatic SSL certificate for the custom domain
- **Route53 Record**: DNS record pointing to CloudFront distribution

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. AWS CDK CLI installed (`npm install -g aws-cdk`)
3. Python 3.7+
4. The `jackjapar.com` domain already configured in Route53

## Setup and Deployment

1. **Install CDK dependencies:**
   ```bash
   cd cdk
   python3 -m venv .venv
   source .venv/bin/activate
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

2. **Bootstrap CDK (first time only):**
   ```bash
   cdk bootstrap
   ```

3. **Deploy the stack:**
   ```bash
   cdk deploy
   ```

4. **Manual Website Upload:**
   After deployment, upload your website files from `./build/web` to the S3 bucket:
   ```bash
   aws s3 sync ../build/web s3://interacting-bear-static-website --delete
   ```

5. **Invalidate CloudFront cache (if needed):**
   ```bash
   aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
   ```

## Stack Outputs

After deployment, you'll see:
- **BucketName**: S3 bucket name for manual uploads
- **DistributionId**: CloudFront distribution ID for cache invalidation
- **WebsiteURL**: Your website URL (https://interactingbear.jackjapar.com)

## Manual Upload Process

Since the website files are not automatically deployed by CDK, you'll need to:

1. Build your Flutter web app:
   ```bash
   flutter build web
   ```

2. Upload to S3:
   ```bash
   aws s3 sync ./build/web s3://interacting-bear-static-website --delete
   ```

3. Invalidate CloudFront cache:
   ```bash
   aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
   ```

## Security Features

- S3 bucket blocks all public access
- CloudFront uses Origin Access Control (OAC) for secure S3 access
- SSL/TLS certificate automatically provisioned and renewed
- HTTPS redirect enforced

## Cost Optimization

- CloudFront compression enabled
- Optimized caching policies
- Versioned S3 bucket for backup and rollback capabilities
