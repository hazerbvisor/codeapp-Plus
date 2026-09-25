# CodeApp Plus — QoL Phase 3

This phase is stacked on top of `feature/qol-ui-licenses` / PR #7. It should be merged after PR #7, then retargeted to `main` if necessary.

## Implemented in this phase

### GitHub repository browser

The existing source-control clone UI already knew how to clone a Git URL, but users had to search or type repository URLs manually.

Phase 3 adds a repository-first workflow:

- **My Repos** automatically loads repositories accessible to the authenticated GitHub account.
- The list includes repositories where the account is an owner, collaborator, or organization member.
- **Add Public** keeps GitHub-wide public repository search.
- **Add Private** filters the authenticated repository list to private repositories the user can access.
- Repository lists are sorted by GitHub's `updated` ordering and support local filtering.
- The repository browser shows public/private state, fork state, owner/repository name, language, size, and clone action.
- Manual HTTPS/SSH URL cloning remains available under a secondary **Clone by URL** disclosure.
- The existing Git clone handler is reused; this phase does not replace SwiftGit2/local Git infrastructure.

### Authentication in this first pass

The initial implementation reuses the GitHub personal access token already stored by Code App under Version Control authentication.

This keeps the feature immediately usable without embedding a client secret. The intended follow-up is GitHub App authentication with OAuth/PKCE, while preserving the same repository-browser UI.

### Editor tab QoL

- Add **Close to the Left**.
- Add **Close Saved**.
- Mirror tab actions in the Explorer's Open Editors section.
- Add previous/next editor navigation helpers with wrap-around behavior.
- Preserve the existing protection against silently discarding modified files.

### Keyboard/navigation QoL

- `⌘⇧[` — previous editor.
- `⌘⇧]` — next editor.
- `⌃G` — Go to Line in Monaco.
- Add Previous Editor, Next Editor, and Go to Line to the top-bar overflow menu.
- Change the top-bar **Close All** action to use the unsaved-file-safe bulk close path.

## Next roadmap

### P0 — finish GitHub account integration

1. Register a CodeApp Plus GitHub App.
2. Implement OAuth/PKCE sign-in for iPadOS.
3. Store access credentials in Keychain.
4. Support GitHub App repository selection / permission refresh.
5. Replace the manual-PAT requirement for **My Repos** and **Add Private**.
6. Add account avatar, username, sign-out, and token-expiry handling.
7. Add organization filters and owned/collaborator/organization grouping.

### P0 — Workspace Search & Replace

The project already has workspace search, but not a complete replace workflow.

Planned:

- replacement input beside search,
- replace one match,
- replace all matches in one file,
- replace across workspace,
- confirmation/preview before bulk writes,
- refresh open editors and diagnostics after replacement.

### P0 — Quick Open (`⌘P`)

Build a native workspace file index and fuzzy picker:

- fuzzy filename/path matching,
- recent files ranked first,
- keyboard navigation,
- open in current/new tab,
- optional `:line` suffix,
- exclude `.git`, build output, and configurable ignored paths.

`⌘⇧P` remains the Monaco command palette.

### P1 — Breadcrumbs

Add a compact path/symbol bar above the editor:

- workspace-relative path,
- clickable parent folders,
- language-symbol breadcrumbs when the language service provides symbols,
- minimal layout on compact iPad widths.

### P1 — Split editor groups

A real split editor needs architectural work because the current app primarily drives one active editor surface/model.

Planned:

- horizontal/vertical editor groups,
- independent active tab per group,
- drag tabs between groups,
- per-group view-state restoration,
- LSP/diagnostic state shared safely across groups.

### P1 — Terminal UX

- clearer terminal tab management,
- rename terminals,
- duplicate/new terminal actions,
- better command history affordances,
- optional working-directory indicator,
- split terminal after editor-group architecture is stable.

### P1 — Source-control polish

- clone progress UI,
- recent cloned repositories,
- repository default-branch display,
- clearer authentication failures,
- GitHub pull-request and issue entry points,
- branch picker/search improvements,
- stash support if supported cleanly by the Git backend.

### P2 — Language intelligence

Continue the CodeApp Plus roadmap toward stronger native language services:

- clangd,
- SourceKit-LSP,
- Pyright,
- TypeScript language server,
- rust-analyzer,
- Java language server improvements.

### P2 — Native iOS build workflow

Integrate the XTool Mobile/native toolchain direction into normal CodeApp Plus tasks:

- Swift/Clang toolchain discovery,
- iPhoneOS SDK selection,
- build tasks,
- diagnostics parsing,
- `.app` generation,
- unsigned IPA packaging,
- optional handoff to external signing apps.

### P3 — Tasks, debugging, and compatible extensions

After build and LSP foundations are stable:

- VS Code-style task definitions,
- reusable build/run configurations,
- debugger/DAP investigation where iPadOS constraints allow it,
- web-compatible/OpenVSX extension investigation,
- extension permission/sandbox model.

## Merge/build order

1. Compile PR #7 (`feature/qol-ui-licenses`) in Codemagic and merge it.
2. Retarget this Phase 3 branch/PR from `feature/qol-ui-licenses` to `main`.
3. Compile Phase 3 in Codemagic.
4. Fix only the first real compiler/build error before addressing cascaded errors.
5. Merge Phase 3 after device testing of repository browsing, private clone authentication, tab actions, and keyboard shortcuts.
