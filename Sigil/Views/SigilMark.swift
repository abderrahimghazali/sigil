import SwiftUI

struct SigilMark: View {
    var size: CGFloat = 20
    var cornerRadius: CGFloat? = nil
    var showsBackground: Bool = true

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.26, style: .continuous)
                    .fill(Color(red: 0.42, green: 0.55, blue: 0.60))
            }

            Image(systemName: "lock.shield.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.white)
                .frame(width: size * 0.66, height: size * 0.66)
        }
        .frame(width: size, height: size)
    }
}
