# CodeApp Plus — Third-Party Notices

CodeApp Plus is a modified distribution of **Code App**. The original Code App source remains available under the MIT License and the original copyright notice is preserved in the repository `LICENSE` file.

This document is an inventory of major open-source components used by or bundled with CodeApp Plus. It is intended to make attribution and license discovery easier; it does not replace the authoritative license text shipped by each upstream project.

## Code App

**Project:** Code App  
**Copyright:** Copyright (c) 2021 Chung Shing Hin  
**License:** MIT  
**Source:** https://github.com/thebaselab/codeapp

The MIT license notice is preserved verbatim in the root `LICENSE` file and is also exposed from the in-app **Open Source & Licenses** screen.

## Bundled runtimes and native tooling

| Component | License / notice | Upstream |
| --- | --- | --- |
| CPython | Python Software Foundation License | https://github.com/python/cpython |
| LLVM / Clang / LLD | Apache-2.0 with LLVM Exceptions | https://github.com/llvm/llvm-project |
| OpenJDK 8 | GPL-2.0 with Classpath Exception; individual bundled files may carry additional notices | https://openjdk.org/ |
| Node.js | MIT; Node.js distributions also include notices for bundled third-party code | https://github.com/nodejs/node |
| PHP | PHP License 3.01; bundled third-party libraries retain their own licenses | https://github.com/php/php-src |
| ios_system | BSD-3-Clause | https://github.com/holzschu/ios_system |
| libssh2 | BSD-style license | https://github.com/libssh2/libssh2 |
| OpenSSL | License depends on the exact bundled OpenSSL release; preserve and consult the license shipped in that archive | https://github.com/openssl/openssl |
| libgit2 | GPL-2.0 with a linking exception | https://github.com/libgit2/libgit2 |
| NMSSH | MIT | https://github.com/NMSSH/NMSSH |

## Editor, UI, and language infrastructure

| Component | License / notice | Upstream |
| --- | --- | --- |
| Monaco Editor | MIT | https://github.com/microsoft/monaco-editor |
| Runestone | MIT | https://github.com/simonbs/Runestone |
| tree-sitter | MIT | https://github.com/tree-sitter/tree-sitter |
| TreeSitterLanguages | See upstream package and individual grammar licenses | https://github.com/simonbs/TreeSitterLanguages |
| ZIPFoundation | MIT | https://github.com/weichsel/ZIPFoundation |
| ZipArchive | MIT | https://github.com/ZipArchive/ZipArchive |
| Dynamic | MIT | https://github.com/mhdhejazi/Dynamic |
| MarkdownView | MIT | https://github.com/thebaselab/MarkdownView |
| FilesProvider / FileProvider fork | See upstream repository license | https://github.com/thebaselab/FileProvider |
| GCDWebServer fork | See upstream repository license | https://github.com/thebaselab/GCDWebServer |
| SwiftNIO | Apache-2.0 | https://github.com/apple/swift-nio |
| SwiftNIO Transport Services | Apache-2.0 | https://github.com/apple/swift-nio-transport-services |
| Swift Atomics | Apache-2.0 | https://github.com/apple/swift-atomics |
| Swift Collections | Apache-2.0 | https://github.com/apple/swift-collections |
| Swift System | Apache-2.0 | https://github.com/apple/swift-system |

## Themes and other assets

The upstream Code App acknowledgements also reference third-party themes, grammars, web assets, command-line utilities, and language-server resources. Those assets remain subject to their respective upstream licenses. When adding or updating a bundled component, update this inventory and keep the upstream license/notice files with the component whenever practical.

## Distribution checklist

Before publishing a CodeApp Plus binary or source release:

- Keep the root Code App MIT `LICENSE` notice unchanged.
- Keep this `THIRD_PARTY_NOTICES.md` file with source distributions.
- Keep the in-app **Open Source & Licenses** screen accessible.
- Preserve license/notice files that are included inside downloaded runtime archives and frameworks.
- Re-audit notices when a runtime, framework, package, theme, grammar, or language server is added or replaced.

This notice inventory is maintained as an engineering aid and is not legal advice.
