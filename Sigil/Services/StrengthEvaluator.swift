import Foundation

enum StrengthEvaluator {
    private static let commonPasswords: Set<String> = [
        "password", "12345678", "123456789", "qwerty", "abc123",
        "letmein", "welcome", "monkey", "dragon", "master",
        "iloveyou", "admin", "passw0rd", "password1", "qwerty123"
    ]

    static func evaluate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .empty }

        let lower = password.lowercased()
        if commonPasswords.contains(lower) || password.count < 6 {
            return .weak
        }

        let entropy = entropyBits(password)
        switch entropy {
        case ..<28: return .weak
        case 28..<48: return .fair
        case 48..<64: return .good
        case 64..<80: return .strong
        default: return .excellent
        }
    }

    private static func entropyBits(_ password: String) -> Double {
        var poolSize = 0
        var hasLower = false, hasUpper = false, hasDigit = false, hasSymbol = false

        for char in password {
            if char.isLowercase { hasLower = true }
            else if char.isUppercase { hasUpper = true }
            else if char.isNumber { hasDigit = true }
            else { hasSymbol = true }
        }

        if hasLower { poolSize += 26 }
        if hasUpper { poolSize += 26 }
        if hasDigit { poolSize += 10 }
        if hasSymbol { poolSize += 27 }

        guard poolSize > 0 else { return 0 }
        let raw = Double(password.count) * log2(Double(poolSize))

        let unique = Set(password).count
        let repetitionPenalty = Double(unique) / Double(password.count)
        return raw * repetitionPenalty
    }
}
