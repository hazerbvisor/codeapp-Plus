#!/usr/bin/env bash
set -euo pipefail

# Keep downloaded archives and completed resources between builds. A failed
# download must never erase a previously working Resources directory.
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resources_dir="$project_dir/Resources"
cache_dir="$resources_dir/.downloads"
mkdir -p "$cache_dir"

fetch_archive() {
    local url="$1" destination="$2" marker="$3" name archive tmp stamp
    name="${url##*/}"
    archive="$cache_dir/$name"
    stamp="$cache_dir/$name.complete"

    if [[ -f "$stamp" && -e "$resources_dir/$marker" ]]; then
        echo "Already installed: $name"
        return
    fi

    if [[ ! -f "$archive" ]]; then
        tmp="$archive.part"
        rm -f "$tmp"
        echo "Downloading: $name"
        curl --fail --location --retry 3 --output "$tmp" "$url"
        mv "$tmp" "$archive"
    fi

    # Catch corrupt or truncated downloads before touching installed files.
    if ! unzip -tq "$archive" >/dev/null; then
        rm -f "$archive"
        echo "Invalid archive: $name; rerun to download it again" >&2
        return 1
    fi
    mkdir -p "$resources_dir/$destination"
    unzip -oq "$archive" -d "$resources_dir/$destination"
    if [[ ! -e "$resources_dir/$marker" ]]; then
        echo "Archive $name did not contain expected $marker" >&2
        return 1
    fi
    touch "$stamp"
}

fetch_archive 'https://github.com/bummoblizard/cpython/releases/download/1.0.1/cpython.zip' . cpython/python3_ios.framework

for lib in ar link libLLVM lld clang nm dis llc lli opt; do
    fetch_archive "https://github.com/thebaselab/llvm-project/releases/download/iOS-14/$lib.xcframework.zip" llvm "llvm/$lib.xcframework/Info.plist"
done

for lib in files curl_ios awk text shell tar ios_system; do
    fetch_archive "https://github.com/holzschu/ios_system/releases/download/v3.0.0/$lib.xcframework.zip" Term "Term/$lib.xcframework/Info.plist"
done

fetch_archive 'https://github.com/holzschu/network_ios/releases/download/v0.2/network_ios.xcframework.zip' Term Term/network_ios.xcframework/Info.plist
fetch_archive 'https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip' Term Term/ssh_cmd.xcframework/Info.plist
fetch_archive 'https://github.com/holzschu/libssh2-for-iOS/releases/download/v1.2/openssl.xcframework.zip' Term Term/openssl.xcframework/Info.plist
fetch_archive 'https://github.com/holzschu/libssh2-for-iOS/releases/download/v1.2/libssh2.xcframework.zip' Term Term/libssh2.xcframework/Info.plist
fetch_archive 'https://github.com/holzschu/libgit2/releases/download/ios_1.0/lg2.xcframework.zip' Term Term/lg2.xcframework/Info.plist

for lib in harfbuzz freetype libpng; do
    fetch_archive "https://github.com/holzschu/Python-aux/releases/download/1.0/$lib.xcframework.zip" PythonAux "PythonAux/$lib.xcframework/Info.plist"
done

fetch_archive 'https://github.com/1Conan/nodejs-mobile/releases/download/v18.19.0-ios/NodeMobile.xcframework.zip' NodeJS NodeJS/NodeMobile.xcframework/Info.plist
fetch_archive 'https://github.com/bummoblizard/php-src/releases/download/v0.3/php.xcframework.zip' PHP PHP/php.xcframework/Info.plist
fetch_archive 'https://github.com/thebaselab/NMSSH/releases/download/2.3.1-p5/NMSSH.xcframework.zip' . NMSSH.xcframework/Info.plist
fetch_archive 'https://github.com/thebaselab/android-openjdk-build-multiarch/releases/download/v0.2/java-8-zero-frameworks-tools-with-src.zip' Java Java/java-frameworks
fetch_archive 'https://github.com/thebaselab/codeapp-python/releases/download/2024.8.15/python-lsp.zip' . python-lsp
fetch_archive 'https://github.com/thebaselab/codeapp-monaco/releases/download/2025.9.20/monaco-textmate.bundle.zip' . monaco-textmate.bundle
fetch_archive 'https://github.com/thebaselab/codeapp-java/releases/download/2024.8.16/java-lsp.zip' . java-lsp

echo 'Framework downloads complete.'
