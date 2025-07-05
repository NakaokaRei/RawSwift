// RawSwift.swift
// Main module file for RawSwift library

import Foundation

// Re-export public types for easy access
@_exported import libraw

// Public typealiases for convenience
public typealias LibRawData = libraw_data_t
public typealias LibRawError = LibRaw_errors

// Version information
public struct RawSwift {
    public static let version = "1.0.0"
    
    public static func libRawVersion() -> String {
        return Utils.librawVersion()
    }
}