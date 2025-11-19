//
//  Item.swift
//  personalos-ios-v2
//
//  Created by Raki on 2025/11/20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
