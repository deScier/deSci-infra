> 🌎 Opções de Idioma:
>
> - Português Brasileiro (atual)
> - [English](../../README.md)

Este documento fornece uma visão detalhada do fluxo de trabalho de CI/CD configurado para a plataforma deScier. Aqui você encontrará uma explicação passo a passo de todo o processo, desde o push no repositório até a implantação na AWS, junto com um diagrama de fluxo para auxiliar na compreensão.

## Índice

- [Visão Geral](#visão-geral)
- [Diagrama de Fluxo](#diagrama-de-fluxo)
- [Fluxo de CI/CD](#fluxo-de-cicd)
  - [1. Push no Repositório](#1-push-no-repositório)
  - [2. Início do Fluxo do GitHub Actions](#2-início-do-fluxo-do-github-actions)
  - [3. Configuração do Ambiente de Build](#3-configuração-do-ambiente-de-build)
  - [4. Build e Push da Imagem Docker](#4-build-e-push-da-imagem-docker)
  - [5. Implantação no Amazon ECS](#5-implantação-no-amazon-ecs)

## Visão Geral

A plataforma deScier utiliza um pipeline de CI/CD automatizado para garantir que as alterações no código sejam continuamente integradas e implantadas de forma confiável. O processo é orquestrado pelo [GitHub Actions](https://github.com/deScier/deSci-platform/actions) e utiliza serviços AWS, incluindo [Amazon ECR (Elastic Container Registry)](https://aws.amazon.com/ecr/) e [Amazon ECS (Elastic Container Service)](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html).

## Diagrama de Fluxo

Para visualizar todo o processo, veja o diagrama de fluxo abaixo:

```mermaid
flowchart TD
    subgraph Desenvolvedor
        A[Push no Repositório] --> |branch: develop| B[Repositório GitHub]
        A2[Push no Repositório] --> |branch: main| B
    end

    subgraph "Fluxo do GitHub Actions"
        B --> |branch develop| C1[Dispara Workflow Dev]
        B --> |branch main| C2[Dispara Workflow Prod]

        subgraph "Fase de Configuração"
            C1 --> D1[Checkout do Repositório]
            C2 --> D2[Checkout do Repositório]
            D1 & D2 --> E[Configurar QEMU]
            E --> F[Configurar Docker Buildx]
        end

        subgraph "Autenticação AWS"
            F --> G[Configurar Credenciais AWS]
            G --> H[Login ECR]
            H --> I[Obter URI do Repositório ECR]
        end

        subgraph "Gerenciamento de Segredos"
            I --> J[Buscar Segredos do AWS Secrets Manager]
            J --> K[Criar arquivo .env]
        end

        subgraph "Build e Push Docker"
            K --> L[Build da Imagem Docker]
            L --> M[Tag da Imagem com URI ECR]
            M --> N[Push para Amazon ECR]
        end

        subgraph "Implantação ECS"
            N --> |develop| O1[Task Definition Dev]
            N --> |main| O2[Task Definition Prod]
            O1 --> P1[Atualizar Imagem Dev]
            O2 --> P2[Atualizar Imagem Prod]
            P1 --> Q1[Registrar Task Dev]
            P2 --> Q2[Registrar Task Prod]
            Q1 --> R1[Atualizar Serviço Dev]
            Q2 --> R2[Atualizar Serviço Prod]
            R1 & R2 --> S[Aguardar Estabilidade do Serviço]
        end
    end

    subgraph "Infraestrutura AWS"
        S --> T[Amazon ECR]
        T --> |develop| U1[Cluster ECS Dev]
        T --> |main| U2[Cluster ECS Prod]
        U1 --> V1[Serviço ECS Dev]
        U2 --> V2[Serviço ECS Prod]
        V1 --> W1[Tasks Dev]
        V2 --> W2[Tasks Prod]
        W1 --> X1[Containers Dev]
        W2 --> X2[Containers Prod]
    end

    subgraph "Acesso Público"
        X1 --> Y1[dev.desci.reviews]
        X2 --> Y2[platform.desci.reviews]
    end

    classDef setup fill:#fff,stroke:#333,color:#333,stroke-width:2px
    classDef aws fill:#ff9900,color:#000
    classDef container fill:#4065a9,color:#fff
    classDef domain fill:#70468c,color:#fff

    class A,A2,B setup
    class T,U1,U2,V1,V2,W1,W2 aws
    class L,M,N container
    class Y1,Y2 domain
```

## Fluxo de CI/CD

### 1. Push no Repositório

Quando os desenvolvedores fazem push de alterações para a branch `develop` do repositório `deSci-platform` no GitHub, isso dispara o pipeline de CI/CD.

### 2. Início do Fluxo do GitHub Actions

O [GitHub Actions](https://github.com/deScier/deSci-platform/actions) detecta o evento de push e inicia o workflow definido no arquivo [`.github/workflows/cd.yml`](https://github.com/deScier/deSci-platform/blob/main/.github/workflows/cd.yml). Este workflow automatiza todo o processo de build e implantação.

### 3. Configuração do Ambiente de Build

**a. Checkout do Código**

O primeiro passo é clonar o repositório para o ambiente de build:

```yaml
- name: Checkout do código
  uses: actions/checkout@v3
```

**b. Configuração do QEMU e Buildx**

Estes passos configuram o emulador [QEMU](https://www.qemu.org/) e o [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/) para permitir a construção de imagens Docker multi-plataforma:

```yaml
- name: Configurar QEMU
  uses: docker/setup-qemu-action@v2

- name: Configurar Docker Buildx
  uses: docker/setup-buildx-action@v2
```

**c. Configuração das Credenciais AWS**

Configura as credenciais AWS usando segredos armazenados no GitHub:

```yaml
- name: Configurar credenciais AWS
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}
```

**d. Login no Amazon ECR**

Autentica com o registro de contêineres Amazon ECR:

```yaml
- name: Login no Amazon ECR
  uses: aws-actions/amazon-ecr-login@v2
```

**e. Obtenção da URI do Repositório ECR**

Obtém a URI completa do repositório ECR onde a imagem Docker será enviada:

```yaml
- name: Obter URI do repositório ECR
  id: ecr
  run: |
    echo "::set-output name=uri::$(aws ecr describe-repositories --repository-names $ECR_REPOSITORY_DEV --query 'repositories[0].repositoryUri' --output text)"
```

**f. Obtenção dos Segredos do AWS Secrets Manager**

Obtém os segredos necessários para a aplicação e os salva em um arquivo `.env`:

```yaml
- name: Obter segredos do AWS Secrets Manager
  run: |
    aws secretsmanager get-secret-value --secret-id $ENV_SECRET_NAME_DEV --query SecretString --output text > .env
```

**Observação:** Os segredos são mantidos seguros e não são exibidos nos logs.

### 4. Build e Push da Imagem Docker

**a. Build da Imagem Docker**

A imagem Docker é construída usando o `Dockerfile`, passando o conteúdo do arquivo `.env` como argumento de build:

```yaml
- name: Build da imagem Docker
  run: |
    docker build --build-arg ENV_FILE="$(cat .env)" -t ${{ steps.ecr.outputs.uri }}:latest .
```

**b. Push para o Amazon ECR**

Após o build, a imagem é enviada para o Amazon ECR:

```yaml
- name: Push da imagem para o Amazon ECR
  run: |
    docker push ${{ steps.ecr.outputs.uri }}:latest
```

### 5. Implantação no Amazon ECS

**a. Atualização da Task Definition**

- Baixa a task definition atual do ECS:

```yaml
- name: Baixar task definition atual do ECS
  run: |
    aws ecs describe-task-definition --task-definition $ECS_TASK_DEV_NAME > task-definition.json
```

- Atualiza a imagem na task definition:

```yaml
- name: Atualizar imagem na task definition
  run: |
    sed -i 's#<IMAGE_NAME>#${{ steps.ecr.outputs.uri }}:latest#g' task-definition.json
```

- Registra a nova task definition no ECS:

```yaml
- name: Registrar nova task definition no ECS
  run: |
    aws ecs register-task-definition --cli-input-json file://task-definition.json
```

**b. Atualização do Serviço ECS**

Atualiza o serviço ECS para usar a nova task definition:

```yaml
- name: Atualizar serviço ECS
  uses: aws-actions/amazon-ecs-deploy-task-definition@v2
  with:
    task-definition: task-definition.json
    service: ${{ env.ECS_SERVICE_DEV }}
    cluster: ${{ env.ECS_CLUSTER_DEV }}
    wait-for-service-stability: true
```

**c. Logout do Amazon ECR**

Por segurança, faz logout do Amazon ECR:

```yaml
- name: Logout do Amazon ECR
  run: |
    docker logout ${{ steps.ecr.outputs.uri }}
```
