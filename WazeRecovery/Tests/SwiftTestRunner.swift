import Foundation
import XCTest

class ConsoleTestObserver: NSObject, XCTestObservation {
    func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        print("  [FAIL] \(testCase.name): \(description) at line \(lineNumber)")
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        if testCase.testRun?.hasSucceeded == true {
            print("  [PASS] \(testCase.name)")
        }
    }
}

print("================================================================================")
print("RUNNING RECONSTRUCTED SWIFT XCTEST UNIT TEST SUITE")
print("================================================================================")

let observer = ConsoleTestObserver()
XCTestObservationCenter.shared.addTestObserver(observer)

let suite = XCTestSuite(name: "WazeRecoveryAllTests")
suite.addTest(AlternateRoutesStateMachineTests.defaultTestSuite)
suite.addTest(NavigationGuidanceReducerTests.defaultTestSuite)
suite.addTest(KeychainStorageTests.defaultTestSuite)
suite.addTest(HazardAlertTests.defaultTestSuite)
suite.addTest(SearchEngineTests.defaultTestSuite)

suite.run()

let totalTests = suite.testRun?.executionCount ?? 0
let failureCount = suite.testRun?.failureCount ?? 0

if failureCount == 0 && totalTests > 0 {
    print("================================================================================")
    print("ALL SWIFT XCTEST UNIT TESTS PASSED SUCCESSFULLY (\(totalTests) tests executed, 0 failures)")
    print("================================================================================")
    exit(0)
} else {
    print("FATAL: \(failureCount) Swift unit test(s) failed out of \(totalTests) executed.")
    exit(1)
}
