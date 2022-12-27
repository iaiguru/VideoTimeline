//
//  Int+Extension.swift
//  VideoTimeline
//
//  Created by hope on 12/24/22.
//

import Foundation

extension Int {
    var toHHMMSS: String {
        if self <= 0 {
            return "00:00"
        }
        
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = (self % 3600) % 60
        var formatted = ""
        
        if hours > 0 {
            formatted = hours < 10 ? "0\(hours):" : "\(hours):"
        }
        formatted += minutes < 10 ? "0\(minutes):" : "\(minutes):"
        formatted += seconds < 10 ? "0\(seconds)" : "\(seconds)"
        
        return formatted
    }
}
