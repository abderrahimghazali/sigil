import Foundation

struct PasswordGeneratorOptions {
    var length: Int = 20
    var includeUppercase: Bool = true
    var includeLowercase: Bool = true
    var includeDigits: Bool = true
    var includeSymbols: Bool = true
    var avoidAmbiguous: Bool = true
}

enum PasswordGenerator {
    private static let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let lowercase = "abcdefghijklmnopqrstuvwxyz"
    private static let digits = "0123456789"
    private static let symbols = "!@#$%^&*()-_=+[]{};:,.<>?/~"
    private static let ambiguous: Set<Character> = ["0", "O", "o", "1", "l", "I", "|", "`", "'"]

    static func generate(_ options: PasswordGeneratorOptions) -> String {
        var pool = ""
        var requiredChars: [Character] = []

        if options.includeUppercase {
            pool += uppercase
            if let c = uppercase.randomElement() { requiredChars.append(c) }
        }
        if options.includeLowercase {
            pool += lowercase
            if let c = lowercase.randomElement() { requiredChars.append(c) }
        }
        if options.includeDigits {
            pool += digits
            if let c = digits.randomElement() { requiredChars.append(c) }
        }
        if options.includeSymbols {
            pool += symbols
            if let c = symbols.randomElement() { requiredChars.append(c) }
        }

        if pool.isEmpty {
            pool = lowercase
            if let c = lowercase.randomElement() { requiredChars.append(c) }
        }

        var filteredPool = pool
        if options.avoidAmbiguous {
            filteredPool = String(pool.filter { !ambiguous.contains($0) })
            requiredChars = requiredChars.filter { !ambiguous.contains($0) }
        }

        let length = max(options.length, requiredChars.count)
        var chars = requiredChars
        let poolArray = Array(filteredPool.isEmpty ? pool : filteredPool)

        while chars.count < length {
            if let c = poolArray.randomElement() {
                chars.append(c)
            }
        }

        chars.shuffle()
        return String(chars)
    }
}
