# CodeApp Plus QoL Phase 2

This batch starts from `main` after QoL phase 1 and the successful Codemagic device build.

## Audit findings

- The editor already supported basic tabs, drag reordering, keyboard switching, and bulk close actions, but the regular tab strip was a fixed `HStack`. With many files open, tabs could overflow rather than scroll.
- The Explorer Open Editors list already exposed **Show in Files App** and **Copy Relative Path**, but the regular editor-tab context menu did not.
- The Problems panel added in phase 1 exposed Monaco diagnostics but had no search or severity filtering.
- Settings still mixed upstream Code App support/App Store links with fork settings, which could send CodeApp Plus users to the wrong support channel.
- The repository preserved the original Code App MIT `LICENSE`, and upstream Code App already had a localized license acknowledgement page. CodeApp Plus did not yet expose the original MIT permission text directly in the fork-specific settings UI or maintain a fork-level third-party notice inventory.

## Implemented

### Editor tabs

- Make the regular tab strip horizontally scrollable.
- Automatically keep the active tab visible when switching files.
- Give tabs a bounded width so long file names do not dominate the editor chrome.
- Add a small active-tab accent indicator.
- Add **Copy Relative Path** and **Show in Files App** to the tab context menu.
- Improve the compact tab picker with a file icon and open-editor count.

### Problems panel

- Add text filtering across diagnostic message, owner, filename, and path.
- Add severity filtering for errors, warnings, info, and hints.
- Show per-filter counts.
- Add a dedicated no-match state and one-tap filter reset.
- Show the parent directory under each filename to disambiguate duplicate filenames.
- Tighten panel-tab typography and count badges.

### Settings / UI cleanup

- Add a CodeApp Plus identity card at the top of Settings.
- Reorganize appearance/editor/terminal/source-control sections without removing existing settings.
- Point issue reporting to `hazerbvisor/codeapp-Plus` rather than upstream support.
- Preserve a direct link to the original Code App project for attribution.
- Remove fork-inappropriate App Store review/support actions from the main settings flow.
- Add clearer icons to high-value navigation rows.

### Open-source notices

- Keep the original root MIT `LICENSE` unchanged.
- Add an in-app **Open Source & Licenses** screen.
- Show the original Code App copyright and full MIT license text in the binary UI.
- Add a major bundled-component inventory with license identifiers and upstream links.
- Add root `THIRD_PARTY_NOTICES.md` for source distributions and release checks.

## License note

The notice inventory is an engineering aid, not a legal opinion. Several bundled runtimes contain their own subcomponents and notice files. Those upstream notices should remain preserved when packaging or replacing runtime archives.

## Deferred

- Workspace-wide replace
- Split editor groups
- Breadcrumbs
- Larger terminal UX redesign

These remain better suited to separate PRs because they touch editor/workspace state or execution architecture rather than presentation-only QoL.
