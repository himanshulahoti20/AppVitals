import AppVitalsCore
import AppVitalsStorage
import Charts
import SwiftUI

// MARK: - Memory tab root

struct MemoryTabView: View {
    let snapshots: [MemorySnapshot]
    let objectStats: [ObjectLifecycleStats]
    let streamStats: [StreamStats]
    let viewRebuildStats: [ViewRebuildStats]

    var body: some View {
        List {
            if !snapshots.isEmpty {
                Section("Memory Usage") {
                    MemoryChartView(snapshots: snapshots)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }

            if !objectStats.isEmpty {
                Section("Object Lifecycle") {
                    ForEach(objectStats, id: \.name) { stat in
                        ObjectLifecycleRow(stat: stat)
                    }
                }
            }

            if !streamStats.isEmpty {
                Section("Active Streams / Listeners") {
                    ForEach(streamStats, id: \.name) { stat in
                        StreamStatsRow(stat: stat)
                    }
                }
            }

            if !viewRebuildStats.isEmpty {
                Section("View Rebuilds") {
                    ForEach(viewRebuildStats) { stat in
                        ViewRebuildRow(stat: stat)
                    }
                }
            }

            if snapshots.isEmpty, objectStats.isEmpty, streamStats.isEmpty, viewRebuildStats.isEmpty {
                ContentUnavailableView(
                    "No Memory Data",
                    systemImage: "memorychip",
                    description: Text(
                        "Enable memory monitoring in your AppVitalsConfiguration, " +
                            "or use AppVitals.trackLifetime, trackStream, and .trackRebuilds."
                    )
                )
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Memory chart

private struct MemoryChartView: View {
    let snapshots: [MemorySnapshot]

    private var currentMB: Double {
        snapshots.last?.usedMB ?? 0
    }

    private var peakMB: Double {
        snapshots.map(\.usedMB).max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f MB", currentMB))
                    .font(.title2.monospacedDigit().weight(.semibold))
                Text("current")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "Peak %.1f MB", peakMB))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Chart(snapshots) { snapshot in
                AreaMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("MB", snapshot.usedMB)
                )
                .foregroundStyle(.blue.opacity(0.15))
                LineMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("MB", snapshot.usedMB)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartXAxis(.hidden)
            .chartYAxisLabel("MB", position: .trailing)
            .frame(height: 80)
            .padding(.horizontal)

            Divider()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Object lifecycle row

private struct ObjectLifecycleRow: View {
    let stat: ObjectLifecycleStats

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(stat.name)
                    .font(.body)
                HStack(spacing: 12) {
                    Text("\(stat.created) created")
                    Text("\(stat.disposed) disposed")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if stat.active > 0 {
                Text("\(stat.active) alive")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.12), in: Capsule())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Stream stats row

private struct StreamStatsRow: View {
    let stat: StreamStats

    var body: some View {
        HStack {
            Label(stat.name, systemImage: "waveform.path")
                .font(.body)
            Spacer()
            Text("\(stat.activeCount) active")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - View rebuild row

private struct ViewRebuildRow: View {
    let stat: ViewRebuildStats

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(stat.name)
                    .font(.body)
                Text(stat.lastRebuildAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(stat.rebuildCount)")
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(rebuildColor)
        }
        .padding(.vertical, 2)
    }

    private var rebuildColor: Color {
        switch stat.rebuildCount {
        case ..<10: .primary
        case 10 ..< 50: .orange
        default: .red
        }
    }
}
