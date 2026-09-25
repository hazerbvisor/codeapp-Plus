//
//  GitHubSearchView.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import SwiftUI

struct GitHubSearchView: View {

    @EnvironmentObject var App: MainApp

    let onClone: (String) async throws -> Void
    let onTap: (String) -> Void

    @State private var mode: RepositoryBrowserMode = .myRepos
    @State private var repositoryFilter: String = ""

    private enum RepositoryBrowserMode: String, CaseIterable, Identifiable {
        case myRepos = "My Repos"
        case publicRepos = "Add Public"
        case privateRepos = "Add Private"

        var id: String { rawValue }
    }

    private func matchesFilter(_ item: GitHubSearchManager.item) -> Bool {
        let trimmed = repositoryFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return item.name.localizedCaseInsensitiveContains(trimmed)
            || item.full_name.localizedCaseInsensitiveContains(trimmed)
            || item.owner.login.localizedCaseInsensitiveContains(trimmed)
            || (item.description?.localizedCaseInsensitiveContains(trimmed) ?? false)
    }

    private var visibleMyRepositories: [GitHubSearchManager.item] {
        App.searchManager.myRepositories.filter(matchesFilter)
    }

    private var visiblePrivateRepositories: [GitHubSearchManager.item] {
        App.searchManager.myRepositories.filter { $0.isPrivate && matchesFilter($0) }
    }

    private var visiblePublicSearchResults: [GitHubSearchManager.item] {
        App.searchManager.searchResultItems.filter { !$0.isPrivate }
    }

    var body: some View {
        Picker("Repository Source", selection: $mode) {
            ForEach(RepositoryBrowserMode.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)

        switch mode {
        case .myRepos:
            repositoryFilterField
            authenticatedRepositoryState(repositories: visibleMyRepositories, emptyMessage: "No accessible repositories found.")

        case .publicRepos:
            SearchBar(
                text: $App.searchManager.searchTerm,
                searchAction: { App.searchManager.search() }, placeholder: "Search public GitHub repositories",
                cornerRadius: 10)

            ForEach(visiblePublicSearchResults, id: \.html_url) { item in
                GitHubSearchResultCell(item: item, onClone: onClone, onTap: onTap)
            }
            .listRowBackground(Color.init(id: "sideBar.background"))

        case .privateRepos:
            repositoryFilterField
            authenticatedRepositoryState(
                repositories: visiblePrivateRepositories,
                emptyMessage: "No private repositories are available with the current GitHub token."
            )
        }
    }

    private var repositoryFilterField: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.secondary)
            TextField("Filter repositories", text: $repositoryFilter)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !repositoryFilter.isEmpty {
                Button {
                    repositoryFilter = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(Color.init(id: "input.background"))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func authenticatedRepositoryState(
        repositories: [GitHubSearchManager.item], emptyMessage: String
    ) -> some View {
        if App.searchManager.isLoadingMyRepositories {
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading repositories…")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        } else if !App.searchManager.myRepositoriesErrorMessage.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    App.searchManager.myRepositoriesErrorMessage,
                    systemImage: "exclamationmark.triangle"
                )
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                Button("Retry") {
                    App.searchManager.loadMyRepositories(force: true)
                }
                .font(.system(size: 12, weight: .semibold))
            }
        } else if repositories.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(emptyMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Button("Refresh Repositories") {
                    App.searchManager.loadMyRepositories(force: true)
                }
                .font(.system(size: 12, weight: .semibold))
            }
        } else {
            HStack {
                DescriptionText("\(repositories.count) repositories")
                Spacer()
                Button {
                    App.searchManager.loadMyRepositories(force: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }

            ForEach(repositories, id: \.html_url) { item in
                GitHubSearchResultCell(item: item, onClone: onClone, onTap: onTap)
            }
            .listRowBackground(Color.init(id: "sideBar.background"))
        }
    }
}

struct GitHubSearchResultCell: View {

    @State var item: GitHubSearchManager.item

    let onClone: (String) async throws -> Void
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                RemoteImage(url: item.owner.avatar_url)
                    .frame(width: 20, height: 20)
                    .cornerRadius(5)
                Text(item.full_name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.init("T1"))
                    .lineLimit(1)

                Spacer()

                Label(
                    item.isPrivate ? "Private" : "Public",
                    systemImage: item.isPrivate ? "lock.fill" : "globe"
                )
                .labelStyle(.titleAndIcon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            }

            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.init("T1"))
                    .lineLimit(2)
            }

            HStack {
                Image(systemName: "star")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                DescriptionText("\(item.stargazers_count)")

                if item.language != nil {
                    DescriptionText(
                        "\(item.language ?? "")  • \(humanReadableByteCount(bytes: item.size*1024))"
                    )
                } else {
                    DescriptionText("\(humanReadableByteCount(bytes: item.size*1024))")
                }

                if item.fork {
                    DescriptionText("• Fork")
                }

                Spacer()

                CloneButton(item: item, onClone: onClone)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(item.html_url)
        }
        .onAppear {
            if AppNeedsRepositoryRefresh.shared.shouldRefresh {
                // Intentionally empty: keeps cells lightweight. Repository refresh is handled by the parent view.
            }
        }
    }
}

private struct CloneButton: View {

    @EnvironmentObject var App: MainApp
    @State var item: GitHubSearchManager.item

    let onClone: (String) async throws -> Void

    var body: some View {
        Text("source_control.clone")
            .foregroundColor(.white)
            .lineLimit(1)
            .font(.system(size: 12))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Color.init(id: "button.background")
            )
            .cornerRadius(10)
            .onTapGesture {
                Task {
                    do {
                        try await onClone(item.clone_url)
                    } catch {
                        App.notificationManager.showErrorMessage(error.localizedDescription)
                    }
                }
            }
    }
}

private final class AppNeedsRepositoryRefresh {
    static let shared = AppNeedsRepositoryRefresh()
    var shouldRefresh: Bool { false }
}
