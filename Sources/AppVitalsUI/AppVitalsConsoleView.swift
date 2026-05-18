import AppVitalsCore
import AppVitalsNetwork
import AppVitalsStorage
import SwiftUI

public struct AppVitalsConsoleView: View {
    @State private var model: AppVitalsConsoleModel
    @State private var selection: ConsoleTab = .logs
    @Environment(\.dismiss) private var dismiss

    public init(stores: AppVitalsStores) {
        _model = State(initialValue: AppVitalsConsoleModel(stores: stores))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Console", selection: $selection) {
                    ForEach(ConsoleTab.allCases, id: \.self) { tab in
                        Label(tab.title, systemImage: tab.systemImage).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                content
                    .refreshable {
                        await model.refresh()
                    }
            }
            .navigationTitle("AppVitals")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    filterMenu
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $model.searchText)
            .task {
                await model.refresh()
            }
            .onChange(of: model.searchText) {
                Task { await model.refresh() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .logs:
            EventListView(events: model.events)
        case .network:
            NetworkListView(transactions: model.transactions)
        case .errors:
            EventListView(events: model.errors)
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                model.selectedCategory = nil
            } label: {
                if model.selectedCategory == nil {
                    Label("All Categories", systemImage: "checkmark")
                } else {
                    Text("All Categories")
                }
            }
            Divider()
            ForEach(AppVitalsEventCategory.allCases, id: \.self) { cat in
                Button {
                    model.selectedCategory = cat
                } label: {
                    if model.selectedCategory == cat {
                        Label(cat.rawValue.capitalized, systemImage: "checkmark")
                    } else {
                        Text(cat.rawValue.capitalized)
                    }
                }
            }
        } label: {
            Image(
                systemName: model.selectedCategory == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .disabled(selection != .logs)
        .opacity(selection == .logs ? 1 : 0.4)
    }
}

private enum ConsoleTab: CaseIterable {
    case logs
    case network
    case errors

    var title: String {
        switch self {
        case .logs: "Logs"
        case .network: "Network"
        case .errors: "Errors"
        }
    }

    var systemImage: String {
        switch self {
        case .logs: "list.bullet.rectangle"
        case .network: "network"
        case .errors: "exclamationmark.triangle"
        }
    }
}

private struct EventListView: View {
    let events: [AppVitalsEvent]

    var body: some View {
        List(events) { event in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.category.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color(for: event.level))
                    Spacer()
                    Text(event.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(event.message)
                    .font(.body)
                    .textSelection(.enabled)
                if !event.metadata.isEmpty {
                    Text(event.metadata.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "  "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .overlay {
            if events.isEmpty {
                ContentUnavailableView("No Logs", systemImage: "list.bullet.rectangle")
            }
        }
    }

    private func color(for level: AppVitalsLogLevel) -> Color {
        switch level {
        case .debug: .secondary
        case .info: .blue
        case .warning: .orange
        case .error: .red
        }
    }
}

private struct NetworkListView: View {
    let transactions: [NetworkTransaction]

    var body: some View {
        List(transactions) { transaction in
            NavigationLink {
                NetworkDetailView(transaction: transaction)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(transaction.request.method)
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(.blue)
                        Text(transaction.response.map { "\($0.statusCode)" } ?? "...")
                            .font(.caption.monospaced())
                            .foregroundStyle(statusColor(transaction.response?.statusCode))
                        Spacer()
                        if let duration = transaction.duration {
                            Text(duration, format: .number.precision(.fractionLength(3)))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(transaction.request.url.absoluteString)
                        .font(.callout)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .overlay {
            if transactions.isEmpty {
                ContentUnavailableView("No Requests", systemImage: "network")
            }
        }
    }

    private func statusColor(_ statusCode: Int?) -> Color {
        guard let statusCode else { return .secondary }
        switch statusCode {
        case 200 ..< 300: return .green
        case 300 ..< 400: return .blue
        case 400 ..< 500: return .orange
        default: return .red
        }
    }
}

private struct NetworkDetailView: View {
    let transaction: NetworkTransaction

    private var curlCommand: String {
        CURLGenerator.makeCommand(for: transaction.request)
    }

    var body: some View {
        List {
            Section("Request") {
                LabeledContent("Method", value: transaction.request.method)
                LabeledContent("URL", value: transaction.request.url.absoluteString)
                DisclosureGroup("Headers") {
                    KeyValueRows(values: transaction.request.headers)
                }
                if let body = transaction.request.body {
                    Text(NetworkBodyFormatter.displayString(from: body, contentType: transaction.request.headers["Content-Type"]))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            if let response = transaction.response {
                Section("Response") {
                    LabeledContent("Status", value: "\(response.statusCode)")
                    DisclosureGroup("Headers") {
                        KeyValueRows(values: response.headers)
                    }
                    if let body = response.body {
                        Text(NetworkBodyFormatter.displayString(from: body, contentType: response.headers["Content-Type"]))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            Section("cURL") {
                Text(curlCommand)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                Button {
                    copyToClipboard(curlCommand)
                } label: {
                    Label("Copy cURL", systemImage: "doc.on.doc")
                }
            }
        }
        .navigationTitle(transaction.request.method)
    }

    private func copyToClipboard(_ string: String) {
        #if canImport(UIKit)
            UIKit.UIPasteboard.general.string = string
        #elseif canImport(AppKit)
            AppKit.NSPasteboard.general.clearContents()
            AppKit.NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

private struct KeyValueRows: View {
    let values: [String: String]

    var body: some View {
        ForEach(values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
            LabeledContent(key, value: value)
        }
    }
}
