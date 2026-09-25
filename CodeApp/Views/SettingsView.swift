//
//  SettingsView.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var themeManager: ThemeManager

    @AppStorage("suggestionEnabled") var suggestionEnabled: Bool = true
    @AppStorage("editorShowKeyboardButtonEnabled") var editorShowKeyboardButtonEnabled: Bool = true
    @AppStorage("preferredColorScheme") var preferredColorScheme: Int = 0
    @AppStorage("explorer.showHiddenFiles") var showHiddenFiles: Bool = false
    @AppStorage("explorer.confirmBeforeDelete") var confirmBeforeDelete = false
    @AppStorage("alwaysOpenInNewTab") var alwaysOpenInNewTab: Bool = false
    @AppStorage("stateRestorationEnabled") var stateRestorationEnabled = true
    @AppStorage("communityTemplatesEnabled") var communityTemplatesEnabled = true
    @AppStorage("remoteShouldResolveHomePath") var remoteShouldResolveHomePath = false
    @AppStorage("editorOptions") var editorOptions: CodableWrapper<EditorOptions> = .init(
        value: EditorOptions())
    @AppStorage("terminalOptions") var terminalOptions: CodableWrapper<TerminalOptions> = .init(
        value: TerminalOptions())
    @AppStorage("runeStoneEditorEnabled") var runeStoneEditorEnabled: Bool = false
    @AppStorage("languageServiceEnabled") var languageServiceEnabled: Bool = true

    @State var showAllFonts = false
    @State var showsEraseAlert: Bool = false
    @State var showReceiptInformation: Bool = false

    let colorSchemes = ["Automatic", "Dark", "Light"]

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        NavigationView {
            Form {
                // TODO: Rework Editor / Terminal settings to support multiple scenes

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("CodeApp Plus")
                                .font(.headline)
                            Text("A community fork of Code App for a more capable iPad IDE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                Group {
                    Section(header: Text("Appearance")) {
                        NavigationLink(
                            destination:
                                SettingsThemeConfiguration()
                                .environmentObject(App)
                        ) {
                            Label("Themes", systemImage: "paintpalette")
                        }

                        Picker(selection: $preferredColorScheme, label: Label("Color Scheme", systemImage: "circle.lefthalf.filled")) {
                            ForEach(0..<colorSchemes.count, id: \.self) {
                                Text(self.colorSchemes[$0])
                            }
                        }

                        Stepper(
                            "\(NSLocalizedString("Editor Font Size", comment: "")) (\(editorOptions.value.fontSize))",
                            value: $editorOptions.value.fontSize, in: 10...30
                        )

                        Stepper(
                            "\(NSLocalizedString("Console Font Size", comment: "")) (\(terminalOptions.value.fontSize))",
                            value: $terminalOptions.value.fontSize, in: 8...24)
                    }

                    Section(header: Text(NSLocalizedString("Editor", comment: ""))) {

                        Toggle("settings.editor.vim.enabled", isOn: $editorOptions.value.vimEnabled)

                        NavigationLink(
                            destination: SettingsFontPicker(
                                showAllFonts: $showAllFonts,
                                onFontPick: { descriptor in
                                    CTFontManagerRequestFonts([descriptor] as CFArray) { _ in
                                        editorOptions.value.fontFamily =
                                            descriptor.object(forKey: .family) as! String
                                    }
                                }
                            ).toolbar {
                                Button("Show all fonts") {
                                    showAllFonts.toggle()
                                }

                                Button("settings.editor.font.reset") {
                                    editorOptions.value.fontFamily = "Menlo"
                                }
                                .disabled(editorOptions.value.fontFamily == "Menlo")
                            },
                            label: {
                                HStack {
                                    Label("Font", systemImage: "textformat")
                                    Spacer()
                                    Text(editorOptions.value.fontFamily)
                                        .foregroundColor(.gray)
                                }
                            }
                        )

                        Toggle("settings.editor.font.show_all_fonts", isOn: $showAllFonts)

                        Toggle(
                            "settings.editor.font.ligatures",
                            isOn: $editorOptions.value.fontLigaturesEnabled)

                        NavigationLink(
                            destination:
                                SettingsKeyboardShortcuts()
                                .environmentObject(App)
                        ) {
                            Label("Custom Keyboard Shortcuts", systemImage: "keyboard")
                        }

                        Stepper(
                            "\(NSLocalizedString("Tab Size", comment: "")) (\(editorOptions.value.tabRenderSize))",
                            value: $editorOptions.value.tabRenderSize, in: 1...8
                        )

                        Toggle("Read-only Mode", isOn: $editorOptions.value.readOnly)
                        Toggle("UI State Restoration", isOn: self.$stateRestorationEnabled)

                        Toggle(
                            NSLocalizedString("Bracket Completion", comment: ""),
                            isOn: $editorOptions.value.autoClosingBrackets
                        )

                        Toggle(
                            NSLocalizedString("Mini Map", comment: ""),
                            isOn: $editorOptions.value.miniMapEnabled
                        )

                        Toggle(
                            NSLocalizedString("Line Numbers", comment: ""),
                            isOn: $editorOptions.value.lineNumbersEnabled
                        )

                        Toggle(
                            "Keyboard Toolbar",
                            isOn: $editorOptions.value.toolBarEnabled
                        ).onChange(
                            of: editorOptions.value.toolBarEnabled
                        ) { value in
                            NotificationCenter.default.post(
                                name: Notification.Name("toolbarSettingChanged"), object: nil,
                                userInfo: ["enabled": value])
                        }

                        Toggle("Always Open In New Tab", isOn: self.$alwaysOpenInNewTab)

                        Toggle(
                            NSLocalizedString("Smooth Scrolling", comment: ""),
                            isOn: $editorOptions.value._smoothScrollingEnabled
                        )

                        Picker(
                            NSLocalizedString("Text Wrap", comment: ""),
                            selection: $editorOptions.value.wordWrap
                        ) {
                            ForEach(WordWrapOption.allCases, id: \.self) {
                                Text(verbatim: "\($0)")
                            }
                        }

                        Picker(
                            selection: $editorOptions.value.renderWhiteSpaces,
                            label: Text("Render Whitespace")
                        ) {
                            ForEach(RenderWhiteSpaceMode.allCases, id: \.self) {
                                Text(verbatim: "\($0)")
                            }
                        }
                    }

                    Section(header: Text(NSLocalizedString("EXPLORER", comment: ""))) {
                        Toggle("settings.explorer.show_hidden_files", isOn: $showHiddenFiles)
                        Toggle(
                            "settings.explorer.confirm_before_delete", isOn: $confirmBeforeDelete)
                    }

                    Section(
                        content: {
                            Toggle(
                                "settings.language_service.enable", isOn: $languageServiceEnabled)
                        }, header: { Text("settings.language_service") },
                        footer: { Text("settings.language_service.notes") })

                    Section(
                        content: {
                            Toggle("settings.runestone.editor", isOn: $runeStoneEditorEnabled)
                        }, header: { Text("settings.runestone.editor") },
                        footer: { Text("settings.runestone.editor.notes") })

                    Section(header: Text("TERMINAL")) {
                        NavigationLink(
                            destination: SettingsFontPicker(
                                showAllFonts: $showAllFonts,
                                onFontPick: { descriptor in
                                    CTFontManagerRequestFonts([descriptor] as CFArray) { _ in
                                        terminalOptions.value.fontFamily =
                                            descriptor.object(forKey: .family) as! String
                                    }
                                }
                            ).toolbar {
                                Button("Show all fonts") {
                                    showAllFonts.toggle()
                                }

                                Button("settings.editor.font.reset") {
                                    terminalOptions.value.fontFamily = TerminalOptions().fontFamily
                                }
                                .disabled(
                                    terminalOptions.value.fontFamily == TerminalOptions().fontFamily
                                )
                            },
                            label: {
                                HStack {
                                    Label("Terminal Font", systemImage: "terminal")
                                    Spacer()
                                    Text(terminalOptions.value.fontFamily)
                                        .foregroundColor(.gray)
                                }
                            }
                        )

                        Toggle("Keyboard Toolbar", isOn: $terminalOptions.value.toolbarEnabled)
                        Toggle(
                            "Show Command in Terminal",
                            isOn: $terminalOptions.value.shouldShowCompilerPath)
                    }

                    Section(header: Text(NSLocalizedString("Version Control", comment: ""))) {
                        NavigationLink(destination: SourceControlIdentityConfiguration()) {
                            Label("Author Identity", systemImage: "person.text.rectangle")
                        }
                        NavigationLink(destination: SourceControlAuthenticationConfiguration()) {
                            Label("Authentication", systemImage: "key")
                        }
                        Toggle(
                            "source_control.community_templates", isOn: $communityTemplatesEnabled)
                    }

                    Section("remote.settings.ssh_remote") {
                        Toggle(
                            "remote.settings.resolve_home_path", isOn: $remoteShouldResolveHomePath)
                    }

                    Section(header: Text("CodeApp Plus")) {
                        Button(action: {
                            guard let url = URL(string: "https://github.com/hazerbvisor/codeapp-Plus/issues")
                            else { return }
                            UIApplication.shared.open(url)
                        }) {
                            Label("Report an Issue", systemImage: "ladybug")
                        }

                        Link(
                            destination: URL(string: "https://github.com/hazerbvisor/codeapp-Plus")!
                        ) {
                            Label("CodeApp Plus on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        }

                        Link(
                            destination: URL(string: "https://github.com/thebaselab/codeapp")!
                        ) {
                            Label("Original Code App Project", systemImage: "arrow.up.right.square")
                        }
                    }

                    Section {
                        NavigationLink(
                            destination: SimpleMarkDownView(
                                text: NSLocalizedString("Changelog.message", comment: ""))
                        ) {
                            Label("Upstream Release Notes", systemImage: "doc.text")
                        }

                        Link(
                            "settings.about.change_app_language",
                            destination: URL(string: UIApplication.openSettingsURLString)!)

                        NavigationLink(
                            destination: OpenSourceLicensesView()
                        ) {
                            Label("Open Source & Licenses", systemImage: "doc.plaintext")
                        }

                        HStack {
                            Label(NSLocalizedString("Version", comment: ""), systemImage: "number")
                            Spacer()
                            Text(
                                (Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                                    as? String
                                    ?? "0.0") + " Build "
                                    + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                                        ?? "0")
                            )
                            .foregroundColor(.secondary)
                        }

                        Button(action: {
                            showsEraseAlert.toggle()
                        }) {
                            Label(NSLocalizedString("Erase all settings", comment: ""), systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .alert(isPresented: $showsEraseAlert) {
                            Alert(
                                title: Text(NSLocalizedString("Erase all settings", comment: "")),
                                message: Text(
                                    NSLocalizedString(
                                        "This will erase all user settings, including author identity and credentials.",
                                        comment: "")),
                                primaryButton: .destructive(
                                    Text(NSLocalizedString("Erase", comment: ""))
                                ) {
                                    UserDefaults.standard.dictionaryRepresentation().keys.forEach {
                                        key in
                                        UserDefaults.standard.removeObject(forKey: key)
                                    }
                                    KeychainWrapper.standard.set("", forKey: "git-username")
                                    KeychainWrapper.standard.set("", forKey: "git-password")
                                    NSUserActivity.deleteAllSavedUserActivities {}
                                    App.notificationManager.showInformationMessage(
                                        "All settings erased")
                                }, secondaryButton: .cancel())
                        }
                    } header: {
                        Text(NSLocalizedString("About", comment: ""))
                    } footer: {
                        Text("CodeApp Plus is based on Code App by thebaselab. Original copyright and open-source license notices are preserved.")
                    }
                }
                .listRowBackground(Color.init(id: "list.inactiveSelectionBackground"))
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                trailing:
                    Button(NSLocalizedString("Done", comment: "")) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
            )
            .configureToolbarBackground()
            .preferredColorScheme(themeManager.colorSchemePreference)
        }
    }
}

private struct OpenSourceComponent: Identifiable {
    let name: String
    let license: String
    let source: String

    var id: String { name }
}

private struct OpenSourceLicensesView: View {
    private let components: [OpenSourceComponent] = [
        .init(name: "CPython", license: "PSF License", source: "https://github.com/python/cpython"),
        .init(name: "LLVM / Clang / LLD", license: "Apache-2.0 WITH LLVM-exception", source: "https://github.com/llvm/llvm-project"),
        .init(name: "OpenJDK 8", license: "GPL-2.0 WITH Classpath Exception", source: "https://openjdk.org/"),
        .init(name: "Node.js", license: "MIT + bundled notices", source: "https://github.com/nodejs/node"),
        .init(name: "PHP", license: "PHP License 3.01", source: "https://github.com/php/php-src"),
        .init(name: "Monaco Editor", license: "MIT", source: "https://github.com/microsoft/monaco-editor"),
        .init(name: "Runestone", license: "MIT", source: "https://github.com/simonbs/Runestone"),
        .init(name: "tree-sitter", license: "MIT", source: "https://github.com/tree-sitter/tree-sitter"),
        .init(name: "ios_system", license: "BSD-3-Clause", source: "https://github.com/holzschu/ios_system"),
        .init(name: "libssh2", license: "BSD-style", source: "https://github.com/libssh2/libssh2"),
        .init(name: "libgit2", license: "GPL-2.0 with linking exception", source: "https://github.com/libgit2/libgit2"),
        .init(name: "ZIPFoundation", license: "MIT", source: "https://github.com/weichsel/ZIPFoundation"),
        .init(name: "ZipArchive", license: "MIT", source: "https://github.com/ZipArchive/ZipArchive"),
        .init(name: "SwiftNIO", license: "Apache-2.0", source: "https://github.com/apple/swift-nio"),
        .init(name: "Swift Collections", license: "Apache-2.0", source: "https://github.com/apple/swift-collections"),
        .init(name: "Swift Atomics", license: "Apache-2.0", source: "https://github.com/apple/swift-atomics"),
        .init(name: "Swift System", license: "Apache-2.0", source: "https://github.com/apple/swift-system")
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CodeApp Plus")
                        .font(.title3.bold())
                    Text("CodeApp Plus is a modified distribution of Code App. The original Code App copyright and MIT permission notice are preserved below.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Original Code App") {
                HStack {
                    Text("Copyright")
                    Spacer()
                    Text("© 2021 Chung Shing Hin")
                        .foregroundColor(.secondary)
                }

                NavigationLink("View MIT License") {
                    LicenseTextView(title: "Code App — MIT License", text: codeAppMITLicense)
                }

                Link("Original source repository", destination: URL(string: "https://github.com/thebaselab/codeapp")!)
            }

            Section("Major Bundled Components") {
                ForEach(components) { component in
                    Link(destination: URL(string: component.source)!) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(component.name)
                                    .foregroundColor(.primary)
                                Text(component.license)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section {
                Text("Third-party components remain governed by their upstream licenses. Runtime archives and frameworks can include additional notices for bundled subcomponents. The repository also contains THIRD_PARTY_NOTICES.md as a distribution checklist and notice inventory.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Open Source & Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicenseTextView: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let codeAppMITLicense = """
MIT License

Copyright (c) 2021 Chung Shing Hin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

extension View {
    @ViewBuilder
    func configureToolbarBackground() -> some View {
        if #available(iOS 16.4, *) {
            self
                .toolbarBackground(
                    Color.init(id: "editor.background"), for: .navigationBar
                )
        } else {
            self
        }
    }
}
