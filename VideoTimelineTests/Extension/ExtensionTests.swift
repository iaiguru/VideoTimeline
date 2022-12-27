//
//  ExtensionTests.swift
//  VideoTimelineTests
//
//  Created by hope on 12/24/22.
//

import XCTest
@testable import VideoTimeline

final class ExtensionTests: XCTestCase {

    func testIntToHHMMSS() {
        XCTAssertEqual((-1).toHHMMSS, "00:00")
        XCTAssertEqual(84.toHHMMSS, "01:24")
        XCTAssertEqual(3684.toHHMMSS, "01:01:24")
    }
    
    func testHexColorToUIColor() {
        XCTAssertEqual(UIColor(hex: "00000000"), nil)
        XCTAssertEqual(UIColor(hex: "#101010ff"), UIColor(red: 16/255, green: 16/255, blue: 16/255, alpha: 1))
        XCTAssertEqual(UIColor(hex: "#b92424ff"), UIColor(red: 185/255, green: 36/255, blue: 36/255, alpha: 1))
    }
}
