from aws_cdk import (
    Stack,
    aws_s3 as s3,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as origins,
    aws_certificatemanager as acm,
    aws_route53 as route53,
    aws_route53_targets as targets,
    aws_iam as iam,
    CfnOutput,
    RemovalPolicy,
    Duration
)
from constructs import Construct

class StaticWebsiteStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, domain_name: str, hosted_zone_name: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Store parameters
        self.domain_name = domain_name
        self.hosted_zone_name = hosted_zone_name

        # Create S3 bucket for static website hosting
        website_bucket = s3.Bucket(
            self, "InteractingBearWebsiteBucket",
            bucket_name="interacting-bear-static-website",
            public_read_access=False,  # We'll use CloudFront for public access
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            removal_policy=RemovalPolicy.RETAIN,  # Keep bucket when stack is deleted
            versioned=True,
            cors=[
                s3.CorsRule(
                    allowed_methods=[s3.HttpMethods.GET, s3.HttpMethods.HEAD],
                    allowed_origins=["*"],
                    allowed_headers=["*"]
                )
            ]
        )

        # Look up the existing hosted zone for jackjapar.com
        hosted_zone = route53.HostedZone.from_lookup(
            self, "JackJaparHostedZone",
            domain_name=self.hosted_zone_name
        )

        # Create SSL certificate for interactingbear.jackjapar.com
        certificate = acm.Certificate(
            self, "InteractingBearCertificate",
            domain_name=self.domain_name,
            validation=acm.CertificateValidation.from_dns(hosted_zone)
        )

        # Create CloudFront Origin Access Control
        origin_access_control = cloudfront.S3OriginAccessControl(
            self, "InteractingBearOAC"
        )

        # Create CloudFront distribution
        distribution = cloudfront.Distribution(
            self, "InteractingBearDistribution",
            default_behavior=cloudfront.BehaviorOptions(
                origin=origins.S3BucketOrigin.with_origin_access_control(website_bucket, origin_access_control=origin_access_control),
                viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                allowed_methods=cloudfront.AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
                cached_methods=cloudfront.CachedMethods.CACHE_GET_HEAD_OPTIONS,
                cache_policy=cloudfront.CachePolicy.CACHING_OPTIMIZED,
                compress=True
            ),
            domain_names=[self.domain_name],
            certificate=certificate,
            minimum_protocol_version=cloudfront.SecurityPolicyProtocol.TLS_V1_2_2021,
            default_root_object="index.html",
            error_responses=[
                cloudfront.ErrorResponse(
                    http_status=404,
                    response_http_status=200,
                    response_page_path="/index.html",
                    ttl=Duration.minutes(30)
                ),
                cloudfront.ErrorResponse(
                    http_status=403,
                    response_http_status=200,
                    response_page_path="/index.html",
                    ttl=Duration.minutes(30)
                )
            ]
        )

        # Create Route53 record for the subdomain
        subdomain = self.domain_name.replace(f".{self.hosted_zone_name}", "")
        route53.ARecord(
            self, "InteractingBearAliasRecord",
            zone=hosted_zone,
            record_name=subdomain,
            target=route53.RecordTarget.from_alias(targets.CloudFrontTarget(distribution))
        )

        # Output important values
        CfnOutput(
            self, "BucketName",
            value=website_bucket.bucket_name,
            description="S3 Bucket name for the static website"
        )

        CfnOutput(
            self, "DistributionId",
            value=distribution.distribution_id,
            description="CloudFront Distribution ID"
        )

        CfnOutput(
            self, "DistributionDomainName",
            value=distribution.distribution_domain_name,
            description="CloudFront Distribution Domain Name"
        )

        CfnOutput(
            self, "WebsiteURL",
            value=f"https://{self.domain_name}",
            description="Website URL"
        )

        CfnOutput(
            self, "S3BucketWebsiteURL",
            value=f"s3://{website_bucket.bucket_name}",
            description="S3 bucket path for manual uploads"
        )
