import SwiftUI
import Charts

struct MenuBarView: View {
    @ObservedObject var manager: SpeedTestManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current speed
            if let latest = manager.results.last {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Download")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(latest.downloadMbps, specifier: "%.1f") Mbps")
                            .font(.title2.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Upload")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(latest.uploadMbps, specifier: "%.1f") Mbps")
                            .font(.title2.bold())
                    }
                }
                Text(latest.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                + Text(" ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Chart
            if manager.results.count >= 2 {
                SpeedChart(results: manager.results)
                    .frame(height: 140)
            } else {
                Text("Collecting data...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .center)
            }

            Divider()

            // Controls
            Button {
                manager.runTest()
            } label: {
                HStack {
                    Text(manager.isTesting ? "Testing..." : "Run Test Now")
                    Spacer()
                    if manager.isTesting {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(manager.isTesting)
            .buttonStyle(.plain)

            // Interval picker
            HStack {
                Text("Interval:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { manager.currentInterval },
                    set: { manager.setInterval($0) }
                )) {
                    ForEach(intervalOptions, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

struct SpeedChart: View {
    let results: [SpeedResult]

    private var axisDates: [Date] {
        guard let first = results.first, let last = results.last else {
            return []
        }
        return ChartAxisCalculator.roundedAxisDates(from: first.timestamp, to: last.timestamp)
    }

    var body: some View {
        Chart {
            ForEach(results) { result in
                LineMark(
                    x: .value("Time", result.timestamp),
                    y: .value("Mbps", result.downloadMbps)
                )
                .foregroundStyle(by: .value("Type", "Download"))

                LineMark(
                    x: .value("Time", result.timestamp),
                    y: .value("Mbps", result.uploadMbps)
                )
                .foregroundStyle(by: .value("Type", "Upload"))
            }
        }
        .chartForegroundStyleScale([
            "Download": .blue,
            "Upload": .green,
        ])
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                AxisValueLabel(format: .dateTime.hour().minute())
                    .font(.caption2)
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartLegend(position: .top, spacing: 8)
    }
}
