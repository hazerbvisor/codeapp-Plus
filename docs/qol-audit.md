# CodeApp Plus QoL Audit

Audit target: the first VS Code-like QoL milestone in `project-context.md`.

This audit was performed against `main` before implementing new QoL work. The goal is to extend the existing Code App architecture rather than duplicate features it already has.

## Audit results

| QoL target | Baseline status | Evidence / notes | This PR |
| --- | --- | --- | --- |
| Better tabs | Partial | Existing tabs support open/close, `Cmd+1...9/0` switching, drag reordering, compact tab picker, and open-editor list. Bulk management actions were missing. | Adds Close Others, Close to the Right, and safe Close All to regular tabs, compact tabs, and Explorer Open Editors. |
| Split editor | Missing / architectural | The current UI exposes one active editor implementation/model at a time. A real split requires editor-group state and multiple editor surfaces. | Deferred to a dedicated PR. |
| Command palette | Existing | `EditorView` already binds `Cmd+Shift+P` to Monaco's command palette. | No duplicate implementation. |
| Workspace handling | Existing / partial | `WorkSpaceStorage`, recent local folders, workspace switching, scene storage and editor restoration already exist. | No replacement. |
| Global search and replace | Partial | Workspace text search already exists through `TextSearchManager` and the Search activity-bar view. The current manager performs grep-based search only; there is no workspace replace flow. | Replace deferred to a dedicated PR. |
| Problems panel | Data pipeline existed, UI missing | Monaco markers are already decoded into `MainApp.problems`, but the built-in bottom panel did not expose them as a Problems list. | Adds a Problems panel with live count and click-to-open / jump-to-line behavior. |
| Breadcrumbs | Not found in inspected editor/top-bar path | No breadcrumb UI was found in the current editor/top-bar implementation. | Deferred. |
| Minimap | Existing | `EditorOptions.miniMapEnabled` already exists and defaults to `true`. | No duplicate implementation. |
| Better keyboard shortcuts | Existing / partial | Code App already has built-in shortcuts plus a searchable custom-shortcut settings UI backed by Monaco actions and GameController keyboard input. | Existing system preserved. |
| Better touch interaction | Existing / partial | Current UI already uses touch menus, hover effects, drag/drop, editor keyboard toolbar, and iPad-specific compact/regular layouts. | Tab context actions improve long-press/right-click usage. |
| Better file explorer | Existing / partial | File tree, open-editors section, file actions, remote providers, and Git decoration support are already present. | Open Editors gets the same tab-management actions as the tab strip. |
| Multi-window support | Existing | The app uses a SwiftUI `WindowGroup`, per-scene restoration state, and exposes a New Window action when multiple scenes are supported. | No duplicate implementation. |
| Better terminal UX | Existing / partial | Terminal manager, terminal instances, bottom-panel infrastructure, local/remote terminal providers and terminal options already exist. | Deferred until a focused terminal UX audit. |

## First implementation batch

The first QoL implementation intentionally stays small and low-risk:

1. VS Code-style tab management on regular tabs.
2. Equivalent tab actions in the compact iPad tab menu.
3. Equivalent actions in Explorer > Open Editors.
4. Bulk-close protection: modified editors are never silently discarded by the new bulk actions.
5. Built-in Problems panel using the existing Monaco diagnostics pipeline.
6. Clicking a problem opens its file, jumps to the diagnostic line, and focuses the editor.
7. Problems tab shows a live diagnostic count.

## Deferred work

Split editor and global replace are intentionally not bundled into this PR. Both touch deeper editor/workspace state and should be implemented and tested independently so existing editor, LSP, restoration and file-system behavior remains stable.
