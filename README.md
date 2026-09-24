# Code App

Bringing desktop-like editing experience to iPad, available on [App Store](https://apps.apple.com/us/app/code-app/id1512938504) and [TestFlight](https://testflight.apple.com/join/EgZ8sE2P).

![Code App Screenshot](https://thebaselab.com/code/clang.png)

## About the repository

This repository contains the source code of the app. We also work on issues, listen to your feedback and publish our development plan here.

## Documentation

See [code.thebaselab.com](https://code.thebaselab.com)

## The Plan

Use [VS Code](https://github.com/microsoft/vscode) as a design template while providing key functionalities with [monaco-editor](https://github.com/microsoft/monaco-editor) and native code:

- Version Control (Git clone, commits, diff editor, push, pull and gutter indicator) ✅
- Embedded terminal (70+ commands available) ✅
- Local web development environment (Node + PHP) ✅
- Built in Python runtime ✅
- C/C++ Runtime with WebAssembly (with clang) ✅
- Local Java (OpenJDK) ✅
- SSH Support ✅
- [LSP](https://microsoft.github.io/language-server-protocol) support (Python & Java) ✅ 

## Building the project

1. `git clone https://github.com/hazerbvisor/codeapp-Plus`
2. `./downloadFrameworks.sh`
3. `./checkBuildInputs.sh` (checks downloaded files before building)
4. Open Code.xcodeproj in Xcode on macOS
5. Select the **Code App** scheme for a device, or **Code UI** for a simulator
6. Build with code signing configured for your developer account

For a command-line device build on macOS, use:

```sh
xcodebuild -project Code.xcodeproj -scheme 'Code App' -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

The framework downloader retains archives under the ignored `Resources/.downloads`
directory so interrupted runs can be resumed without discarding earlier downloads.
`checkBuildInputs.sh` reports absent framework files; it does not compile the app.
This repository currently has an Xcode project, not an XTool Mobile build
configuration. Building directly on iPad requires a separate XTool integration.

The source code of the built-in languages are hosted on these repositories.
| Language | Repository |
|-----------------|-------------------|
| Python 3.9.2 | [cpython](https://github.com/holzschu/cpython/tree/3.9)|
| Clang 14.0.0 | [llvm-project](https://github.com/holzschu/llvm-project)|
| PHP 8.3.2 | [php-src](https://github.com/bummoblizard/php-src/tree/PHP-8.3.2)|
| Node.js 18.19.0 | [nodejs-mobile](https://github.com/1Conan/nodejs-mobile)|
| OpenJDK 8 | [android-openjdk-build-multiarch](https://github.com/thebaselab/android-openjdk-build-multiarch)|
