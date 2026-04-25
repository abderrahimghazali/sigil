import SwiftUI

enum PasswordStrength: Int, Comparable {
    case empty = 0
    case weak = 1
    case fair = 2
    case good = 3
    case strong = 4
    case excellent = 5

    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .empty: return ""
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        case .excellent: return "Excellent"
        }
    }

    var color: Color {
        switch self {
        case .empty: return .secondary
        case .weak: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return .green
        case .excellent: return .mint
        }
    }

    var fillCount: Int {
        switch self {
        case .empty: return 0
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        case .excellent: return 5
        }
    }
}
