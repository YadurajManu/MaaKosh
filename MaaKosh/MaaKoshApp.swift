//
//  MaaKoshApp.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import Firebase

@main
struct MaaKoshApp: App {
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
    }
}
