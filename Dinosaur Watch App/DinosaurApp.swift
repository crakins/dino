//
//  DinosaurApp.swift
//  Dinosaur Watch App
//
//  Created by Christopher Akins on 1/9/26.
//

import SwiftUI

@main
struct Dinosaur_Watch_AppApp: App {
    init() {
        #if DEBUG
        if ScreenshotScene.current != nil {
            ScreenshotScene.seedDefaults()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
