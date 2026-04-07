//
//  TestMHCBApp.swift
//  TestMHCB
//
//  Created by David Headen on 12/14/25.
//

import SwiftUI

@main
struct TestMHCBApp: App {
    // This looks at UserDefaults for the key "isLoggedIn"
    // If it's true, the app will launch straight to the chatbot
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
           
                MentalHealthChatbotUI()
                    .transition(.opacity) // Smooth transition when switching
            }
        }
    }
