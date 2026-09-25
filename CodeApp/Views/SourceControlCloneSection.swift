//
//  SourceControlCloneSection.swift
//  Code
//
//  Created by Ken Chung on 12/4/2022.
//

import SwiftUI

struct SourceControlCloneSection: View {

    @EnvironmentObject var App: MainApp
    @State var gitURL: String = ""
    @State private var showsManualClone: Bool = false

    let onClone: (String) async throws -> Void
    let onTapResult: (String) -> Void

    var body: some View {
        Section(
            header:
                Text("Repositories")
                .foregroundColor(Color(id: "sideBarSectionHeader.foreground"))
        ) {

            if App.searchManager.errorMessage != "" {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(App.searchManager.errorMessage).font(
                        .system(size: 12, weight: .light))
                }.foregroundColor(.gray)
            }

            GitHubSearchView(onClone: onClone, onTap: onTapResult)

            DisclosureGroup("Clone by URL", isExpanded: $showsManualClone) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        TextField(
                            "URL (HTTPS/SSH)", text: $gitURL,
                            onCommit: {
                                Task {
                                    do {
                                        try await onClone(gitURL)
                                        await MainActor.run {
                                            gitURL = ""
                                        }
                                    } catch {
                                        App.notificationManager.showErrorMessage(error.localizedDescription)
                                    }
                                }
                            }
                        )
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                        Spacer()

                    }
                    .padding(7)
                    .background(Color.init(id: "input.background"))
                    .cornerRadius(10)

                    DescriptionText("Use this for Git servers or repositories not listed above.")
                }
                .padding(.top, 6)
            }
        }
    }
}
