#!/usr/bin/env python3
import os
import aws_cdk as cdk
from static_website.static_website_stack import StaticWebsiteStack

app = cdk.App()

# Get environment variables for AWS account and region
account = os.getenv('CDK_DEFAULT_ACCOUNT')
region = os.getenv('CDK_DEFAULT_REGION', 'us-east-1')  # CloudFront requires certificates in us-east-1

StaticWebsiteStack(app, "InteractingBearStaticWebsiteStack",
    domain_name="interactingbear.jackjapar.com",
    hosted_zone_name="jackjapar.com",
    env=cdk.Environment(account=account, region=region),
    description="Static website deployment for Interacting Bear Flutter app"
)

app.synth()
