import SwiftUI

enum RatingColors {
    static func color(for rating: Int) -> Color {
        switch rating {
        case 1...3: .red
        case 4...6: .yellow
        default: .green
        }
    }
}
