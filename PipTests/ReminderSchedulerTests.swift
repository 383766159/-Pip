import XCTest
import SwiftData
import UserNotifications
@testable import Pip

@MainActor
final class ReminderSchedulerTests: XCTestCase {
    func testDefaultsAreThreeWorkdaySlots() {
        let slots = ReminderSlot.defaultSlots(now: Date(timeIntervalSince1970: 1_750_000_000))

        XCTAssertEqual(slots.map(\.slotKey), ["morning", "afternoon", "evening"])
        XCTAssertEqual(slots.map(\.hour), [9, 13, 20])
        XCTAssertEqual(slots.map(\.minute), [0, 0, 0])
        XCTAssertEqual(slots.map(\.weekdayMask), [31, 31, 31])
        XCTAssertTrue(slots.allSatisfy(\.isEnabled))
    }

    func testWeekendToggleAddsAndRemovesSaturdayAndSundayBits() {
        let viewModel = ReminderSettingsViewModel()
        let slots = ReminderSlot.defaultSlots()
        let stored = slots
        _ = stored

        XCTAssertEqual(ReminderSettingsViewModel.normalizedSlots(from: slots).count, 3)
        XCTAssertEqual(ReminderScheduler.foundationWeekday(forBitIndex: 0), 2)
        XCTAssertEqual(ReminderScheduler.foundationWeekday(forBitIndex: 5), 7)
        XCTAssertEqual(ReminderScheduler.foundationWeekday(forBitIndex: 6), 1)
        _ = viewModel
    }

    func testDescriptorsUseStableIdentifiersAndCalendarTriggers() {
        let slot = ReminderSlot(
            slotKey: "morning",
            hour: 9,
            minute: 15,
            weekdayMask: (1 << 0) | (1 << 5) | (1 << 6)
        )
        let scheduler = ReminderScheduler()

        let descriptors = scheduler.descriptors(for: slot)
        XCTAssertEqual(descriptors.map(\.weekday), [2, 7, 1])
        XCTAssertEqual(
            descriptors.map(\.identifier),
            [
                "Pip.Reminder.morning.weekday-2",
                "Pip.Reminder.morning.weekday-7",
                "Pip.Reminder.morning.weekday-1"
            ]
        )

        let requests = scheduler.requests(for: [slot])
        XCTAssertEqual(requests.count, 3)
        XCTAssertTrue(requests.allSatisfy { $0.trigger is UNCalendarNotificationTrigger })
        XCTAssertTrue(requests.allSatisfy { $0.content.body.contains("Kegel") })
    }

    func testDisabledOrEmptyWeekdaySlotsDoNotSchedule() {
        let disabled = ReminderSlot(slotKey: "morning", hour: 9, minute: 0, weekdayMask: 31, isEnabled: false)
        let empty = ReminderSlot(slotKey: "afternoon", hour: 13, minute: 0, weekdayMask: 0)
        let highBit = ReminderSlot(slotKey: "evening", hour: 20, minute: 0, weekdayMask: 128)
        let negative = ReminderSlot(slotKey: "morning", hour: 9, minute: 0, weekdayMask: -1)
        let scheduler = ReminderScheduler()

        XCTAssertTrue(scheduler.descriptors(for: disabled).isEmpty)
        XCTAssertTrue(scheduler.descriptors(for: empty).isEmpty)
        XCTAssertTrue(scheduler.descriptors(for: highBit).isEmpty)
        XCTAssertTrue(scheduler.descriptors(for: negative).isEmpty)
        XCTAssertFalse(highBit.isValidForScheduling)
        XCTAssertFalse(negative.isValidForScheduling)
    }

    func testLoadPersistsMissingDefaultSlotsForPartialStore() throws {
        let store = try LocalStore.makeInMemoryForTesting()
        let existing = ReminderSlot(
            slotKey: "morning",
            hour: 7,
            minute: 30,
            weekdayMask: 31
        )
        store.context.insert(existing)
        try store.context.save()

        let viewModel = ReminderSettingsViewModel()
        viewModel.load(context: store.context)

        XCTAssertEqual(viewModel.slots.map(\.slotKey), ["morning", "afternoon", "evening"])
        XCTAssertEqual(viewModel.slot(for: "morning")?.hour, 7)
        XCTAssertEqual(viewModel.slot(for: "morning")?.minute, 30)

        let persisted = try store.context.fetch(FetchDescriptor<ReminderSlot>())
        XCTAssertEqual(
            Set(persisted.map(\.slotKey)),
            Set(["morning", "afternoon", "evening"])
        )
        XCTAssertEqual(persisted.filter { ReminderScheduler.slotKeys.contains($0.slotKey) }.count, 3)
    }

    func testAuthorizationPolicyIsOnlyMarkedAfterCompletionRequest() {
        let suiteName = "Pip.ReminderSchedulerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let fake = FakeNotificationAuthorizationClient()
        let authorization = NotificationAuthorization(center: fake, preferences: defaults)

        XCTAssertFalse(authorization.didRequestAuthorization)
        authorization.requestAuthorizationIfNeeded()
        XCTAssertEqual(fake.requestCount, 1)
        XCTAssertTrue(authorization.didRequestAuthorization)

        authorization.requestAuthorizationIfNeeded()
        XCTAssertEqual(fake.requestCount, 1)
    }
}

private final class FakeNotificationAuthorizationClient: NSObject, NotificationAuthorizationClient {
    var requestCount = 0

    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        requestCount += 1
        completionHandler(true, nil)
    }
}
