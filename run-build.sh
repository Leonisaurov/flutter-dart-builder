#!/usr/bin/env bash
# ============================================================
# RUN-BUILD.SH — lanza el build con el último commit del
# repositorio fuente configurado en checkout.conf.
# ============================================================
# Uso:  ./run-build.sh [ref]
#   - ref: rama/tag del REPOSITORIO RUNNER contra la que lanzar
#     el workflow (opcional; por defecto la rama por defecto).
#
# No requiere commit ni push: el workflow ya está en tu última
# versión pusheada y hace checkout del último commit del fuente.
# ============================================================
set -euo pipefail

WORKFLOW="build-dart-flutter.yml"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# Información del repositorio fuente configurado (solo informativo;
# no debe bloquear el lanzamiento si checkout.conf tuviera un fallo).
if [ -f checkout.conf ]; then
  # shellcheck disable=SC1091
  source ./checkout.conf || true
  echo "▶ Repositorio fuente: ${REPO_URL:-<vacío — edita checkout.conf>}"
  if [ -n "${BRANCH:-}" ]; then
    echo "▶ Rama: $BRANCH"
  fi
fi

# Último run workflow_dispatch existente, para detectar el nuevo por su id
BEFORE="$(gh run list --workflow="$WORKFLOW" --limit 50 --json databaseId,event -q 'first(.[] | select(.event == "workflow_dispatch") | .databaseId)' || true)"

REF_ARGS=()
if [ -n "${1:-}" ]; then
  REF_ARGS+=(--ref "$1")
fi
gh workflow run "$WORKFLOW" "${REF_ARGS[@]}"
echo "⏳ Workflow lanzado; esperando a que el run aparezca..."

RUN_ID=""
for _ in {1..30}; do
  sleep 2
  LATEST="$(gh run list --workflow="$WORKFLOW" --limit 50 --json databaseId,event -q 'first(.[] | select(.event == "workflow_dispatch") | .databaseId)' || true)"
  if [ -n "$LATEST" ] && [ "$LATEST" != "$BEFORE" ]; then
    RUN_ID="$LATEST"
    break
  fi
done
if [ -z "$RUN_ID" ]; then
  echo "::error::No se pudo detectar el nuevo run tras lanzar el workflow." >&2
  exit 1
fi

echo "▶ Run: $RUN_ID"
STATUS=0
if gh run watch "$RUN_ID" --exit-status; then
  echo "✅ Build completado con éxito. Artefactos y releases disponibles en GitHub."
else
  echo "❌ El build falló. Detalles a continuación:" >&2
  STATUS=1
fi
gh run view "$RUN_ID"
exit "$STATUS"
