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

    private var isActive: Bool {
        panel.labelId == currentPanelId
    }

    var body: some View {
        Button {
            currentPanelId = panel.labelId
        } label: {
            Text(LocalizedStringKey(panel.labelId))
                .textCase(.uppercase)
                .foregroundColor(
                    Color.init(
                        id: isActive
                            ? "panelTitle.activeForeground" : "panelTitle.inactiveForeground")
                )
                .font(.system(size: 11, weight: isActive ? .semibold : .medium))
                .padding(.horizontal, 7)
                .frame(height: 28)
                .overlay(alignment: .bottom) {
                    if isActive {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct PanelCountBadge: View {
    let count: Int

    var body: some View {
        Text(count > 999 ? "999+" : "\(count)")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(Color.init(id: "panelTitle.activeForeground"))
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 16)
            .background(
                Capsule()
                    .fill(Color.init(id: "panel.border"))
            )
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
            HStack(spacing: 3) {
                PanelTabLabel(panel: panel)

                if panel.labelId == "PROBLEMS", problemCount > 0 {
                    PanelCountBadge(count: problemCount)
                } else if let bubbleCount = panelManager.bubbleCount[panel.labelId] {
                    PanelCountBadge(count: bubbleCount)
                }
            }
        }
    }
}

private enum ProblemSeverityFilter: String, CaseIterable, Identifiable {
    case all
    case errors
    case warnings
    case info
    case hints

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .errors: return "Errors"
        case .warnings: return "Warnings"
        case .info: return "Info"
        case .hints: return "Hints"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .errors: return "xmark.circle.fill"
        case .warnings: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .hints: return "lightbulb.fill"
        }
    }

    var severity: Int? {
        switch self {
        case .all: return nil
        case .errors: return 8
        case .warnings: return 4
        case .info: return 2
        case .hints: return 1
        }
    }
}

private struct ProblemsPanelView: View {
    @EnvironmentObject var App: MainApp

    @State private var searchText = ""
    @State private var severityFilter: ProblemSeverityFilter = .all

    private var sortedURLs: [URL] {
        App.problems.keys.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent)
                == .orderedAscending
        }
    }

    private var filteredURLs: [URL] {
        sortedURLs.filter { !filteredMarkers(for: $0).isEmpty }
    }

    private var filteredProblemCount: Int {
        filteredURLs.reduce(0) { $0 + filteredMarkers(for: $1).count }
    }

    private var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || severityFilter != .all
    }

    private func markerCount(for filter: ProblemSeverityFilter) -> Int {
        App.problems.values.reduce(0) { partialResult, markers in
            partialResult + markers.filter { marker in
                guard let severity = filter.severity else { return true }
                return marker.severity == severity
            }.count
        }
    }

    private func filteredMarkers(for url: URL) -> [MonacoEditorMarker] {
        guard let markers = App.problems[url] else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return markers.filter { marker in
            if let severity = severityFilter.severity, marker.severity != severity {
                return false
            }

            guard !query.isEmpty else { return true }
            return marker.message.localizedCaseInsensitiveContains(query)
                || marker.owner.localizedCaseInsensitiveContains(query)
                || url.lastPathComponent.localizedCaseInsensitiveContains(query)
                || url.path.localizedCaseInsensitiveContains(query)
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

    private func iconColor(for severity: Int) -> Color {
        switch severity {
        case 8:
            return .red
        case 4:
            return .orange
        case 2:
            return .blue
        default:
            return .secondary
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
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Filter Problems", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))
                )

                Menu {
                    ForEach(ProblemSeverityFilter.allCases) { filter in
                        Button {
                            severityFilter = filter
                        } label: {
                            Label(
                                "\(filter.title) (\(markerCount(for: filter)))",
                                systemImage: filter.systemImage
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: severityFilter.systemImage)
                        Text(severityFilter.title)
                        if isFiltering {
                            Text("\(filteredProblemCount)")
                                .font(.caption2.monospacedDigit())
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.init(id: "panel.border"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)

            Divider()

            if App.problems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                    Text("No problems detected in the current workspace.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredURLs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22))
                    Text("No problems match the current filter.")
                        .foregroundColor(.secondary)
                    Button("Clear Filters") {
                        searchText = ""
                        severityFilter = .all
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filteredURLs, id: \.self) { url in
                            let markers = filteredMarkers(for: url)

                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 7) {
                                    FileIcon(url: url.lastPathComponent, iconSize: 12)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(url.lastPathComponent)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                        Text(url.deletingLastPathComponent().lastPathComponent)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 6)
                                    Text("\(markers.count)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundColor(.secondary)
                                }

                                ForEach(markers) { marker in
                                    Button {
                                        open(marker, in: url)
                                    } label: {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: iconName(for: marker.severity))
                                                .foregroundColor(iconColor(for: marker.severity))
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
                                        .padding(.vertical, 3)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }
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
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .foregroundColor(Color.init(id: "panel.border"))

            HStack(spacing: 4) {
                PanelTabs()

                Spacer()

                currentPanel?
                    .toolBarView
                    .padding(.horizontal, 8)
                    .environmentObject(panelManager)
            }
            .frame(height: 28)

            HStack {
                if let currentPanel = currentPanel {
                    currentPanel.mainView
                        .padding(.horizontal)
                } else {
                    Text("Empty Panel")
                }
            }
            .frame(maxHeight: .infinity)
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
