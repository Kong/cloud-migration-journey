# syntax = docker/dockerfile:1.2

FROM hashicorp/terraform:latest

# setup build cache
COPY ./automation/terraform_infra/ /tmp/kmj

RUN --mount=type=cache,target=/tmp/kmj/.terraform \
     cd /tmp/kmj && terraform init

# setup final content in image
COPY ./automation/terraform_infra/ /kmj

# copy terraform cache into place, cleanup temp cache in image and re-run init to ensure we have everything
RUN cp -R /tmp/kmj/.terraform /kmj/.terraform && ls -lh /kmj/.terraform && rm -rf /tmp/kmj && cd /kmj && terraform init

WORKDIR /kmj
