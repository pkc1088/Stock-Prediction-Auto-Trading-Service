//
//  AutoTradingApp.swift
//  AutoTrading
//
//  Created by loyH on 2/26/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct AutoTradingApp: App {
    var body: some Scene {
        WindowGroup {
            MainNavigation(store: Store(initialState: MainFeature.State(), reducer: {
                MainFeature()
            }))
        }
    }
}
