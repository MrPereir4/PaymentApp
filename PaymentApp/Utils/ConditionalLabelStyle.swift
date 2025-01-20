//
//  ConditionalLabelStyle.swift
//  PaymentApp
//
//  Created by Vinnicius Pereira on 19/01/25.
//

import Foundation
import SwiftUI

struct ConditionalLabelStyle: LabelStyle {
    var showIcon: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if showIcon {
                configuration.icon
            }
            configuration.title
        }
    }
}
