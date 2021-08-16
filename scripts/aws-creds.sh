#!/usr/bin/env bash

USER_ID=$(aws sts get-caller-identity --output json)
AWS_USER=$(echo "${USER_ID}" | jq -r .Arn | awk -F/ '{print $2}')
aws_credentials=$(aws sts assume-role --role-arn arn:aws:iam::454661681615:role/test_role --role-session-name "$AWS_USER")

AWS_ACCESS_KEY_ID=$(echo "${CREDS}" | jq .Credentials.AccessKeyId | xargs)
AWS_SECRET_ACCESS_KEY=$(echo "${CREDS}" | jq .Credentials.SecretAccessKey | xargs)
AWS_SESSION_TOKEN=$(echo "${CREDS}" | jq .Credentials.SessionToken | xargs)