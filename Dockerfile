FROM hashicorp/terraform:latest

COPY ./automation/terraform_infra/ /kmj

RUN cd /kmj; terraform init;

WORKDIR /kmj
