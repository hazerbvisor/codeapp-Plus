//
//  panel.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import ios_system

private let PANEL_MINIMUM_HEIGHT: CGFloat = 40
private let TOP_BAR_HEIGHT: CGFloat = 40
private let EDITOR_MINIMUM_HEIGHT: CGFloat = 8
private let BOTTOM_BAR_HEIGHT: CGFloat = 20

struct PanelToolbarButton: View {
    let systemName: String
    let onTapGesture: () -> Void

    var body: some View {
        Button(action: onTapGesture) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(Color.init(id: "panelTitle.activeForeground"))
                .padding(3)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .hoverEffect(.highlight)
                .frame(minWidth: 0, maxWidth: 8, minHeight: 0, maxHeight: 8)
                .padding(.horizontal)
        }
    }
}

private struct PanelTabLabel: View {
    let panel: Panel
    @SceneStorage("panel.focusedId") var currentPanelId: String = DefaultUIState.PANEL_FOCUSED_ID

    var body: some View {
        Text(LocalizedStringKey(panel.labelId))
            .textCase(.uppercase)
            .foregroundColor(
                Color.init(
                    id: panel.labelId == currentPanelId
                        ? "panelTitle.activeForeground" : "panelTitle.inactiveForeground")
            )
            .font(.system(size: 12, weight: .light))
            .padding(.leading)
            .onTapGesture {
                currentPanelId = panel.labelId
            }
    }
}

private struct PanelTabs: View {
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var panelManager: PanelManager

    private var problemCount: Int {
        App.problems.values.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        ForEach(panelManager.panels, id: \.labelId) { panel in
            PanelTabLabel(panel: panel)

            if panel.labelId == "PROBLEMS", problemCount > 0 {
                Circle()
                    .fill(Color.init(id: "panel.border"))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Text("\(problemCount)")
                            .foregroundColor(Color.init(id: "panelTitle.activeForeground"))
                            .font(.system(size: 10))
                    )
            } else if let bubbleCount = panelManager.bubbleCount[panel.labelId] {
                Circle()
                    .fill(Color.init(id: "panel.border"))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Text("\(bubbleCount)")
                            .foregroundColor(Color.init(id: "panelTitle.activeForeground"))
                            .font(.system(size: 10))
                    )
            }
        }
    }

}

private struct ProblemsPanelView: View {
    @EnvironmentObject var App: MainApp

    private var sortedURLs: [URL] {
        App.problems.keys.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent)
                == .orderedAscending
        }
    }

    private func iconName(for severity: Int) -> String {
        switch severity {
        case 8:
            return "xmark.circle.fill"
        case 4:
            return "exclamationmark.triangle.fill"
        case 2:
            return "info.circle.fill"
        default:
            return "lightbulb.fill"
        }
    }

    private func open(_ marker: MonacoEditorMarker, in url: URL) {
        Task { @MainActor in
            do {
                _ = try await App.openFile(url: url, alwaysInNewTab: true)
                await App.monacoInstance.scrollToLine(line: marker.startLineNumber)
                await App.monacoInstance.focus()
            } catch {
                App.notificationManager.showErrorMessage(error.localizedDescription)
            }
        }
    }

    var body: some View {
        if App.problems.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24))
                Text("No problems detected in the current workspace.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedURLs, id: \.self) { url in
                        if let markers = App.problems[url], !markers.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    FileIcon(url: url.lastPathComponent, iconSize: 12)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                    Text("\(markers.count)")
                                        .foregroundColor(.secondary)
                                }

                                ForEach(markers) { marker in
                                    Button {
                                        open(marker, in: url)
                                    } label: {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: iconName(for: marker.severity))
                                                .frame(width: 14)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(marker.message)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(2)
                                                Text(
                                                    "Line \(marker.startLineNumber), Column \(marker.startColumn) · \(marker.owner)"
                                                )
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            }
                                            Spacer(minLength: 0)
                                        }
                                        .contentShape(Rectangle())
                                        .padding(.vertical, 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct Implementation: View {

    @EnvironmentObject var panelManager: PanelManager
    @SceneStorage("panel.focusedId") var currentPanelId: String = DefaultUIState.PANEL_FOCUSED_ID

    var currentPanel: Panel? {
        panelManager.panels.first(where: { $0.labelId == currentPanelId })
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Rectangle()
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 1)
                    .foregroundColor(
                        Color.init(id: "panel.border"))
            }

            HStack {
                PanelTabs()

                Spacer()

                currentPanel?
                    .toolBarView
                    .padding(.horizontal)
                    .environmentObject(panelManager)

            }.frame(height: 14).padding(.vertical, 5)

            HStack {
                if let currentPanel = currentPanel {
                    currentPanel.mainView
                        .padding(.horizontal)
                } else {
                    Text("Empty Panel")
                }
            }.frame(maxHeight: .infinity)
        }
        .foregroundColor(Color(id: "panelTitle.activeForeground"))
        .font(.system(size: 12, weight: .light))
    }

}

struct PanelView: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var panelManager: PanelManager

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @SceneStorage("panel.visible") var showsPanel: Bool = DefaultUIState.PANEL_IS_VISIBLE
    @SceneStorage("panel.height") var panelHeight: Double = DefaultUIState.PANEL_HEIGHT

    @State var showSheet = false
    @GestureState private var translation: CGFloat?

    var maxHeight: CGFloat {
        windowHeight
            - UIApplication.shared.getSafeArea(edge: .top)
            - UIApplication.shared.getSafeArea(edge: .bottom)
            - TOP_BAR_HEIGHT
            - EDITOR_MINIMUM_HEIGHT
            - BOTTOM_BAR_HEIGHT
    }
    var windowHeight: CGFloat

    func evaluateProposedHeight(proposal: CGFloat) {
        if proposal < PANEL_MINIMUM_HEIGHT {
            showsPanel = false
            panelHeight = DefaultUIState.PANEL_HEIGHT
        } else if proposal > maxHeight {
            panelHeight = maxHeight
        } else {
            panelHeight = proposal
        }
    }

    private func registerProblemsPanelIfNeeded() {
        guard !panelManager.panels.contains(where: { $0.labelId == "PROBLEMS" }) else {
            return
        }
        panelManager.registerPanel(
            panel: Panel(
                labelId: "PROBLEMS",
                mainView: AnyView(ProblemsPanelView()),
                toolBarView: nil
            )
        )
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Implementation()
                    .frame(height: min(CGFloat(panelHeight), maxHeight))
                    .background(Color.init(id: "editor.background"))
                    .gesture(
                        DragGesture(minimumDistance: 10.0, coordinateSpace: .global)
                            .updating($translation) { value, gestureState, transaction in
                                let proposedNewHeight =
                                    panelHeight - value.translation.height + (translation ?? 0)
                                evaluateProposedHeight(proposal: proposedNewHeight)
                                gestureState = value.translation.height
                            }
                    )
            } else {
                Implementation()
                    .frame(height: min(CGFloat(panelHeight), maxHeight))
                    .background(Color.init(id: "editor.background"))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let proposedNewHeight = panelHeight - value.translation.height
                                evaluateProposedHeight(proposal: proposedNewHeight)
                            }
                    )
            }
        }
        .onAppear {
            registerProblemsPanelIfNeeded()
        }
    }
}
