import AppVitalsCore
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
                    filterButton
                }
                ToolbarItem(placement: .automatic) {
                    ShareLink(item: exportContent) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $model.searchText)
            .task { await model.refresh() }
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
            NetworkListView(
                transactions: model.filteredTransactions,
                grouped: model.groupedByHost,
                isGrouped: model.isGroupedByHost
            )
        case .errors:
            EventListView(events: model.errors)
        case .timeline:
            TimelineListView(entries: model.timeline)
        }
    }

    private var exportContent: String {
        switch selection {
        case .logs: model.exportLogsText()
        case .network: model.exportNetworkText()
        case .errors: model.exportErrorsText()
        case .timeline: model.exportTimelineText()
        }
    }

    @ViewBuilder
    private var filterButton: some View {
        switch selection {
        case .logs:
            logFilterMenu
        case .network:
            networkFilterMenu
        default:
            EmptyView()
        }
    }

    private var logFilterMenu: some View {
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
    }

    private var networkFilterMenu: some View {
        Menu {
            Section("Method") {
                Button {
                    model.networkMethodFilter = nil
                } label: {
                    if model.networkMethodFilter == nil {
                        Label("All Methods", systemImage: "checkmark")
                    } else {
                        Text("All Methods")
                    }
                }
                ForEach(["GET", "POST", "PUT", "PATCH", "DELETE"], id: \.self) { method in
                    Button {
                        model.networkMethodFilter = method
                    } label: {
                        if model.networkMethodFilter == method {
                            Label(method, systemImage: "checkmark")
                        } else {
                            Text(method)
                        }
                    }
                }
            }
            Section("Status") {
                Button {
                    model.networkStatusFilter = nil
                } label: {
                    if model.networkStatusFilter == nil {
                        Label("All Status", systemImage: "checkmark")
                    } else {
                        Text("All Status")
                    }
                }
                ForEach(NetworkStatusFilter.allCases, id: \.self) { filter in
                    Button {
                        model.networkStatusFilter = filter
                    } label: {
                        if model.networkStatusFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            }
            Divider()
            Button {
                model.showSlowOnly.toggle()
            } label: {
                if model.showSlowOnly {
                    Label("Slow Requests Only (>2s)", systemImage: "checkmark")
                } else {
                    Text("Slow Requests Only (>2s)")
                }
            }
            Button {
                model.isGroupedByHost.toggle()
            } label: {
                if model.isGroupedByHost {
                    Label("Group by Host", systemImage: "checkmark")
                } else {
                    Text("Group by Host")
                }
            }
        } label: {
            Image(
                systemName: hasNetworkFilter
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
    }

    private var hasNetworkFilter: Bool {
        model.networkMethodFilter != nil || model.networkStatusFilter != nil
            || model.showSlowOnly || model.isGroupedByHost
    }
}

private enum ConsoleTab: CaseIterable {
    case logs, network, errors, timeline

    var title: String {
        switch self {
        case .logs: "Logs"
        case .network: "Network"
        case .errors: "Errors"
        case .timeline: "Timeline"
        }
    }

    var systemImage: String {
        switch self {
        case .logs: "list.bullet.rectangle"
        case .network: "network"
        case .errors: "exclamationmark.triangle"
        case .timeline: "clock.arrow.circlepath"
        }
    }
}
