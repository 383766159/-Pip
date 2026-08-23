import Foundation
import SwiftData
import UserNotifications

@MainActor
public final class ReminderSettingsViewModel: ObservableObject {
    @Published public private(set) var slots: [ReminderSlot] = []
    @Published public private(set) var isLoaded = false
    @Published public private(set) var isSaving = false
    @Published public private(set) var errorMessage: String?

    private var modelContext: ModelContext?
    private let scheduler: ReminderScheduler

    public init(scheduler: ReminderScheduler = ReminderScheduler()) {
        self.scheduler = scheduler
    }

    public func load(context: ModelContext) {
        guard !isLoaded else { return }
        modelContext = context

        do {
            let stored = try context.fetch(FetchDescriptor<ReminderSlot>())
            let normalized = Self.normalizedSlots(from: stored)
            let storedKeys = Set(stored.map(\.slotKey))
            let missingDefaults = normalized.filter { !storedKeys.contains($0.slotKey) }
            if !missingDefaults.isEmpty {
                missingDefaults.forEach(context.insert)
                try context.save()
            }
            slots = normalized
            isLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = "Reminders could not be loaded."
        }
    }

    public func time(for slotKey: String, calendar: Calendar = .current) -> Date {
        guard let slot = slot(for: slotKey) else { return Date() }
        var calendar = calendar
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(hour: slot.hour, minute: slot.minute)) ?? Date()
    }

    public func updateTime(for slotKey: String, date: Date, calendar: Calendar = .current) {
        guard let slot = slot(for: slotKey) else { return }
        let components = calendar.dateComponents([.hour, .minute], from: date)
        slot.hour = components.hour ?? slot.hour
        slot.minute = components.minute ?? slot.minute
        slot.updatedAt = Date()
        objectWillChange.send()
    }

    public func isWeekendEnabled(for slotKey: String) -> Bool {
        guard let slot = slot(for: slotKey) else { return false }
        return slot.weekdayMask & (1 << 5) != 0 || slot.weekdayMask & (1 << 6) != 0
    }

    public func setWeekendEnabled(_ enabled: Bool, for slotKey: String) {
        guard let slot = slot(for: slotKey) else { return }
        if enabled {
            slot.weekdayMask |= (1 << 5) | (1 << 6)
        } else {
            slot.weekdayMask &= ~((1 << 5) | (1 << 6))
        }
        slot.updatedAt = Date()
        objectWillChange.send()
    }

    public func setEnabled(_ enabled: Bool, for slotKey: String) {
        guard let slot = slot(for: slotKey) else { return }
        slot.isEnabled = enabled
        slot.updatedAt = Date()
        objectWillChange.send()
    }

    public func save() {
        guard let modelContext else {
            errorMessage = "Reminders are not ready yet."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try modelContext.save()
            scheduler.replaceScheduledReminders(with: slots) { [weak self] error in
                Task { @MainActor in
                    self?.errorMessage = error.map { _ in "Reminders could not be scheduled." }
                }
            }
            errorMessage = nil
        } catch {
            errorMessage = "Reminders could not be saved."
        }
    }

    public func slot(for slotKey: String) -> ReminderSlot? {
        slots.first { $0.slotKey == slotKey }
    }

    public static func normalizedSlots(from stored: [ReminderSlot]) -> [ReminderSlot] {
        let storedByKey = stored.reduce(into: [String: ReminderSlot]()) { result, slot in
            guard ReminderScheduler.slotKeys.contains(slot.slotKey), result[slot.slotKey] == nil else {
                return
            }
            result[slot.slotKey] = slot
        }
        let defaultsByKey = Dictionary(uniqueKeysWithValues: ReminderSlot.defaultSlots().map { ($0.slotKey, $0) })

        return ReminderScheduler.slotKeys.compactMap { key in
            if let existing = storedByKey[key] {
                return existing
            }
            return defaultsByKey[key]
        }
    }
}
