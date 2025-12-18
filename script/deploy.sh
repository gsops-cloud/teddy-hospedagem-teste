#!/bin/bash

# Script para fazer deploy manual dos arquivos estáticos

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Iniciando deploy manual...${NC}"

# Verificar se AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não está instalado. Por favor, instale primeiro.${NC}"
    exit 1
fi

# Obter bucket name do Terraform ou usar variável de ambiente
if [ -f "../terraform/terraform.tfstate" ]; then
    cd ../terraform
    BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null || echo "")
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
    cd ..
else
    BUCKET_NAME="${S3_BUCKET_NAME}"
    DISTRIBUTION_ID="${CLOUDFRONT_DISTRIBUTION_ID}"
fi

if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}❌ Nome do bucket não encontrado!${NC}"
    echo -e "${YELLOW}💡 Execute 'terraform apply' primeiro ou configure S3_BUCKET_NAME${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Fazendo upload para s3://$BUCKET_NAME/${NC}"

# Sincronizar arquivos (exceto HTML)
aws s3 sync ./src/ s3://$BUCKET_NAME/ \
    --delete \
    --exclude "*.git*" \
    --cache-control "public, max-age=3600" \
    --exclude "*.html" \
    || exit 1

# HTML sem cache
aws s3 sync ./src/ s3://$BUCKET_NAME/ \
    --exclude "*" \
    --include "*.html" \
    --include "*.json" \
    --cache-control "public, max-age=0, must-revalidate" \
    || exit 1

echo -e "${GREEN}✅ Upload concluído!${NC}"

# Invalidar cache do CloudFront se Distribution ID estiver disponível
if [ -n "$DISTRIBUTION_ID" ]; then
    echo -e "${GREEN}🔄 Invalidando cache do CloudFront...${NC}"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    echo -e "${GREEN}✅ Invalidação criada: $INVALIDATION_ID${NC}"
else
    echo -e "${YELLOW}⚠️  Distribution ID não encontrado. Cache não foi invalidado.${NC}"
fi

echo -e "${GREEN}🎉 Deploy concluído com sucesso!${NC}"