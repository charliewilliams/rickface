//
//  RickfaceApp.swift
//  Rickface
//
//  Created by Charlie Williams on 02/10/2022.
//

import SwiftUI

@main
struct RickfaceApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(face: Face.random())
        }
    }
}
