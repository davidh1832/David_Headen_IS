//
//  TestMHCBApp.swift
//  TestMHCB
//
//  Created by David Headen on 12/14/25.
''' This file is the main entry point for the Swift app.'''

import SwiftUI

@main
struct TestMHCBApp: App {
    // If isLoggedIn is true, the app will launch straight to the chatbot
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
           
                MentalHealthChatbotUI()
                    .transition(.opacity)
            }
        }
    }
