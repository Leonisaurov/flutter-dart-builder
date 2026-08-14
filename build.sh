#!/usr/bin/env bash
# ============================================================
# BUILD.SH — define el comando de construcción.
# ============================================================
# Este script se ejecuta DENTRO del repositorio fuente clonado
# (cwd = raíz del proyecto fuente). Edítalo con tu comando de build.
#
# Al final, copia los artefactos a $GITHUB_WORKSPACE/artifacts/
# para que el workflow los suba y/o los use en releases.conf.
# ============================================================
set -euo pipefail

# --- Ejemplo Flutter (APK release) ---
flutter pub get
flutter build apk --release
mkdir -p "$GITHUB_WORKSPACE/artifacts"
cp build/app/outputs/flutter-apk/*.apk "$GITHUB_WORKSPACE/artifacts/"

# --- Ejemplo Dart puro (ejecutable nativo) ---
# dart pub get
# dart compile exe bin/main.dart -o myapp
# mkdir -p "$GITHUB_WORKSPACE/artifacts"
# cp myapp "$GITHUB_WORKSPACE/artifacts/"
