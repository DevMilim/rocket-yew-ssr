#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "1) building client (trunk release)"
# se você usa features, ajuste --no-default-features/--features
trunk build --release --no-default-features --features hydration --public-url ./ || { echo "trunk build failed"; exit 1; }

echo "2) building server (cargo release)"
cargo build --release --no-default-features --features ssr || { echo "cargo build failed"; exit 1; }

echo "3) preparing site folder"
rm -rf target/site
mkdir -p target/site/static
mv dist/index.html target/site/index.html || true
cp -r dist/* target/site/static/
# index.html normalmente em dist/index.html — copie pro root se quiser servir direto

echo "4) copying server binary"
BIN_NAME="app" # ajuste para o nome do bin no Cargo.toml
cp target/release/$BIN_NAME target/site/

echo "5) packaging"
cd target
tar -czf release-site.tar.gz -C site .

echo "Done: release-site.tar.gz (contém site/ binary)"
