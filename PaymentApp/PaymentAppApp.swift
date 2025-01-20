//
//  PaymentAppApp.swift
//  PaymentApp
//
//  Created by Vinnicius Pereira on 20/01/25.
//

import SwiftUI

@main
struct PaymentAppApp: App {
    var body: some Scene {
        WindowGroup {
            NumpadView()
                .preferredColorScheme(.light)
        }
    }
}
