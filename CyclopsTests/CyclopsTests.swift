//
//  CyclopsTests.swift
//  CyclopsTests
//
//  Created by ka2n on 2015/12/02.
//  Copyright © 2015年 ka2n. All rights reserved.
//

import XCTest
@testable import Cyclops

class CyclopsTests: XCTestCase {
    
    func testJSON() {
        // Parse
        let cyclops = Cyclops(file: NSBundle(forClass: self.dynamicType).pathForResource("example", ofType: "json"))!
        
        XCTAssertEqual(cyclops.curves["example-scale"]!.duration, 1334.66800133467)
        let lastFrame = cyclops.curves["example-scale"]!.frames.last!
        XCTAssertEqual(lastFrame.time, 2068.73540206873)
        XCTAssertEqual(lastFrame.values.last!, 126.506024096386)
        
        // Generate animations
        XCTAssertNotNil(cyclops.animation("example-scale", ofProperty: Property.Scale))
        XCTAssertNotNil(cyclops.animation("example-position", ofProperty: Property.Position))
        XCTAssertNotNil(cyclops.animation("example-x rotation", ofProperty: Property.RotationX))
        XCTAssertNotNil(cyclops.animation("example-z rotation", ofProperty: Property.RotationZ))
    }
}
