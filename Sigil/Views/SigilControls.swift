import SwiftUI

enum SigilButtonVariant {
    case primary
    case secondary
    case subtle
}

struct SigilCommandButtonStyle: ButtonStyle {
    var variant: SigilButtonVariant = .secondary

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(
                background(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return .primary
        case .subtle: return .secondary
        }
    }

    private func background(isPressed: Bool) -> some ShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(Color.indigo.opacity(isPressed ? 0.85 : 1))
        case .secondary:
            return AnyShapeStyle(Color.primary.opacity(isPressed ? 0.10 : 0.06))
        case .subtle:
            return AnyShapeStyle(Color.primary.opacity(isPressed ? 0.07 : 0.035))
        }
    }
}

struct SigilIconButtonStyle: ButtonStyle {
    var isProminent = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isProminent ? Color.white : Color.secondary)
            .frame(width: 26, height: 26)
            .background(
                background(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func background(isPressed: Bool) -> some ShapeStyle {
        if isProminent {
            return AnyShapeStyle(Color.indigo.opacity(isPressed ? 0.85 : 1))
        }
        return AnyShapeStyle(Color.primary.opacity(isPressed ? 0.10 : 0.05))
    }
}

struct SigilKindSelector: View {
    @Binding var selection: CredentialKind
    @Namespace private var indicator

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("TYPE")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
                .tracking(0.8)

            HStack(spacing: 0) {
                ForEach(CredentialKind.allCases) { kind in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            selection = kind
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: symbol(for: kind))
                                .font(.system(size: 11, weight: .medium))
                            Text(kind.shortName)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .foregroundStyle(selection == kind ? Color.white : Color.secondary)
                        .background {
                            if selection == kind {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.indigo)
                                    .matchedGeometryEffect(id: "kind-indicator", in: indicator)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(kind.displayName)
                }
            }
            .padding(2)
            .background(
                Color.primary.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
        }
    }

    private func symbol(for kind: CredentialKind) -> String {
        switch kind {
        case .password: return "key.fill"
        case .apiToken: return "curlybraces"
        case .accessToken: return "person.badge.key.fill"
        case .secret: return "lock.fill"
        }
    }
}
