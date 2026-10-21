import Foundation
import Observation

struct Token: Codable, Identifiable, Equatable {
    let id: String
    let symbol: String
    let name: String

    static let initial = [
        Token(id: "bitcoin", symbol: "BTC", name: "Bitcoin"),
        Token(id: "ethereum", symbol: "ETH", name: "Ethereum"),
        Token(id: "solana", symbol: "SOL", name: "Solana")
    ]
}

enum ChangePeriod: String, CaseIterable {
    case hour = "1h", day = "24h", week = "1w"
}

struct Quote: Decodable {
    let id: String
    let current_price: Double?
    let price_change_percentage_1h_in_currency: Double?
    let price_change_percentage_24h_in_currency: Double?
    let price_change_percentage_7d_in_currency: Double?
    let last_updated: String?

    func change(for period: ChangePeriod) -> Double? {
        switch period {
        case .hour: price_change_percentage_1h_in_currency
        case .day: price_change_percentage_24h_in_currency
        case .week: price_change_percentage_7d_in_currency
        }
    }

    var isStale: Bool {
        guard let last_updated else { return true }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: last_updated) else { return true }
        return Date().timeIntervalSince(date) > 600
    }

    var price: String {
        guard let usd = current_price, usd.isFinite, usd >= 0 else { return "—" }
        if usd > 0 && usd < 0.000001 { return "<$0.000001" }
        return usd.formatted(.currency(code: "USD").precision(.fractionLength(usd < 1 ? 2...6 : 2...2)))
    }
}

enum CoinGecko {
    static func fetch<T: Decodable>(_ path: String, items: [URLQueryItem]) async throws -> T {
        var url = URLComponents(string: "https://api.coingecko.com/api/v3/\(path)")!
        url.queryItems = items
        var request = URLRequest(url: url.url!, cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func search(_ query: String) async throws -> [Token] {
        struct Results: Decodable { let coins: [Token] }
        let result: Results = try await fetch("search", items: [.init(name: "query", value: query)])
        return Array(result.coins.prefix(20))
    }
}

@MainActor @Observable
final class TokenStore {
    private let defaults: UserDefaults
    private(set) var tokens: [Token]
    private(set) var starredID: String?
    private(set) var quotes: [String: Quote] = [:]
    private(set) var refreshing = false
    private(set) var error: String?
    private(set) var updatedAt: Date?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        tokens = defaults.data(forKey: "tokens").flatMap { try? JSONDecoder().decode([Token].self, from: $0) } ?? Token.initial
        let saved = defaults.string(forKey: "starredID")
        starredID = tokens.first(where: { $0.id == saved })?.id ?? tokens.first?.id
    }

    var starred: Token? { tokens.first { $0.id == starredID } }

    var menuTitle: String {
        guard let starred else { return "Ticker" }
        guard let quote = quotes[starred.id], quote.current_price != nil else { return "\(starred.symbol.uppercased()) —" }
        return "\(starred.symbol.uppercased()) \(error != nil || quote.isStale ? "~" : "")\(quote.price)"
    }

    func add(_ token: Token) {
        guard !tokens.contains(where: { $0.id == token.id }) else { return }
        tokens.append(token)
        if starredID == nil { starredID = token.id }
        save()
    }

    func remove(_ token: Token) {
        tokens.removeAll { $0.id == token.id }
        quotes[token.id] = nil
        if starredID == token.id { starredID = tokens.first?.id }
        save()
    }

    func star(_ token: Token) {
        guard tokens.contains(where: { $0.id == token.id }) else { return }
        starredID = token.id
        save()
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(tokens), forKey: "tokens")
        defaults.set(starredID, forKey: "starredID")
    }

    func refresh() async {
        guard !refreshing, !tokens.isEmpty else { return }
        refreshing = true
        defer { refreshing = false }
        do {
            let result: [Quote] = try await CoinGecko.fetch("coins/markets", items: [
                .init(name: "ids", value: tokens.map(\.id).joined(separator: ",")),
                .init(name: "vs_currency", value: "usd"),
                .init(name: "per_page", value: "250"),
                .init(name: "price_change_percentage", value: "1h,24h,7d")
            ])
            quotes = Dictionary(uniqueKeysWithValues: result.filter { quote in
                tokens.contains { $0.id == quote.id }
            }.map { ($0.id, $0) })
            updatedAt = Date()
            error = nil
        } catch {
            self.error = "Prices unavailable. Retrying every minute."
        }
    }
}
