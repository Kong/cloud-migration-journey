FROM hashicorp/terraform:latest

COPY ./automation/terraform_infra/ /kmj

RUN --mount=type=cache,target=/kmj/.terraform \
     cd /kmj && terraform init

WORKDIR /kmj
