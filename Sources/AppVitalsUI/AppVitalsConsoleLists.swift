import AppVitalsCore
import AppVitalsNetwork
import Charts
import SwiftUI

// MARK: - Logs / Errors

struct EventListView: View {
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

// MARK: - Network

struct NetworkListView: View {
    let transactions: [NetworkTransaction]
    let grouped: [(host: String, transactions: [NetworkTransaction])]
    let isGrouped: Bool

    var body: some View {
        Group {
            if isGrouped {
                groupedList
            } else {
                flatList
            }
        }
        .overlay {
            if transactions.isEmpty {
                ContentUnavailableView("No Requests", systemImage: "network")
            }
        }
    }

    private var flatList: some View {
        List {
            if !transactions.isEmpty {
                Section {
                    LatencyChartView(transactions: transactions)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }
            ForEach(transactions) { tx in
                NavigationLink {
                    NetworkDetailView(transaction: tx)
                } label: {
                    NetworkRowView(transaction: tx)
                }
            }
        }
        .listStyle(.plain)
    }

    private var groupedList: some View {
        List {
            ForEach(grouped, id: \.host) { group in
                Section(group.host) {
                    ForEach(group.transactions) { tx in
                        NavigationLink {
                            NetworkDetailView(transaction: tx)
                        } label: {
                            NetworkRowView(transaction: tx)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct NetworkRowView: View {
    let transaction: NetworkTransaction

    var body: some View {
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
                        .foregroundStyle(duration > 2.0 ? .orange : .secondary)
                }
            }
            Text(transaction.request.url.absoluteString)
                .font(.callout)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
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

private struct LatencyChartView: View {
    let transactions: [NetworkTransaction]

    private struct ChartPoint: Identifiable {
        let id: Int
        let duration: Double
    }

    private var points: [ChartPoint] {
        Array(
            transactions.prefix(20).reversed().enumerated()
                .map { ChartPoint(id: $0.offset, duration: $0.element.duration ?? 0) }
        )
    }

    var body: some View {
        if !transactions.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Latency — last \(min(transactions.count, 20)) requests")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Chart(points) { point in
                    BarMark(
                        x: .value("Request", point.id),
                        y: .value("Duration (s)", point.duration)
                    )
                    .foregroundStyle(barColor(point.duration))
                }
                .chartXAxis(.hidden)
                .chartYAxisLabel("sec", position: .trailing)
                .frame(height: 72)
                .padding(.horizontal)
                Divider()
            }
            .padding(.top, 8)
        }
    }

    private func barColor(_ duration: Double) -> Color {
        if duration > 3.0 { return .red }
        if duration > 1.0 { return .orange }
        return .blue
    }
}
