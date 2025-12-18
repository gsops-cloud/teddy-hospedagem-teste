# Site Estático com CloudFront e S3

Solução de infraestrutura como código para hospedar um site estático na AWS usando Terraform e pipelines automatizados no GitHub Actions.

## Como Funciona

O projeto cria e gerencia uma infraestrutura completa na AWS:

1. **S3 Bucket**: Armazena os arquivos HTML, CSS, JavaScript e outros assets estáticos
2. **CloudFront Distribution**: CDN que distribui o conteúdo globalmente com cache otimizado
3. **Origin Access Identity (OAI)**: Garante que o S3 só seja acessível via CloudFront (segurança)
4. **Política do Bucket**: Permite acesso apenas do CloudFront ao bucket S3

### Fluxo de Deploy

```
Push para main/master → GitHub Actions detecta mudanças em src/
  ↓
Verifica se bucket existe → Sincroniza arquivos para S3
  ↓
Invalida cache do CloudFront → Site atualizado
```

### Fluxo de Infraestrutura

```
Terraform Apply → Cria S3, CloudFront, OAI e políticas
  ↓
State salvo no S3 → Permite destroy e gerenciamento contínuo
  ↓
Terraform Destroy → Remove todos os recursos criados
```

## Estrutura do Projeto

```
teddy-hospedagem/
├── terraform/              # Infraestrutura como código
│   ├── main.tf            # Recursos AWS (S3, CloudFront, políticas)
│   ├── variables.tf       # Variáveis configuráveis
│   └── outputs.tf         # Outputs (URLs, IDs)
├── src/                   # Arquivos estáticos do site
│   ├── index.html
│   └── 404.html
└── .github/workflows/     # Pipelines CI/CD
    ├── terraform.yml      # Apply/Destroy manual
    └── deploy.yml         # Deploy automático
```

## Configuração

### Secrets do GitHub (Settings > Secrets and variables > Actions)

**Obrigatórios:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `S3_BUCKET_NAME` (nome único globalmente)

**Opcionais:**
- `AWS_REGION` (padrão: `us-east-1`)
- `TERRAFORM_ENVIRONMENT` (padrão: `prod`)

## Uso

### 1. Criar Infraestrutura

GitHub Actions → Workflow "Terraform Infrastructure" → Ação "apply"

Cria todos os recursos AWS necessários e salva o state no S3.

### 2. Deploy Automático

Ao fazer push para `main`/`master` com mudanças em `src/`, o workflow:
- Verifica se o bucket existe
- Sincroniza arquivos para S3
- Invalida cache do CloudFront

### 3. Destruir Infraestrutura

GitHub Actions → Workflow "Terraform Infrastructure" → Ação "destroy"

Remove todos os recursos criados.

## Características Técnicas

- **Backend S3**: State do Terraform persistido no S3 para permitir destroy entre execuções
- **Importação Automática**: Detecta recursos existentes e importa para o state
- **Limpeza Automática**: Remove objetos do bucket antes do destroy
- **Cache Otimizado**: HTML sem cache, outros arquivos com cache de 1 hora
- **Segurança**: Bucket privado, acesso apenas via CloudFront

## Outputs

Após `terraform apply`:
- `cloudfront_url`: URL do site (https://...)
- `bucket_name`: Nome do bucket S3
- `cloudfront_distribution_id`: ID da distribuição