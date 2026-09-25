//
//  editor.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import AVFoundation
import AVKit
import GameController
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private struct EditorBreadcrumbBar: View {
    @EnvironmentObject var App: MainApp

    private var components: [String] {
        guard let editor = App.activeEditor as? EditorInstanceWithURL else {
            return []
        }

        if let root = App.workSpaceStorage.currentDirectory._url {
            let rootComponents = root.pathComponents
            let fileComponents = editor.url.pathComponents

            if fileComponents.starts(with: rootComponents) {
                let relativeComponents = Array(fileComponents.dropFirst(rootComponents.count))
                let rootName = root.lastPathComponent
                let result = (rootName.isEmpty ? [] : [rootName]) + relativeComponents
                if !result.isEmpty {
                    return result
                }
            }
        }

        let fallback = editor.pathAfterUUID
            .split(separator: "/")
            .map(String.init)
        return fallback.isEmpty ? [editor.title] : fallback
    }

    var body: some View {
        if !components.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(Color.init(id: "activityBar.inactiveForeground"))
                                .accessibilityHidden(true)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: index == components.count - 1 ? "doc.text" : "folder")
                                .font(.system(size: 10))
                                .accessibilityHidden(true)
                            Text(component)
                                .lineLimit(1)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(
                            Color.init(
                                id: index == components.count - 1
                                    ? "panelTitle.activeForeground"
                                    : "panelTitle.inactiveForeground"
                            )
                        )
                    }
                }
                .padding(.horizontal, 10)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 27)
            .background(Color.init(id: "editor.background"))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.init(id: "panel.border"))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Breadcrumbs")
        }
    }
}

struct EditorView: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var preivewProviderManager: EditorProviderManager
    @EnvironmentObject var stateManager: MainStateManager

    @AppStorage("editorLightTheme") var editorLightTheme: String = "Default"
    @AppStorage("editorDarkTheme") var editorDarkTheme: String = "Default"
    @AppStorage("editorFontSize") var editorTextSize: Int = 14
    @SceneStorage("sidebar.visible") var isSideBarVisible: Bool = DefaultUIState.SIDEBAR_VISIBLE

    @State var targeted: Bool = false

    func onDropURL(url: URL) {
        // TODO: Determine whether file is directory
        _ = url.startAccessingSecurityScopedResource()
        App.openFile(url: url, alwaysInNewTab: true)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                EditorBreadcrumbBar()

                ZStack {
                    // Invisible buttons for creating keyboard shortcuts in SwiftUI
                    VStack {
                        Button("New File") {
                            stateManager.showsNewFileSheet.toggle()
                        }.keyboardShortcut("n", modifiers: [.command])

                        Button("Open File") {
                            stateManager.showsFilePicker.toggle()
                        }
                        .keyboardShortcut("o", modifiers: [.command])
                        .sheet(isPresented: $stateManager.showsFilePicker) {
                            DocumentPickerView()
                        }

                        Button("Save") {
                            App.saveCurrentFile()

                        }
                        .keyboardShortcut("s", modifiers: [.command])
                        .sheet(
                            isPresented: $stateManager.showsChangeLog,
                            content: {
                                ChangeLogView()
                            })

                        Button("Close Editor") {
                            if let activeEditor = App.activeEditor {
                                App.closeEditor(editor: activeEditor)
                            }
                        }
                        .keyboardShortcut("w", modifiers: [.command])
                        .sheet(isPresented: $stateManager.showsDirectoryPicker) {
                            DirectoryPickerView(
                                type: .directory,
                                onOpen: { url in
                                    App.loadFolder(url: url)
                                    isSideBarVisible = true
                                })
                        }

                        // Fast editor switching for hardware keyboards. The first nine
                        // open editors map to Command-1 through Command-9.
                        ForEach(0..<min(App.editors.count, 9), id: \.self) { index in
                            Button("Open Editor \(index + 1)") {
                                App.setActiveEditor(editor: App.editors[index])
                            }
                            .keyboardShortcut(
                                KeyEquivalent(String(index + 1).first!),
                                modifiers: [.command]
                            )
                        }
                    }.foregroundColor(.clear).font(.system(size: 1))

                    Color.init(id: "editor.background")

                    if !App.stateManager.isMonacoEditorInitialized {
                        EditorImplementationView(implementation: App.monacoInstance)
                            .overlay {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.init(id: "editor.background"))
                            }
                    } else if let editor = App.activeEditor {
                        ZStack {

                            VStack {
                                Button("Command Palette") {
                                    Task {
                                        await App.monacoInstance._toggleCommandPalatte()
                                    }
                                }
                                .keyboardShortcut("p", modifiers: [.command, .shift])

                                Button("Zoom in") {
                                    if self.editorTextSize < 30 {
                                        self.editorTextSize += 1
                                        App.monacoInstance.options.fontSize += 1
                                    }
                                }.keyboardShortcut("+", modifiers: [.command])

                                Button("Zoom out") {
                                    if self.editorTextSize > 10 {
                                        self.editorTextSize -= 1
                                        App.monacoInstance.options.fontSize -= 1
                                    }
                                }.keyboardShortcut("-", modifiers: [.command])
                            }.foregroundColor(.clear).font(.system(size: 1))

                            editor.view
                        }
                    } else {
                        DescriptionText("You don't have any open editor.")
                    }

                    VStack {
                        InfinityProgressView(enabled: App.workSpaceStorage.editorIsBusy)
                        Spacer()
                    }

                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: Notification.Name("editor.focus"),
                        object: nil),
                    perform: { notification in
                        guard let sceneIdentifier = notification.userInfo?["sceneIdentifier"] as? UUID,
                            sceneIdentifier != App.sceneIdentifier
                        else { return }
                        Task {
                            await App.monacoInstance.blur()
                        }
                    }
                )
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: Notification.Name("terminal.focus"),
                        object: nil),
                    perform: { notification in
                        Task {
                            await App.monacoInstance.blur()
                        }
                    }
                )
                .onReceive(
                    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification),
                    perform: { data in
                        guard
                            !App.alertManager.isShowingAlert,
                            let beginRect = data.userInfo?["UIKeyboardFrameBeginUserInfoKey"]
                                as? CGRect,
                            let endRect = data.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect,
                            beginRect.origin.y != endRect.origin.y
                        else {
                            return
                        }

                        Task {
                            await App.saveCurrentFile()
                            if await App.monacoInstance.editorInFocus() {
                                await App.monacoInstance.blur()
                            }
                        }
                    }
                )
            }

        }.onDrop(
            of: [.url, .item], isTargeted: $targeted,
            perform: { providers in
                if let provider = providers.first {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        _ = provider.loadObject(
                            ofClass: URL.self,
                            completionHandler: { url, err in
                                if let url {
                                    onDropURL(url: url)
                                }
                            })
                    } else {
                        provider.loadItem(forTypeIdentifier: UTType.item.identifier) {
                            data, error in
                            if let url = data as? URL {
                                onDropURL(url: url)
                            }
                        }

                    }

                }
                return true
            })

    }
}
