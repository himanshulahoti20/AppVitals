import AppVitalsCore
import AppVitalsNetwork
import SwiftUI

// MARK: - Network Detail

struct NetworkDetailView: View {
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
                    if let duration = transaction.duration {
                        LabeledContent("Duration", value: String(format: "%.3fs", duration))
                    }
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

// MARK: - Timeline

struct TimelineListView: View {
    let entries: [TimelineEntry]

    var body: some View {
        List(entries) { entry in
            switch entry {
            case let .event(event):
                EventTimelineRow(event: event)
            case let .transaction(tx):
                NetworkTimelineRow(transaction: tx)
            }
        }
        .listStyle(.plain)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("No Activity", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}

private struct EventTimelineRow: View {
    let event: AppVitalsEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(levelColor)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(event.category.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(levelColor)
                    Spacer()
                    Text(event.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(event.message)
                    .font(.callout)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private var levelColor: Color {
        switch event.level {
        case .debug: .secondary
        case .info: .blue
        case .warning: .orange
        case .error: .red
        }
    }
}

private struct NetworkTimelineRow: View {
    let transaction: NetworkTransaction

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 4, height: 36)
                .foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(transaction.request.method)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(.blue)
                    if let status = transaction.response?.statusCode {
                        Text("\(status)")
                            .font(.caption.monospaced())
                            .foregroundStyle(statusColor)
                    } else {
                        Text("pending")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let duration = transaction.duration {
                        Text(String(format: "%.3fs", duration))
                            .font(.caption.monospaced())
                            .foregroundStyle(duration > 2.0 ? .orange : .secondary)
                    }
                    Spacer()
                    Text(transaction.startedAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(transaction.request.url.absoluteString)
                    .font(.callout)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        guard let code = transaction.response?.statusCode else { return .secondary }
        switch code {
        case 200 ..< 300: return .green
        case 300 ..< 400: return .blue
        case 400 ..< 500: return .orange
        default: return .red
        }
    }
}

// MARK: - Shared

private struct KeyValueRows: View {
    let values: [String: String]

    var body: some View {
        ForEach(values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
            LabeledContent(key, value: value)
        }
    }
}
