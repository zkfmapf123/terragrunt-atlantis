## 2025.2.14 dobby.lee
FROM ghcr.io/runatlantis/atlantis:latest

USER root

## 1. terragrunt 설치
RUN apk update && apk add --no-cache curl jq \
    && TERRAGRUNT_VERSION=$(curl -sL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name) \
    && curl -L -o /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
    && chmod +x /usr/local/bin/terragrunt

# 2. 환경 변수 설정
ENV ATLANTIS_GH_USER=leedonggyu
ENV ATLANTIS_REPO_ALLOWLIST=github.com/zkfmapf123/terragrunt-atlantis

RUN mkdir -p /home/atlantis/.atlantis/bin \
    && chown -R atlantis:atlantis /home/atlantis/.atlantis

COPY config/server.yaml /home/atlantis/.atlantis/server.yaml
RUN chown -R atlantis:atlantis /home/atlantis/.atlantis

USER atlantis

ENTRYPOINT ["atlantis", "server"]