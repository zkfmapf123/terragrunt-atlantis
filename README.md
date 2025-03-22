# atlantis terragrunt

## 1. atlantis settings

- <a href="https://github.com/zkfmapf123/atlantis-fargate"> atlantis setting </a>

## 2. Dockerfile Setting

- arm64로 이미지 빌드

```sh
    docker buildx create --use && \
    docker buildx build --platform linux/amd64 -t [IMAGE_URL] . --push
```

## 3. Atlantis 설정

```sh
cd tg-atlantis && terraform apply
```

## 4. terragrunt 프로젝트 실행
