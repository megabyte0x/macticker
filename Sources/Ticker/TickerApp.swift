import SwiftUI

@main
struct TickerApp: App {
    @State private var store = TokenStore()

    var body: some Scene {
        MenuBarExtra {
            TickerView(store: store)
        } label: {
            Text(store.menuTitle)
                .monospacedDigit()
                .task {
                    while !Task.isCancelled {
                        await store.refresh()
                        try? await Task.sleep(for: .seconds(60))
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
}

struct TickerView: View {
    let store: TokenStore
    @AppStorage("changePeriod") private var changePeriod = ChangePeriod.day
    @State private var adding = false
    @State private var query = ""
    @State private var results: [Token] = []
    @State private var searching = false
    @State private var searchError: String?
    @FocusState private var searchFocused: Bool
    @FocusState private var removeFocusedID: String?
    @State private var hoveredID: String?

    private var contentHeight: CGFloat {
        max(168, CGFloat(min(store.tokens.count, 5)) * 56)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if adding {
                    Button { closeSearch() } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Back to watchlist")
                    .help("Back to watchlist (Esc)")
                }
                Text(adding ? "Add Token" : "Ticker")
                    .font(.headline)
                Spacer()
                if !adding {
                    Button {
                        adding = true
                        searchFocused = true
                    } label: {
                        Image(systemName: "plus").frame(width: 24, height: 24)
                    }
                    .keyboardShortcut("n")
                    .accessibilityLabel("Add token")
                    .help("Add token (⌘N)")
                    Menu {
                        Button("Refresh Prices", systemImage: "arrow.clockwise") {
                            Task { await store.refresh() }
                        }
                        .keyboardShortcut("r")
                        .disabled(store.refreshing || store.tokens.isEmpty)
                        Divider()
                        Button("Quit Ticker", systemImage: "power") {
                            NSApplication.shared.terminate(nil)
                        }
                        .keyboardShortcut("q")
                    } label: {
                        Image(systemName: "ellipsis").frame(width: 24, height: 24)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .accessibilityLabel("Ticker options")
                    .help("Ticker options")
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Group {
                if adding {
                    searchView
                } else if store.tokens.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2).foregroundStyle(.secondary)
                        Text("Your watchlist is empty").font(.headline)
                        Button("Add Token") {
                            adding = true
                            searchFocused = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(store.tokens) { token in
                                tokenRow(token)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .frame(height: contentHeight)

            Divider()

            VStack(spacing: 12) {
                HStack {
                    Text("Change").foregroundStyle(.secondary)
                    Spacer()
                    Picker("Price change period", selection: $changePeriod) {
                        ForEach(ChangePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 144)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(statusText)
                        .lineLimit(2)
                        .help(store.error ?? statusText)
                        .accessibilityLabel(statusText)
                    Spacer(minLength: 0)
                    Link("CoinGecko", destination: URL(string: "https://www.coingecko.com")!)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(16)
        }
        .frame(width: 320)
        .onExitCommand { closeSearch() }
        .onDisappear {
            closeSearch()
            hoveredID = nil
        }
    }

    private var statusText: String {
        if store.tokens.isEmpty { return "No tokens" }
        if store.refreshing { return "Updating prices…" }
        if store.error != nil { return "Prices unavailable · retrying" }
        if let date = store.updatedAt {
            return "Updated \(date.formatted(date: .omitted, time: .shortened))"
        }
        return "Waiting for prices…"
    }

    private var searchView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Name or symbol", text: $query)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .accessibilityLabel("Search tokens by name or symbol")
                if !query.isEmpty {
                    Button {
                        query = ""
                        searchFocused = true
                    } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Clear search")
                }
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if searching || results.isEmpty {
                VStack(spacing: 8) {
                    if searching {
                        ProgressView().controlSize(.small)
                        Text("Searching…")
                    } else {
                        Text(searchError ?? (query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "Search for a token, like Bitcoin or BTC."
                            : "No tokens found."))
                            .multilineTextAlignment(.center)
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(results) { token in
                            let added = store.tokens.contains { $0.id == token.id }
                            Button {
                                store.add(token)
                                closeSearch()
                                Task { await store.refresh() }
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(token.name).foregroundStyle(.primary).lineLimit(1)
                                        Text(token.symbol.uppercased()).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: added ? "checkmark" : "plus")
                                        .foregroundStyle(added ? Color.secondary : Color.accentColor)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .disabled(added)
                            .accessibilityLabel(added ? "\(token.name), already added" : "Add \(token.name)")
                        }
                    }
                }
            }
        }
        .task(id: query) {
            let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
            results = []
            searchError = nil
            searching = !term.isEmpty
            guard !term.isEmpty else { return }
            do {
                try await Task.sleep(for: .milliseconds(400))
                let found = try await CoinGecko.search(term)
                try Task.checkCancellation()
                results = found
                searching = false
            } catch {
                guard !Task.isCancelled else { return }
                searchError = "Search unavailable. Please try again."
                searching = false
            }
        }
    }

    private func closeSearch() {
        adding = false
        searchFocused = false
        query = ""
        results = []
        searching = false
        searchError = nil
    }

    private func tokenRow(_ token: Token) -> some View {
        let selected = token.id == store.starredID
        let quote = store.quotes[token.id]
        return HStack(spacing: 8) {
            Button { store.star(token) } label: {
                Image(systemName: selected ? "star.fill" : "star")
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .frame(width: 28, height: 32)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(selected ? "\(token.name) is shown in menu bar" : "Show \(token.name) in menu bar")
            .help("Show \(token.symbol.uppercased()) in menu bar")
            VStack(alignment: .leading, spacing: 3) {
                Text(token.symbol.uppercased()).font(.system(.body, weight: .medium))
                Text(token.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(quote?.price ?? "—").monospacedDigit()
                if let quote, quote.isStale || store.error != nil {
                    Text("Stale").font(.caption).foregroundStyle(.secondary)
                } else if let change = quote?.change(for: changePeriod) {
                    Text("\(change >= 0 ? "+" : "")\(change.formatted(.number.precision(.fractionLength(2))))%")
                        .font(.caption).monospacedDigit()
                        .foregroundStyle(change >= 0 ? .green : .red)
                        .accessibilityLabel("\(changePeriod.rawValue) change \(change.formatted()) percent")
                } else {
                    Text("—").font(.caption).foregroundStyle(.secondary)
                        .accessibilityLabel("\(changePeriod.rawValue) change unavailable")
                }
            }
            Button {
                store.remove(token)
                hoveredID = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 32)
            }
            .buttonStyle(.borderless)
            .focused($removeFocusedID, equals: token.id)
            .opacity(hoveredID == token.id || removeFocusedID == token.id ? 1 : 0)
            .allowsHitTesting(hoveredID == token.id || removeFocusedID == token.id)
            .accessibilityLabel("Remove \(token.name)")
            .help("Remove \(token.name)")
        }
        .padding(.horizontal, 8)
        .frame(height: 56)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                hoveredID = token.id
            } else if hoveredID == token.id {
                hoveredID = nil
            }
        }
    }
}
