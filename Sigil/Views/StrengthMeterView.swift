import SwiftUI

struct StrengthMeterView: View {
    let strength: PasswordStrength
    var compact: Bool = false

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    private var compactView: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1)
                    .fill(idx < strength.fillCount ? strength.color : Color.secondary.opacity(0.2))
                    .frame(width: 4, height: 10)
            }
        }
    }

    private var fullView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(idx < strength.fillCount ? strength.color : Color.secondary.opacity(0.15))
                        .frame(height: 4)
                }
            }
            if !strength.label.isEmpty {
                Text(strength.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(strength.color)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: strength)
    }
}
