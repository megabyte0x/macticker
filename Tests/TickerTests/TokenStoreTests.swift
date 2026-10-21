import Foundation
import Testing
@testable import Ticker

@Test(.enabled(if: ProcessInfo.processInfo.environment["TICKER_LIVE_CHECK"] == "1"))
@MainActor func livePricesAndSearch() async throws {
    let tokens = try await CoinGecko.search("zcash")
    #expect(tokens.contains { $0.id == "zcash" && $0.symbol.uppercased() == "ZEC" })
    let suite = "TickerLiveTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TokenStore(defaults: defaults)
    await store.refresh()
    #expect(store.error == nil)
    #expect((store.quotes["bitcoin"]?.current_price ?? 0) > 0)
    for period in ChangePeriod.allCases {
        #expect(store.quotes["bitcoin"]?.change(for: period) != nil)
    }
    #expect(store.updatedAt != nil)
    #expect(store.quotes["bitcoin"]?.isStale == false)
}

@Test func quoteFreshnessAllowsProviderLag() {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let recent = Quote(id: "bitcoin", current_price: 100, price_change_percentage_1h_in_currency: nil,
                       price_change_percentage_24h_in_currency: nil, price_change_percentage_7d_in_currency: nil,
                       last_updated: formatter.string(from: Date().addingTimeInterval(-240)))
    let old = Quote(id: "bitcoin", current_price: 100, price_change_percentage_1h_in_currency: nil,
                    price_change_percentage_24h_in_currency: nil, price_change_percentage_7d_in_currency: nil,
                    last_updated: formatter.string(from: Date().addingTimeInterval(-660)))
    #expect(!recent.isStale)
    #expect(old.isStale)
}

@Test @MainActor func watchlistAndPrices() throws {
    let suite = "TickerTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TokenStore(defaults: defaults)
    #expect(store.starred?.id == "bitcoin")
    store.add(Token.initial[0])
    #expect(store.tokens.count == 3)
    store.star(Token.initial[1])
    #expect(TokenStore(defaults: defaults).starred?.id == "ethereum")
    store.remove(Token.initial[1])
    #expect(store.starred?.id == "bitcoin")
    for token in store.tokens { store.remove(token) }
    #expect(store.menuTitle == "Ticker")
    #expect(TokenStore(defaults: defaults).tokens.isEmpty)
    store.add(Token.initial[2])
    #expect(store.starred?.id == "solana")
    let data = Data(#"{"id":"tiny","current_price":0.00000001,"price_change_percentage_1h_in_currency":1.5,"price_change_percentage_24h_in_currency":-2.5,"price_change_percentage_7d_in_currency":7.5,"last_updated":"2020-01-01T00:00:00.000Z"}"#.utf8)
    let quote = try JSONDecoder().decode(Quote.self, from: data)
    #expect(quote.price == "<$0.000001")
    #expect(quote.isStale)
    #expect(quote.change(for: .hour) == 1.5)
    #expect(quote.change(for: .day) == -2.5)
    #expect(quote.change(for: .week) == 7.5)
    let missing = try JSONDecoder().decode(Quote.self, from: Data(#"{"id":"missing"}"#.utf8))
    #expect(missing.price == "—")
    #expect(missing.change(for: .week) == nil)
}
