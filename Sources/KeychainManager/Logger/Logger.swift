//
//  Logger.swift
//  KeychainManager
//
//  Created by Saad Tahir on 3/27/25.
//

import Foundation
import os

class Logger {
    private let subsystem: String
    private let category: String
    private let log: OSLog

    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
        self.log = OSLog(subsystem: subsystem, category: category)
    }

    /// Basic logging method (default log level)
    func log(_ message: String) {
        os_log("%{public}@", log: log, type: .default, message)
    }

    /// Info level logging
    func info(_ message: String) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    /// Debug level logging
    func debug(_ message: String) {
        os_log("%{public}@", log: log, type: .debug, message)
    }

    /// Error level logging
    func error(_ message: String) {
        os_log("%{public}@", log: log, type: .error, message)
    }

    /// Fault level logging (for critical issues)
    func fault(_ message: String) {
        os_log("%{public}@", log: log, type: .fault, message)
    }

    /// Log message with arguments (example: username, status)
    func log(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .default, args)
    }

    /// Info level logging with arguments
    func info(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .info, args)
    }

    /// Debug level logging with arguments
    func debug(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .debug, args)
    }

    /// Error level logging with arguments
    func error(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .error, args)
    }

    /// Fault level logging with arguments
    func fault(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .fault, args)
    }
}
