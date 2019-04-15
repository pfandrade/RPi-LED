import XCTest

import ledTests

var tests = [XCTestCaseEntry]()
tests += ledTests.allTests()
XCTMain(tests)