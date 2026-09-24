#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resources_dir="$project_dir/Resources"
missing=0

require_path() {
    if [[ ! -e "$resources_dir/$1" ]]; then
        echo "Missing Resources/$1"
        missing=$((missing + 1))
    fi
}

for lib in ar link libLLVM lld clang nm dis llc lli opt; do
    require_path "llvm/$lib.xcframework/Info.plist"
done
for lib in files curl_ios awk text shell tar ios_system network_ios ssh_cmd openssl libssh2 lg2; do
    require_path "Term/$lib.xcframework/Info.plist"
done
for lib in harfbuzz freetype libpng; do
    require_path "PythonAux/$lib.xcframework/Info.plist"
done

require_path cpython/python3_ios.framework
require_path NodeJS/NodeMobile.xcframework/Info.plist
require_path PHP/php.xcframework/Info.plist
require_path NMSSH.xcframework/Info.plist
require_path Java/java-frameworks
require_path Java/tools.jar
require_path Java/java-8-openjdk
require_path python-lsp
require_path java-lsp
require_path monaco-textmate.bundle

if (( missing > 0 )); then
    echo "Missing $missing required build inputs. Run ./downloadFrameworks.sh, then check again." >&2
    exit 1
fi

echo 'Downloaded build inputs are present.'
