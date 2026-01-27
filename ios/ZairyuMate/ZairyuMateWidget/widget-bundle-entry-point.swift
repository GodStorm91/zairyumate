//
//  widget-bundle-entry-point.swift
//  ZairyuMateWidget
//
//  Main entry point for widget extension bundle
//  Registers all available widgets for the app
//

import WidgetKit
import SwiftUI

/// Widget bundle registering all widgets for Zairyu Mate
@main
struct ZairyuMateWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
    }
}
