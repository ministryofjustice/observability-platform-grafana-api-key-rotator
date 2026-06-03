import os

import boto3
import botocore.exceptions

grafana_client = boto3.client("grafana")
secretsmanager_client = boto3.client("secretsmanager")
workspace_service_account_name = os.environ["WORKSPACE_SERVICE_ACCOUNT_NAME"]
workspace_api_key_ttl = (
    os.environ.get("WORKSPACE_API_KEY_TTL") or 1209600
)  # 1209600 is 14 days
workspace_id = os.environ["WORKSPACE_ID"]
secret_id = os.environ["SECRET_ID"]


def lambda_handler(event, context):  # pylint: disable=unused-argument
    # Find the service account ID by name
    accounts = grafana_client.list_workspace_service_accounts(workspaceId=workspace_id)
    service_account = next(
        (
            a
            for a in accounts["serviceAccounts"]
            if a["name"] == workspace_service_account_name
        ),
        None,
    )
    if service_account is None:
        raise ValueError(
            f"Service account '{workspace_service_account_name}' not found in workspace {workspace_id}"
        )

    service_account_id = service_account["id"]

    # Delete any existing tokens to avoid hitting limits
    existing_tokens = grafana_client.list_workspace_service_account_tokens(
        workspaceId=workspace_id,
        serviceAccountId=service_account_id,
    )
    for token in existing_tokens.get("serviceAccountTokens", []):
        try:
            grafana_client.delete_workspace_service_account_token(
                tokenId=token["id"],
                serviceAccountId=service_account_id,
                workspaceId=workspace_id,
            )
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "ResourceNotFoundException":
                pass
            else:
                raise e

    # Create a new token
    new_token = grafana_client.create_workspace_service_account_token(
        name="terraform",
        secondsToLive=workspace_api_key_ttl,
        serviceAccountId=service_account_id,
        workspaceId=workspace_id,
    )

    secretsmanager_client.update_secret(
        SecretId=secret_id,
        SecretString=new_token["serviceAccountToken"]["key"],
    )

    return {
        "statusCode": 200,
        "body": "Successfully updated AWS Secrets Manager secret",
    }
