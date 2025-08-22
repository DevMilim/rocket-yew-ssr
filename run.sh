#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Configuráveis por ENV
# -------------------------
TRUNK_CMD=${TRUNK_CMD:-trunk}
CARGO_CMD=${CARGO_CMD:-cargo}
FEATURES_WASM=${FEATURES_WASM:-hydration}
FEATURES_SSR=${FEATURES_SSR:-ssr}
DIST_DIR=${DIST_DIR:-dist}
SITE_DIR=${SITE_DIR:-site}
STATIC_SUBDIR=${STATIC_SUBDIR:-static}
BINARY_NAME=${BINARY_NAME:-app}
BUILD_PROFILE=${BUILD_PROFILE:-debug}   # debug | release | both
CLEAN_FIRST=${CLEAN_FIRST:-true}
USE_TMPDIR=${USE_TMPDIR:-false}

# -------------------------
# Checks básicos
# -------------------------
for cmd in "$TRUNK_CMD" "$CARGO_CMD" rsync; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERRO: '$cmd' não encontrado no PATH. Instale-o antes de rodar."
    exit 1
  fi
done

# -------------------------
# Helper: path do binário para um profile
# -------------------------
binary_path_for_profile() {
  local profile="$1" # debug or release
  if [ "$profile" = "release" ]; then
    echo "target/release/${BINARY_NAME}"
  else
    echo "target/debug/${BINARY_NAME}"
  fi
}

# -------------------------
# Função build wasm + server por profile
# -------------------------
build_once() {
  local profile="$1" # debug or release
  echo "--> Build wasm ($profile)"
  if [ "$profile" = "release" ]; then
    $TRUNK_CMD build --release --no-default-features --features "$FEATURES_WASM"
  else
    $TRUNK_CMD build --no-default-features --features "$FEATURES_WASM"
  fi

  echo "--> Build server ($profile)"
  if [ "$profile" = "release" ]; then
    $CARGO_CMD build --release --no-default-features --features "$FEATURES_SSR"
  else
    $CARGO_CMD build --no-default-features --features "$FEATURES_SSR"
  fi
}

# -------------------------
# Executa builds conforme BUILD_PROFILE
# -------------------------
case "$BUILD_PROFILE" in
  debug)
    build_once debug
    ;;
  release)
    build_once release
    ;;
  both)
    build_once debug
    build_once release
    ;;
  *)
    echo "BUILD_PROFILE inválido: $BUILD_PROFILE. Use debug|release|both"
    exit 1
    ;;
esac

# -------------------------
# Prepara site dir
# -------------------------
if [ "$USE_TMPDIR" = "true" ]; then
  SITE_DIR=$(mktemp -d /tmp/site.XXXX)
  echo "Usando tmp dir: $SITE_DIR (será removido ao finalizar)"
fi

if [ "$CLEAN_FIRST" = "true" ]; then
  rm -rf "$SITE_DIR"
fi

mkdir -p "$SITE_DIR/$STATIC_SUBDIR"

if [ ! -f "$DIST_DIR/index.html" ]; then
  echo "ERRO: $DIST_DIR/index.html não encontrado. Rode build do frontend primeiro."
  exit 1
fi

cp "$DIST_DIR/index.html" "$SITE_DIR/index.html"
rsync -a --delete --exclude='index.html' "$DIST_DIR/" "$SITE_DIR/$STATIC_SUBDIR/"

# -------------------------
# Copia binários conforme profile
# -------------------------
# Se BUILD_PROFILE=both, copia debug -> app-debug, release -> app-release e executa release.
# Se BUILD_PROFILE=release, copia release -> app and executa.
# Se BUILD_PROFILE=debug, copia debug -> app and executa.
if [ "$BUILD_PROFILE" = "both" ]; then
  dbg_bin=$(binary_path_for_profile debug)
  rel_bin=$(binary_path_for_profile release)

  if [ ! -x "$dbg_bin" ]; then
    echo "ERRO: binário debug não encontrado em $dbg_bin"
    exit 1
  fi
  if [ ! -x "$rel_bin" ]; then
    echo "ERRO: binário release não encontrado em $rel_bin"
    exit 1
  fi

  cp "$dbg_bin" "$SITE_DIR/${BINARY_NAME}-debug"
  cp "$rel_bin" "$SITE_DIR/${BINARY_NAME}-release"
  chmod +x "$SITE_DIR/${BINARY_NAME}-debug" "$SITE_DIR/${BINARY_NAME}-release"

  echo "Copiados: ${BINARY_NAME}-debug e ${BINARY_NAME}-release (executando release por padrão)"
  exec_name="${BINARY_NAME}-release"

elif [ "$BUILD_PROFILE" = "release" ]; then
  rel_bin=$(binary_path_for_profile release)
  if [ ! -x "$rel_bin" ]; then
    echo "ERRO: binário release não encontrado em $rel_bin"
    exit 1
  fi
  cp "$rel_bin" "$SITE_DIR/${BINARY_NAME}"
  chmod +x "$SITE_DIR/${BINARY_NAME}"
  exec_name="${BINARY_NAME}"

else
  dbg_bin=$(binary_path_for_profile debug)
  if [ ! -x "$dbg_bin" ]; then
    echo "ERRO: binário debug não encontrado em $dbg_bin"
    exit 1
  fi
  cp "$dbg_bin" "$SITE_DIR/${BINARY_NAME}"
  chmod +x "$SITE_DIR/${BINARY_NAME}"
  exec_name="${BINARY_NAME}"
fi

# -------------------------
# Env para debug
# -------------------------
export RUST_BACKTRACE=${RUST_BACKTRACE:-1}
export RUST_LOG=${RUST_LOG:-info}

# -------------------------
# Inicia servidor
# -------------------------
echo "--> Iniciando servidor em $SITE_DIR usando $exec_name"
cd "$SITE_DIR"

# Execução em foreground (útil pra dev)
./"$exec_name"
rc=$?

# Opcional: limpar tmpdir
if [ "$USE_TMPDIR" = "true" ]; then
  rm -rf "$SITE_DIR"
fi

exit $rc
