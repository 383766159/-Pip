import SwiftData
import SwiftUI

@MainActor
public struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CalendarViewModel

    public init() {
        _viewModel = StateObject(wrappedValue: CalendarViewModel())
    }

    public init(viewModel: CalendarViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthHeader
                weekdayHeader
                monthGrid
                selectedDaySummary
            }
            .padding(20)
        }
        .navigationTitle("Calendar")
        .task {
            viewModel.load(context: modelContext)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pip completion calendar")
    }

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous month")

            Text(viewModel.monthTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)

            Button {
                viewModel.moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Next month")
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(Array(viewModel.monthDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayButton(for: date)
                } else {
                    Color.clear
                        .frame(height: 42)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func dayButton(for date: Date) -> some View {
        let count = viewModel.count(for: date)
        let isSelected = viewModel.selectedDayKey == StreakCalculator.dayKey(
            for: date,
            calendar: viewModel.calendar,
            timeZone: viewModel.timeZone
        )

        return Button {
            viewModel.select(date)
        } label: {
            VStack(spacing: 2) {
                Text(date, format: .dateTime.day())
                    .font(.body.monospacedDigit())
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PipTheme.mint)
                } else {
                    Text("–")
                        .font(.caption2)
                        .foregroundStyle(.clear)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? PipTheme.mint.opacity(0.22) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayAccessibilityLabel(for: date, count: count))
    }

    private var selectedDaySummary: some View {
        VStack(spacing: 6) {
            Text(viewModel.selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.headline)
            Text("\(viewModel.selectedDayCount) completed sessions")
                .font(.body)
            if viewModel.selectedDayStreak > 0 {
                Text("Streak ending this day: \(viewModel.selectedDayStreak) days")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text("Current streak: \(viewModel.currentStreakDays) days")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: PipTheme.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private func dayAccessibilityLabel(for date: Date, count: Int) -> String {
        let dateText = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        return count == 1
            ? "\(dateText), 1 completed session"
            : "\(dateText), \(count) completed sessions"
    }
}
