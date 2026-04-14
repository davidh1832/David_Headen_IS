//
//  TestMHCBApp.swift
//  TestMHCB
//
//  Created by David Headen on 12/14/25.
''' This file is the main entry point for the Swift app.'''

import SwiftUI

@main
struct TestMHCBApp: App {
    var body: some Scene {
        WindowGroup {
           
                MentalHealthChatbotUI()
                    .transition(.opacity)
            }
        }
    }
