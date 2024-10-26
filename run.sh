#!/bin/bash

# Carrega as variáveis do arquivo .env
set -a
source .env
set +a

# Converte a string de availability_zones em uma lista
export TF_VAR_availability_zones=$(echo $TF_VAR_availability_zones | sed 's/^.\(.*\).$/[\1]/')

# Executa o comando Terraform passado como argumento
exec "$@"