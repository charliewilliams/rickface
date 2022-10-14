//
//  RickWatchApp.swift
//  RickWatch Watch App
//
//  Created by Charlie Williams on 13/10/2022.
//

import SwiftUI

@main
struct RickWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            WatchView(face: Face.random())
        }
    }
}
