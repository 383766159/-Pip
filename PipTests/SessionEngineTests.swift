import XCTest
@testable import Pip

final class SessionEngineTests: XCTestCase {
    func testFixedConfigurationIsThreeThreeEightAnd48Seconds() {
        let configuration = SessionConfiguration()

        XCTAssertEqual(configuration.liftDuration, 3)
        XCTAssertEqual(configuration.releaseDuration, 3)
        XCTAssertEqual(configuration.repetitionCount, 8)
        XCTAssertEqual(configuration.totalDuration, 48)
    }

    func testStageSequenceEmitsLiftAndReleaseHapticsForEightRepetitions() {
        var engine = SessionEngine()

        XCTAssertEqual(engine.start(), [.haptic(.lift)])
        XCTAssertEqual(engine.phase, .lift(repetition: 1))

        for repetition in 1...8 {
            XCTAssertEqual(engine.phase, .lift(repetition: repetition))
            XCTAssertEqual(engine.advance(by: 3), [.haptic(.release)])
            XCTAssertEqual(engine.phase, .release(repetition: repetition))

            if repetition < 8 {
                XCTAssertEqual(engine.advance(by: 3), [.haptic(.lift)])
                XCTAssertEqual(engine.completedRepetitions, repetition)
            } else {
                XCTAssertEqual(engine.advance(by: 3), [.haptic(.success), .completed])
                XCTAssertEqual(engine.completedRepetitions, 8)
                XCTAssertEqual(engine.phase, .completed)
            }
        }

        XCTAssertEqual(engine.activeSeconds, 48)
        XCTAssertTrue(engine.isCompleted)
    }

    func testPauseAndResumePreservePositionWithoutCompletion() {
        var engine = SessionEngine()

        _ = engine.start()
        _ = engine.advance(by: 2)
        XCTAssertEqual(engine.pause(), [])
        XCTAssertEqual(engine.phase, .paused)
        XCTAssertEqual(engine.activeSeconds, 2)
        XCTAssertEqual(engine.completedRepetitions, 0)

        XCTAssertEqual(engine.advance(by: 20), [])
        XCTAssertEqual(engine.phase, .paused)
        XCTAssertEqual(engine.activeSeconds, 2)

        XCTAssertEqual(engine.resume(), [])
        XCTAssertEqual(engine.phase, .lift(repetition: 1))
        XCTAssertEqual(engine.advance(by: 1), [.haptic(.release)])
        XCTAssertEqual(engine.phase, .release(repetition: 1))
        XCTAssertFalse(engine.isCompleted)
    }

    func testPauseAndCancelDoNotEmitCompletionEventOrCountSignal() {
        var pausedEngine = SessionEngine()
        _ = pausedEngine.start()
        _ = pausedEngine.advance(by: 6)
        _ = pausedEngine.pause()

        XCTAssertFalse(pausedEngine.isCompleted)
        XCTAssertEqual(pausedEngine.completedRepetitions, 1)
        XCTAssertEqual(pausedEngine.advance(by: 48), [])

        var cancelledEngine = SessionEngine()
        _ = cancelledEngine.start()
        _ = cancelledEngine.advance(by: 3)
        XCTAssertEqual(cancelledEngine.cancel(), [])
        XCTAssertEqual(cancelledEngine.phase, .cancelled)
        XCTAssertFalse(cancelledEngine.isCompleted)
        XCTAssertEqual(cancelledEngine.advance(by: 48), [])
    }

    func testCompleteIsNoOpBeforeEightRepetitionsAndEmitsOnlyOnceAtTheEnd() {
        var engine = SessionEngine()

        _ = engine.start()
        XCTAssertEqual(engine.complete(), [])
        XCTAssertEqual(engine.phase, .lift(repetition: 1))

        XCTAssertEqual(engine.advance(by: 47).filter { $0 == .completed }, [])
        XCTAssertEqual(engine.phase, .release(repetition: 8))
        XCTAssertFalse(engine.isCompleted)

        XCTAssertEqual(engine.advance(by: 1), [.haptic(.success), .completed])
        XCTAssertEqual(engine.complete(), [])
        XCTAssertEqual(engine.phase, .completed)
    }
}
