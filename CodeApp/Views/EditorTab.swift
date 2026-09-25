//
//  editorTab.swift
//  Code
//
//  Created by Ken Chung on 16/5/2021.
//

import SwiftUI

struct EditorTab: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager

    // TODO: Don't use ObservedObject because it leaks memory
    @ObservedObject var currentEditor: EditorInstance
    var isActive: Bool
    var onOpenEditor: () -> Void
    var onCloseEditor: () -> Void

    var index: Int {
        App.editors.firstIndex { $0 == currentEditor } ?? 0
    }

    private var editorURL: URL? {
        (currentEditor as? EditorInstanceWithURL)?.url
    }

    static private func keyForInt(int: Int) -> KeyEquivalent {
        if int < 10 {
            return KeyEquivalent.init(String(int).first!)
        }
        return KeyEquivalent.init("0")
    }

    private func openInFilesApp() {
        guard let editorURL else { return }
        openSharedFilesApp(
            urlString: editorURL.deletingLastPathComponent().absoluteString
        )
    }

    private func copyRelativePath() {
        guard let editorURL else { return }
        guard let baseURL = URL(string: App.workSpaceStorage.currentDirectory.url) else {
            return
        }
        UIPasteboard.general.string = editorURL.relativePath(from: baseURL)
        App.notificationManager.showInformationMessage("Relative path copied")
    }

    var body: some View {
        Group {
            HStack(spacing: 5) {
                FileIcon(url: currentEditor.title, iconSize: 12)
                Button(action: {
                    onOpenEditor()
                }) {
                    Group {
                        if let editorURL = editorURL,
                            let status = App.gitTracks[editorURL]
                        {
                            FileDisplayName(
                                gitStatus: status,
                                name: currentEditor.title, useAllSpaceAvailableHorizontally: false)
                        } else {
                            FileDisplayName(
                                gitStatus: nil, name: currentEditor.title,
                                useAllSpaceAvailableHorizontally: false)
                        }
                        if let textEditor = currentEditor as? TextEditorInstance,
                            textEditor.isDeleted
                        {
                            Text("(deleted)").italic()
                        }
                    }
                    .lineLimit(1)
                    .font(.system(size: 13, weight: isActive ? .medium : .regular))
                    .foregroundColor(
                        Color.init(id: isActive ? "tab.activeForeground" : "tab.inactiveForeground")
                    )
                }
                .keyboardShortcut(EditorTab.keyForInt(int: index + 1), modifiers: .command)

                Group {
                    if let textEditor = currentEditor as? TextEditorInstance,
                        !textEditor.isSaved
                    {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(
                                Color.init(
                                    id: isActive ? "tab.activeForeground" : "tab.inactiveForeground"
                                )
                            )
                            .frame(width: 18, height: 18)
                            .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .hoverEffect(.highlight)
                    } else if isActive {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(
                                Color.init(
                                    id: isActive ? "tab.activeForeground" : "tab.inactiveForeground"
                                )
                            )
                            .frame(width: 22, height: 22)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .hoverEffect(.highlight)
                .onTapGesture {
                    onCloseEditor()
                }
            }
            .frame(minWidth: 110, maxWidth: 220, minHeight: 40, maxHeight: 40)
            .padding(.horizontal, 8)
            .background(
                isActive
                    ? Color(id: "tab.activeBackground")
                    : Color.clear
            )
            .overlay(alignment: .bottom) {
                if isActive {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                }
            }
            .cornerRadius(9, corners: [.topLeft, .topRight])
        }
        .contextMenu {
            Button {
                onCloseEditor()
            } label: {
                Label("Close", systemImage: "xmark")
            }

            if App.editors.count > 1 {
                Button {
                    App.closeOtherEditors(keeping: currentEditor)
                } label: {
                    Label("Close Others", systemImage: "xmark.circle")
                }
            }

            if !App.editorsToRight(of: currentEditor).isEmpty {
                Button {
                    App.closeEditorsToRight(of: currentEditor)
                } label: {
                    Label("Close to the Right", systemImage: "arrow.right.to.line")
                }
            }

            if editorURL != nil {
                Divider()

                Button(action: copyRelativePath) {
                    Label("Copy Relative Path", systemImage: "doc.on.doc")
                }

                Button(action: openInFilesApp) {
                    Label("Show in Files App", systemImage: "folder")
                }
            }

            if !App.editors.isEmpty {
                Divider()
                Button(role: .destructive) {
                    App.closeEditorsRespectingUnsaved(App.editors)
                } label: {
                    Label("Close All", systemImage: "xmark.rectangle.stack")
                }
            }
        }
    }
}
