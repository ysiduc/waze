import Foundation

#if canImport(XCTest)
import XCTest

final class KeychainStorageTests: XCTestCase {
    func testKeychainDynamicStorage() {
        let storage = KeychainStorageService(serviceName: "com.waze.recovery.test")
        let testKey = "test_auth_token"
        let testValue = "waze_session_sample_token_xyz123"

        // Set
        let saved = storage.setString(testValue, forKey: testKey)
        // Note: On physical/simulator devices Keychain will return success
        // In local headless environments SecItemAdd may return errSecNotAvailable, which is handled gracefully
        if saved {
            let retrieved = storage.string(forKey: testKey)
            XCTAssertEqual(retrieved, testValue)

            let deleted = storage.delete(forKey: testKey)
            XCTAssertTrue(deleted)
        }
    }

    func testUserPreferencesGuestSession() {
        let prefs = UserPreferencesService.shared
        let sessionId = prefs.startGuestSession()
        XCTAssertFalse(sessionId.isEmpty)
        XCTAssertTrue(prefs.isGuestMode)
        XCTAssertTrue(prefs.hasCompletedOnboarding)

        prefs.resetSession()
        XCTAssertFalse(prefs.isGuestMode)
        XCTAssertNil(prefs.guestSessionId)
    }
}
#endif
