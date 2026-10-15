#checkov:skip=CKV_DOCKER_2: HEALTHCHECK not required - AWS Lambda does not support HEALTHCHECK
#checkov:skip=CKV_DOCKER_3: USER not required - A non-root user is used by AWS Lambda

FROM public.ecr.aws/lambda/python:3.14.2026.10.14.14@sha256:bc6a64e4ceed5d8b4a6c0de0d7cc6996b1ef464927c18943c4265ed7a401b81a

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Observability Platform (observability-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Grafana API Key Rotator" \
      org.opencontainers.image.description="Creates or updates an API key for Amazon Managed Grafana and uploads it to AWS Secrets Manager" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/observability-platform-grafana-api-key-rotator"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

COPY --chown=nobody:nobody --chmod=0755 src/var/task/ ${LAMBDA_TASK_ROOT}

RUN <<EOF
rm -f /usr/local/bin/aws-lambda-rie
python -m pip install --no-cache-dir --requirement requirements-pip.txt
python -m pip install --no-cache-dir --requirement requirements.txt
EOF

CMD ["function.lambda_handler"]
