import SwiftUI

@inlinable
func contrastingTextColor(red: Double, green: Double, blue: Double) -> Color {
    let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
    return luminance > 0.65 ? .black : .white
}
