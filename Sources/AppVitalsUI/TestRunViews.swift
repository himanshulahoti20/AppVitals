import AppVitalsCore
import SwiftUI

struct TestRunListView: View {
    let runs: [TestRun]
    let model: AppVitalsConsoleModel

    var body: some View {
        List(runs) { run in
            NavigationLink {
                TestRunDetailView(run: run, model: model)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon(run.status))
                        .foregroundStyle(color(run.status))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.name).font(.callout)
                        Text(run.kind.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let duration = run.duration {
                        Text(String(format: "%.2fs", duration))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if runs.isEmpty {
                ContentUnavailableView("No Test Runs", systemImage: "checklist")
            }
        }
    }
}

private struct TestRunDetailView: View {
    let run: TestRun
    let model: AppVitalsConsoleModel
    @State private var report: TestReport?

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Status", value: run.status.rawValue.capitalized)
                LabeledContent("Kind", value: run.kind.rawValue.capitalized)
                if let failure = run.failureMessage {
                    Text(failure).foregroundStyle(.red).textSelection(.enabled)
                }
            }
            if let report {
                Section("Performance") {
                    LabeledContent("Requests", value: "\(report.performance.requestCount) (\(report.performance.slowRequests) slow)")
                    LabeledContent("Frame drops", value: "\(report.performance.frameDrops)")
                    if let peak = report.performance.peakMemoryMB {
                        LabeledContent("Peak memory", value: String(format: "%.1f MB", peak))
                    }
                    if let delta = report.performance.memoryDeltaMB {
                        LabeledContent("Memory delta", value: String(format: "%+.1f MB", delta))
                    }
                }
                Section("Timeline") {
                    ForEach(entries(report)) { entry in
                        switch entry {
                        case let .event(event): EventTimelineRow(event: event)
                        case let .transaction(tx): NetworkTimelineRow(transaction: tx)
                        }
                    }
                }
            }
        }
        .navigationTitle(run.name)
        .toolbar {
            if let report {
                ToolbarItem(placement: .automatic) {
                    ShareLink(item: report.plainText()) {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .task { report = await model.report(for: run) }
    }

    private func entries(_ report: TestReport) -> [TimelineEntry] {
        (report.events.map(TimelineEntry.event) + report.transactions.map(TimelineEntry.transaction))
            .sorted { $0.timestamp < $1.timestamp }
    }
}

private func icon(_ status: TestStatus) -> String {
    switch status {
    case .running: "hourglass"
    case .passed: "checkmark.circle.fill"
    case .failed: "xmark.octagon.fill"
    }
}

private func color(_ status: TestStatus) -> Color {
    switch status {
    case .running: .secondary
    case .passed: .green
    case .failed: .red
    }
}
