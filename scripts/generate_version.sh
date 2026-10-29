#!/usr/bin/env bash
# Gera a versão da aplicação no formato yy.DDD.HHmm, baseado na data/hora
# da compilação atual.
#
# Formato:
#   yy  = ano, 2 digitos (ex: 26)
#   DDD = dia do ano, 3 digitos (001-366)
#   HH  = hora, 2 digitos (00-23)
#   mm  = minutos, 2 digitos (00-59)
#
# Exemplo: 26.302.1430  =>  29/out/2026, 14:30
set -euo pipefail

VERSION=$(date +%y.%j.%H%m)
echo "Versao gerada para a compilacao: $VERSION"

# Escreve o arquivo Dart com a constante da versao (sobrescrito a cada build).
mkdir -p lib/src
cat > lib/src/app_version.dart <<DART
/// Gerado automaticamente por scripts/generate_version.sh na compilacao.
/// Nao edite manualmente; sera regenerado a cada build.
const String appVersion = '$VERSION';
DART

echo "version=$VERSION"
