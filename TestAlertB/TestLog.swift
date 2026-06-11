//
//  TestLog.swift
//  TestAlertB
//
//  Created by linhao on 2026/6/11.
//

import Foundation

enum TestLog {

    static func log(
        _ message: @autoclosure () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        #if DEBUG
        print("___+++ [\(file):\(line)] \(function) | \(message())")
        #endif
    }

    func log() {
        Self.log("__")
    }
}
