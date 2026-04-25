import SwiftUI

struct SigilMark: View {
    var size: CGFloat = 20
    var cornerRadius: CGFloat? = nil
    var showsBackground: Bool = true

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.26, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.34, green: 0.30, blue: 0.95), Color(red: 0.62, green: 0.32, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.26, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
                    .shadow(color: Color.indigo.opacity(0.35), radius: size * 0.15, y: size * 0.05)
            }

            Image(systemName: "lock.badge.checkmark.fill")
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
    }
}
