//
//  tabs.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import UniformTypeIdentifiers

extension MainApp {
    /// Bulk tab actions deliberately refuse to discard modified editors.
    /// Single-tab close still uses `closeEditor`, which already presents the save prompt.
    @MainActor
    func closeEditorsRespectingUnsaved(
        _ candidates: [EditorInstance],
        preserving preservedEditor: EditorInstance? = nil
    ) {
        let candidateIDs = Set(candidates.map(\.id))
        let targets = editors.filter { candidateIDs.contains($0.id) }
        guard !targets.isEmpty else { return }

        let unsavedEditors = targets.compactMap { $0 as? TextEditorInstance }.filter { !$0.isSaved }
        guard unsavedEditors.isEmpty else {
            alertManager.showAlert(
                title: "Unsaved Changes",
                message: "Save or close modified files before using a bulk tab action.",
                content: AnyView(
                    Button("OK", role: .cancel) {}
                )
            )
            return
        }

        for editor in targets {
            if editors.contains(where: { $0.id == editor.id }) {
                closeEditor(editor: editor, force: true)
            }
        }

        if let preservedEditor,
            editors.contains(where: { $0.id == preservedEditor.id })
        {
            setActiveEditor(editor: preservedEditor)
        }
    }

    @MainActor
    func closeOtherEditors(keeping editor: EditorInstance) {
        closeEditorsRespectingUnsaved(
            editors.filter { $0.id != editor.id },
            preserving: editor
        )
    }

    @MainActor
    func closeEditorsToRight(of editor: EditorInstance) {
        guard let index = editors.firstIndex(where: { $0.id == editor.id }) else { return }
        let nextIndex = editors.index(after: index)
        guard nextIndex < editors.endIndex else { return }
        closeEditorsRespectingUnsaved(Array(editors[nextIndex...]), preserving: editor)
    }

    func editorsToRight(of editor: EditorInstance) -> [EditorInstance] {
        guard let index = editors.firstIndex(where: { $0.id == editor.id }) else { return [] }
        let nextIndex = editors.index(after: index)
        guard nextIndex < editors.endIndex else { return [] }
        return Array(editors[nextIndex...])
    }
}

struct CompactEditorTabs: View {
    @EnvironmentObject var App: MainApp

    var body: some View {
        Menu {
            if let activeEditor = App.activeEditor {
                Section(
                    (activeEditor as? EditorInstanceWithURL)?.pathAfterUUID ?? activeEditor.title
                ) {
                    Button(role: .destructive) {
                        App.closeEditor(editor: activeEditor)
                    } label: {
                        Label("Close Editor", systemImage: "xmark")
                    }
                }

                if App.editors.count > 1 {
                    Section("Tab Actions") {
                        Button {
                            App.closeOtherEditors(keeping: activeEditor)
                        } label: {
                            Label("Close Others", systemImage: "xmark.circle")
                        }

                        if !App.editorsToRight(of: activeEditor).isEmpty {
                            Button {
                                App.closeEditorsToRight(of: activeEditor)
                            } label: {
                                Label("Close to the Right", systemImage: "arrow.right.to.line")
                            }
                        }

                        Button(role: .destructive) {
                            App.closeEditorsRespectingUnsaved(App.editors)
                        } label: {
                            Label("Close All", systemImage: "xmark.rectangle.stack")
                        }
                    }
                }
            }

            Section("Open Editors") {
                ForEach(App.editors) { editor in
                    Button {
                        App.setActiveEditor(editor: editor)
                    } label: {
                        FileIcon(url: editor.title, iconSize: 12)
                        Text(editor.title)
                    }
                }
            }
        } label: {
            HStack {
                Text(App.activeEditor?.title ?? "")
                    .bold()
                    .lineLimit(1)
                    .foregroundColor(Color.init("T1"))

                if App.editors.count > 0 {
                    Image(systemName: "chevron.down.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .id(UUID())

    }
}

struct EditorTabs: View {
    @EnvironmentObject var App: MainApp

    @State private var dragging: EditorInstance?

    struct DragRelocateDelegate: DropDelegate {
        let item: EditorInstance
        @Binding var listData: [EditorInstance]
        @Binding var current: EditorInstance?

        func dropEntered(info: DropInfo) {
            if item != current, current != nil {
                let from = listData.firstIndex(of: current!)!
                let to = listData.firstIndex(of: item)!
                if listData[to].id != current!.id {
                    withAnimation {
                        listData.move(
                            fromOffsets: IndexSet(integer: from),
                            toOffset: to > from ? to + 1 : to)
                    }
                }
            }
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            return DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            self.current = nil
            return true
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(App.editors) { currentEditor in
                EditorTab(
                    currentEditor: currentEditor,
                    isActive: (App.activeEditor == currentEditor),
                    onOpenEditor: {
                        App.setActiveEditor(editor: currentEditor)
                    },
                    onCloseEditor: {
                        App.closeEditor(editor: currentEditor)
                    }
                )
                .onDrag {
                    self.dragging = currentEditor
                    return NSItemProvider(object: currentEditor.id.uuidString as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: DragRelocateDelegate(
                        item: currentEditor, listData: $App.editors, current: $dragging))
            }
        }
    }
}
