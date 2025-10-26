import json
from os import path as osp, remove
from shutil import rmtree
from textwrap import dedent

import pytest
from pytest_infrahouse import terraform_apply

from tests.conftest import (
    LOG,
)


@pytest.mark.parametrize(
    "aws_provider_version", ["~> 5.11", "~> 6.0"], ids=["aws-5", "aws-6"]
)
def test_module(
    service_network,
    aws_region,
    keep_after,
    test_role_arn,
    subzone,
    cleanup_ecs_task_definitions,
    aws_provider_version,
):
    terraform_root_dir = "test_data"

    terraform_dir = osp.join(terraform_root_dir, "registry")

    # Clean up state files to ensure fresh terraform init
    state_files = [
        osp.join(terraform_dir, ".terraform"),
        osp.join(terraform_dir, ".terraform.lock.hcl"),
    ]
    for state_file in state_files:
        try:
            if osp.isdir(state_file):
                rmtree(state_file)
            elif osp.isfile(state_file):
                remove(state_file)
        except FileNotFoundError:
            pass

    subnet_public_ids = service_network["subnet_public_ids"]["value"]
    subnet_private_ids = service_network["subnet_private_ids"]["value"]
    test_zone_id = subzone["subzone_id"]["value"]

    # Generate terraform.tf with specified AWS provider version
    with open(osp.join(terraform_dir, "terraform.tf"), "w") as fp:
        fp.write(
            dedent(
                f"""
                terraform {{
                  required_version = "~> 1.5"
                  //noinspection HILUnresolvedReference
                  required_providers {{
                    aws = {{
                      source = "hashicorp/aws"
                      version = "{aws_provider_version}"
                    }}
                  }}
                }}
                """
            )
        )

    with open(osp.join(terraform_dir, "terraform.tfvars"), "w") as fp:
        fp.write(f'region = "{aws_region}"\n')
        fp.write(f'zone_id = "{test_zone_id}"\n')
        fp.write(f"frontend_subnets = {json.dumps(subnet_public_ids)}\n")
        fp.write(f"backend_subnets = {json.dumps(subnet_private_ids)}\n")

        if test_role_arn:
            fp.write(f'role_arn = "{test_role_arn}"\n')

    with terraform_apply(
        terraform_dir,
        destroy_after=not keep_after,
        json_output=True,
    ) as tf_output:
        LOG.info(json.dumps(tf_output, indent=4))
        cleanup_ecs_task_definitions("terraform-registry")
