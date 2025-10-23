//
//  +Color.swift
//  swebftcord
//
//  Created by mugman on 10/10/25.
//
import SwiftUI

/// https://stackoverflow.com/a/62632214
extension Color {
    init(hue: Double, saturation: Double, lightness: Double, opacity: Double) {
        precondition(0...1 ~= hue &&
                     0...1 ~= saturation &&
                     0...1 ~= lightness &&
                     0...1 ~= opacity, "input range is out of range 0...1")

        //From HSL TO HSB ---------
        var newSaturation: Double = 0.0

        let brightness = lightness + saturation * min(lightness, 1-lightness)

        if brightness == 0 { newSaturation = 0.0 }
        else {
            newSaturation = 2 * (1 - lightness / brightness)
        }
        //---------

        self.init(hue: hue, saturation: newSaturation, brightness: brightness, opacity: opacity)
    }

    init?(stringorint color: StringOrInt?) {
        switch color {
        case .string(let col):
            if let match = try? hslaRegex.wholeMatch(in: col) {
                let (_, sh, ss, sl, so) = match.output
                if let h = Double(sh),
                   let s = Double(ss),
                   let l = Double(sl),
                   let o = Double(so) {
                    self.init(hue: h/360, saturation: s/100, lightness: l/100, opacity: o)
                }
            }
        case .int(let num):
            let alpha = Double((num >> 24) & 0xFF)
            let red = Double((num >> 16) & 0xFF)
            let green = Double((num >> 8) & 0xFF)
            let blue = Double(num & 0xFF)
            self.init(red: red/255, green: green/255, blue: blue/255, opacity: alpha/255)
        default:
            return nil
        }
        return nil
    }
}
