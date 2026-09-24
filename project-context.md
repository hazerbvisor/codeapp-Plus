# CodeApp Plus — Project Context

Repository: https://github.com/hazerbvisor/codeapp-Plus

## Project Goal

CodeApp Plus is an iPadOS IDE project based on the open-source Code App project.

The goal is to turn Code App into a much more complete VS Code-like IDE for iPadOS by fixing its limitations instead of rebuilding an IDE from scratch.

The long-term target is a powerful, mostly local development environment on iPad with:

- VS Code-like editing and workflow
- Strong syntax highlighting
- Proper diagnostics and code correction
- Intelligent autocomplete
- Go to Definition / Rename / Hover / Quick Fix
- Local terminal and runtimes
- Git
- Native iOS/iPadOS compiling
- Swift and Objective-C development
- C/C++ development
- Local language servers
- Tasks and debugging
- Extension support where technically possible
- Unsigned IPA building directly on iPad

## Base Architecture

Keep Code App's existing strengths:

- Swift / SwiftUI native application
- Monaco Editor
- Existing filesystem support
- Git
- Terminal
- Node.js
- Python
- Java
- Existing C/C++ support
- Existing LSP architecture

Do not unnecessarily rewrite working Code App components.

Prefer extending and replacing limitations incrementally.

## Major Development Areas

### 1. VS Code QoL

Improve Code App until the workflow feels much closer to desktop VS Code.

Targets include:

- Better tabs
- Split editor
- Command palette
- Workspace handling
- Global search and replace
- Problems panel
- Breadcrumbs
- Minimap
- Better keyboard shortcuts
- Better touch interaction
- Better file explorer
- Multi-window support
- Better terminal UX

### 2. Language Intelligence

Add proper local language servers where feasible.

Targets include:

- clangd — C/C++/Objective-C
- SourceKit-LSP — Swift
- Pyright — Python
- TypeScript language server
- rust-analyzer
- Java language server

The goal is proper:

- Diagnostics
- Error/warning squiggles
- Autocomplete
- Hover documentation
- Go to Definition
- Find References
- Rename Symbol
- Formatting
- Quick Fix / code actions

### 3. Native iOS Toolchain

Integrate the toolchain from the XTool Mobile project.

Target architecture:

CodeApp Plus
→ terminal/build task
→ native Swift/Clang toolchain
→ iPhoneOS SDK
→ linker
→ .app bundle
→ unsigned IPA

The goal is to compile real ARM64 iOS/iPadOS applications directly on the iPad rather than relying only on WebAssembly compilers.

### 4. Terminal / Unix Environment

Improve the current Code App terminal/runtime environment.

Potentially integrate or reuse ARM64 iSH work where useful.

The terminal should eventually support development tools such as:

- shell
- git
- clang
- Swift
- Python
- Node
- Java
- package managers
- build scripts

### 5. Extensions

Later investigate:

- Open VSX
- VS Code web extensions
- WebWorker extension host
- Local Node extension host
- Compatibility layers for extensions requiring Node APIs

Do not assume every desktop VS Code extension can run on iPad.

### 6. Tasks and Debugging

Eventually implement VS Code-like:

- tasks.json
- launch.json
- build tasks
- Run / Debug
- breakpoints
- Debug Console
- Problems integration
- testing UI

## Development Philosophy

Work incrementally.

Do not replace large working sections without a strong technical reason.

Prioritize:

1. Stability
2. Compatibility with existing Code App features
3. Local/offline operation
4. iPad usability
5. VS Code-like behavior
6. Native iOS development capabilities

When modifying the repository:

- Inspect the current repository state first
- Understand existing architecture before changing it
- Preserve working functionality
- Make focused changes
- Prefer feature/fix branches and PRs rather than risky large rewrites
- Fix the first real compiler/runtime error rather than masking downstream errors

## Immediate Direction

Initial milestone:

1. Code App builds successfully
2. Improve editor QoL
3. Establish proper LSP infrastructure
4. Add Swift + SourceKit-LSP
5. Connect the XTool native iOS compiler/toolchain
6. Compile a simple Swift iOS app
7. Package it as an unsigned IPA

## Restore Phrase

When the user says:

> Continue CodeApp Plus

Restore this project context and continue from the latest repository state instead of starting over.
