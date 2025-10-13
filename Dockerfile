#checkov:skip=CKV_DOCKER_2: HEALTHCHECK not required - AWS Lambda does not support HEALTHCHECK
#checkov:skip=CKV_DOCKER_3: USER not required - A non-root user is used by AWS Lambda

FROM public.ecr.aws/lambda/python:3.13.2025.10.12.13@sha256:2b00c9883624cadf45e7daf1953a7c4ef8bcd56238847c670d0c2aedd9926f5b

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Observability Platform (observability-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Grafana API Key Rotator" \
      org.opencontainers.image.description="Creates or updates an API key for Amazon Managed Grafana and uploads it to AWS Secrets Manager" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/observability-platform-grafana-api-key-rotator"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

COPY --chown=nobody:nobody --chmod=0755 src/var/task/ ${LAMBDA_TASK_ROOT}

RUN <<EOF
python -m pip install --no-cache-dir --requirement requirements-pip.txt
python -m pip install --no-cache-dir --requirement requirements.txt
EOF

CMD ["function.lambda_handler"]
