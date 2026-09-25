//
//  GitHubSearchManager.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import Foundation
import SwiftUI

class GitHubSearchManager: ObservableObject {

    @Published var searchResultItems: [item] = []
    @Published var myRepositories: [item] = []
    @Published var templates: [item]? = nil
    @Published var searchTerm: String = ""
    @Published var errorMessage: String = ""
    @Published var myRepositoriesErrorMessage: String = ""
    @Published var isLoadingMyRepositories: Bool = false

    static let endpoint = "https://api.github.com/search/repositories"
    static let userRepositoriesEndpoint = "https://api.github.com/user/repos"

    struct searchResult: Decodable {
        let items: [item]
    }

    struct item: Decodable {
        let name: String
        let full_name: String
        let html_url: String
        let clone_url: String
        let description: String?
        let stargazers_count: Int
        let size: Int
        let language: String?
        let owner: owner
        let isPrivate: Bool
        let fork: Bool
        let default_branch: String
        let updated_at: String

        enum CodingKeys: String, CodingKey {
            case name
            case full_name
            case html_url
            case clone_url
            case description
            case stargazers_count
            case size
            case language
            case owner
            case isPrivate = "private"
            case fork
            case default_branch
            case updated_at
        }
    }

    struct owner: Decodable {
        let login: String
        let avatar_url: String
    }

    private enum GitHubRepositoryError: LocalizedError {
        case missingToken
        case requestFailed(Int)

        var errorDescription: String? {
            switch self {
            case .missingToken:
                return "Add a GitHub personal access token in Settings → Version Control → Authentication to load repositories you can access."
            case .requestFailed(let statusCode):
                return "GitHub returned HTTP \(statusCode). Check your token and repository permissions."
            }
        }
    }

    private var storedGitHubToken: String? {
        guard let token = KeychainWrapper.standard.string(forKey: "git-password"), !token.isEmpty
        else { return nil }
        return token
    }

    func search() {
        if searchTerm == "" {
            return
        }
        self.errorMessage = ""

        let query = searchTerm + "&per_page=10"

        Task {
            do {
                let items = try await executeQuery(query: query)
                await MainActor.run {
                    self.searchResultItems = items
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func loadMyRepositories(force: Bool = false) {
        if !force && !myRepositories.isEmpty {
            return
        }

        isLoadingMyRepositories = true
        myRepositoriesErrorMessage = ""

        Task {
            do {
                let repositories = try await executeAuthenticatedRepositoriesQuery()
                await MainActor.run {
                    self.myRepositories = repositories
                    self.isLoadingMyRepositories = false
                }
            } catch {
                await MainActor.run {
                    self.myRepositoriesErrorMessage = error.localizedDescription
                    self.isLoadingMyRepositories = false
                }
            }
        }
    }

    func listTemplates() {
        let query = "topic:codeapp-template sort:stars"
        Task {
            do {
                let templates = try await executeQuery(query: query)
                await MainActor.run {
                    self.templates = templates
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func makeRequest(url: URL, requiresAuthentication: Bool) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("CodeApp-Plus", forHTTPHeaderField: "User-Agent")

        if let token = storedGitHubToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if requiresAuthentication {
            throw GitHubRepositoryError.missingToken
        }

        return request
    }

    private func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
            !(200...299).contains(response.statusCode)
        {
            throw GitHubRepositoryError.requestFailed(response.statusCode)
        }
        return data
    }

    private func executeQuery(query: String) async throws -> [item] {
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return []
        }
        let url = URL(string: GitHubSearchManager.endpoint + "?q=\(query)")!
        let request = try makeRequest(url: url, requiresAuthentication: false)
        let data = try await data(for: request)
        let result = try JSONDecoder().decode(searchResult.self, from: data)
        return result.items
    }

    private func executeAuthenticatedRepositoriesQuery() async throws -> [item] {
        var repositories: [item] = []
        var page = 1

        while true {
            var components = URLComponents(string: GitHubSearchManager.userRepositoriesEndpoint)!
            components.queryItems = [
                URLQueryItem(name: "affiliation", value: "owner,collaborator,organization_member"),
                URLQueryItem(name: "visibility", value: "all"),
                URLQueryItem(name: "sort", value: "updated"),
                URLQueryItem(name: "direction", value: "desc"),
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: "\(page)")
            ]

            guard let url = components.url else { return repositories }
            let request = try makeRequest(url: url, requiresAuthentication: true)
            let data = try await data(for: request)
            let pageItems = try JSONDecoder().decode([item].self, from: data)
            repositories.append(contentsOf: pageItems)

            if pageItems.count < 100 {
                break
            }
            page += 1
        }

        return repositories
    }
}
