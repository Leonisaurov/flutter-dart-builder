# Repositorio-runner de builds Flutter/Dart

## 1. Qué es

Este repositorio es un **runner de builds**: compila proyectos Flutter o Dart usando **GitHub Actions** (runners `ubuntu-latest`), para builds que en Termux/Android son inviables por limitaciones de memoria, SDK o tiempo.

Un **push** a este repo (rama `main` o `master`), o lanzar `./run-build.sh` manualmente, dispara el workflow [`build-dart-flutter.yml`](.github/workflows/build-dart-flutter.yml), que:

1. obtiene el código fuente (según `checkout.conf`),
2. ejecuta el build (según `build.sh`),
3. publica los artefactos resultantes.

## 2. Cómo funciona (flujo)

El workflow hace lo siguiente en orden:

1. **Checkout de ESTE repositorio** (el runner).
2. **Lee `checkout.conf`** y valida que `REPO_URL` no esté vacío.
3. **Obtiene el código fuente**:
   - Si `REPO_URL` empieza por `./`, copia ese directorio local (commiteado en este repo) a `src/`.
   - Si no, clona el repositorio remoto (público) con `git clone --depth 1`, usando `BRANCH` si está definido.
4. **Instala el Flutter SDK** (canal `stable`).
5. **Ejecuta `build.sh`** dentro del código fuente clonado (`src/`).
6. **Sube los artefactos** del workflow (nombre: `build-artifacts`, ruta: `artifacts/**`).
7. **Crea GitHub Releases** según `releases.conf` (solo si hay archivos que coincidan con los patrones).

## 3. Estructura de archivos

| Archivo | Propósito |
|---|---|
| `.github/workflows/build-dart-flutter.yml` | Definición del workflow de GitHub Actions: checkout del runner, lectura de `checkout.conf`, obtención del fuente, instalación de Flutter SDK, ejecución de `build.sh`, subida de artefactos y creación de releases. |
| `checkout.conf` | Configura la **fuente del código** a construir: `REPO_URL` (URL remota o `./directorio` local) y opcionalmente `BRANCH`. |
| `build.sh` | Define el **comando de construcción**; se ejecuta dentro del proyecto fuente. Copia los artefactos a `$GITHUB_WORKSPACE/artifacts/`. |
| `releases.conf` | Define qué **GitHub Releases** se crean por build (formato `nombre=patrón_glob`). |
| `run-build.sh` | Script local (Termux) para **lanzar el build sin hacer push**: dispara el workflow, lo monitoriza y muestra el resumen. |
| `.gitignore` | Excluye `src/` y `artifacts/` del control de versiones (no se commitean). |

## 4. Dos modos de fuente

Solo se usa **un modo a la vez**, definido por `REPO_URL` en `checkout.conf`.

### Modo remoto

```
REPO_URL=https://github.com/usuario/proyecto.git
```

- Clona el **último commit** del repositorio público (rama por defecto, o la indicada en `BRANCH`).
- Al modificar el repositorio fuente (hacer push allí) **NO** se recompila automáticamente: hay que lanzar `./run-build.sh` desde este runner.

### Modo local

```
REPO_URL=./mi_app
```

- Usa un **directorio dentro de este mismo repositorio** (debe estar commiteado).
- Al modificar ese directorio y pushear a este repo, el workflow lo compila directamente.

## 5. Uso paso a paso

### Paso 1: editar `checkout.conf`

Pon la URL del repositorio fuente o un directorio local:

```bash
# Modo remoto
REPO_URL=https://github.com/usuario/proyecto.git

# o modo local
REPO_URL=./mi_app
```

### Paso 2: editar `build.sh`

Escribe tu comando de construcción (ejemplos en la sección [Ejemplos de `build.sh`](#8-ejemplos-de-buildsh)). **Importante**: copia los artefactos a `$GITHUB_WORKSPACE/artifacts/` para que el workflow los suba y/o los use en `releases.conf`.

### Paso 3 (opcional): definir releases en `releases.conf`

Formato `nombre=glob`:

```
release-apk=artifacts/*.apk
```

- El tag se genera automáticamente: `<nombre>-<fecha-hora UTC>`.
- El release **solo se crea si hay archivos** que coincidan con el patrón.

### Paso 4: lanzar el build

- **Con push**: `git push` a `main`/`master` → el workflow corre automáticamente.
- **Sin push**: `./run-build.sh` → lanza el build con el último commit sin necesidad de commitear ni pushear. Esto es clave en el modo remoto: modificas el repositorio fuente, haces push allí, y desde el runner lanzas `./run-build.sh`.

## 6. `run-build.sh`

Script local que **dispara el workflow manualmente** (`workflow_dispatch`) y lo sigue de principio a fin:

1. Lee `checkout.conf` para mostrar el repositorio fuente configurado.
2. Lanza el workflow con `gh workflow run build-dart-flutter.yml`.
3. Detecta el run nuevo comparando los IDs de runs anteriores con `gh run list`.
4. Lo monitoriza con `gh run watch` (salida de error si falla).
5. Muestra el resumen con `gh run view`.

Uso:

```bash
./run-build.sh [ref]
```

- `ref`: rama/tag del **repositorio-runner** contra la que lanzar el workflow (opcional; por defecto la rama por defecto).
- **No requiere commit ni push**: el workflow ya está en tu última versión pusheada y hace checkout del último commit del fuente.

Requisito: **`gh` instalado y autenticado** en tu entorno local.

## 7. Dónde están los resultados

- **Pestaña Actions** de este repo → run correspondiente → sección **Artifacts** → `build-artifacts` (descargable como ZIP).
- **GitHub Releases** de este repo (si configuraste `releases.conf`).

## 8. Ejemplos de `build.sh`

### Flutter (APK release)

```bash
flutter pub get
flutter build apk --release
mkdir -p "$GITHUB_WORKSPACE/artifacts"
cp build/app/outputs/flutter-apk/*.apk "$GITHUB_WORKSPACE/artifacts/"
```

### Dart puro (ejecutable nativo)

```bash
dart pub get
dart compile exe bin/main.dart -o myapp
mkdir -p "$GITHUB_WORKSPACE/artifacts"
cp myapp "$GITHUB_WORKSPACE/artifacts/"
```

## 9. Notas / troubleshooting

- **El primer push fallará a propósito** si `REPO_URL` está vacío: es la validación del workflow (paso "Leer checkout.conf"). Edita `checkout.conf` primero.
- El runner trae **Android SDK + NDK + Java preinstalados**: no hay que instalar nada para builds de Flutter Android.
- **iOS requiere un runner macOS**: fuera del alcance de este template.
- Los **repositorios fuente privados NO están soportados** (solo públicos o locales): el workflow clona sin credenciales.
- `src/` y `artifacts/` están en `.gitignore`: **no se commitean** (el workflow los crea/usa en cada run).
