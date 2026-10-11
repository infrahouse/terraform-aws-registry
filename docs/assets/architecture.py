#!/usr/bin/env python3
"""
Generate the architecture diagram for the terraform-aws-registry module.

Requirements:
    pip install diagrams

Usage:
    cd docs/assets
    python architecture.py

Output:
    architecture.png (in current directory)
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECS, EC2
from diagrams.aws.database import Dynamodb
from diagrams.aws.general import Users
from diagrams.aws.management import Cloudwatch
from diagrams.aws.network import ALB, Route53
from diagrams.aws.security import ACM, Cognito, IAMRole, SecretsManager
from diagrams.aws.storage import S3
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.iac import Terraform

fontsize = "16"

graph_attr = {
    "splines": "spline",
    "nodesep": "1.0",
    "ranksep": "1.5",
    "fontsize": fontsize,
    "fontname": "Roboto",
    "dpi": "200",
}

node_attr = {
    "fontname": "Roboto",
    "fontsize": fontsize,
}

edge_attr = {
    "fontname": "Roboto",
    "fontsize": fontsize,
}

with Diagram(
    "Terraform Registry Architecture",
    filename="architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
    outformat="png",
):
    admins = Users("\nAdmins\n(web UI)")
    terraform = Terraform("\nterraform init")
    release = GithubActions("\nModule release\nworkflow")

    dns = Route53("\nRoute 53\nregistry.<zone>")
    cert = ACM("\nACM\nCertificate")
    cognito = Cognito("\nCognito\nUser Pool")
    client_role = IAMRole("\nRegistry client\nrole (OIDC)")

    with Cluster("VPC"):
        with Cluster("Public Subnets"):
            lb = ALB("\nApplication\nLoad Balancer")

        with Cluster("Private Subnets"):
            with Cluster("Auto Scaling Group"):
                hosts = EC2("\nECS container\ninstances")
            tapir = ECS("\nTapir\ncontainers")

    bucket = S3("\nS3\nModule archives")
    tables = Dynamodb("\nDynamoDB\nModules, Providers,\nReports, DeployKeys")
    secret = SecretsManager("\nSecrets Manager\nCognito client\nsecret")
    logs = Cloudwatch("\nCloudWatch\nLogs")

    # Web UI: sign in through Cognito
    admins >> dns >> lb
    terraform >> dns
    cert - Edge(style="dashed", label="TLS") - lb
    lb >> hosts - tapir
    tapir >> Edge(style="dashed", label="OIDC") >> cognito
    admins >> Edge(style="dashed", label="sign in") >> cognito

    # Storage
    tapir >> Edge(label="metadata") >> tables
    tapir >> Edge(label="archives") >> bucket
    terraform >> Edge(style="dashed", label="pre-signed\ndownload") >> bucket
    tapir >> Edge(style="dashed", label="client secret") >> secret
    tapir >> Edge(style="dashed") >> logs

    # Publishing
    release >> Edge(label="assume role") >> client_role
    client_role >> Edge(label="read deploy key") >> tables
    release >> Edge(label="upload") >> dns
