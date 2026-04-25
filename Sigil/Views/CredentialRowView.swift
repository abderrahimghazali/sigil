import SwiftUI
import AppKit

struct CredentialRowView: View {
    let credential: Credential
    let loadSecret: () -> String?
    let onDelete: () -> Void
    let onEdit: () -> Void

    @State private var copied: CopiedField?
    @State private var hovering = false
    @State private var revealed = false
    @State private var revealedSecret: String?

    private enum CopiedField {
        case username, secret
    }

    var body: some View {
        HStack(spacing: 10) {
            serviceIcon

            VStack(alignment: .leading, spacing: 1) {
                Text(credential.service)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(usernameDisplay)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            trailingContent
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? Color.white.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { copySecret() }
        .contextMenu {
            Button(credential.kind.copyTitle) { copySecret() }
            Button("Copy Username") { copyUsername() }
            if !credential.url.isEmpty {
                Button("Open URL") { openURL() }
            }
            Divider()
            Button("Edit") { onEdit() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
        .animation(.easeInOut(duration: 0.15), value: hovering)
        .animation(.spring(duration: 0.3), value: copied)
        .animation(.easeInOut(duration: 0.15), value: revealed)
    }

    private var usernameDisplay: String {
        credential.username.isEmpty ? "—" : credential.username
    }

    @ViewBuilder
    private var trailingContent: some View {
        if let copied {
            copiedBadge(copied)
        } else if hovering {
            hoverActions
        } else if revealed, let revealedSecret {
            Text(revealedSecret)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 110, alignment: .trailing)
        } else if let strength {
            StrengthMeterView(strength: strength, compact: true)
        } else {
            typeBadge
        }
    }

    private var hoverActions: some View {
        HStack(spacing: 4) {
            iconButton(systemName: "person", tooltip: "Copy username") { copyUsername() }
            iconButton(systemName: revealed ? "eye.slash" : "eye", tooltip: revealed ? "Hide" : "Reveal") {
                toggleReveal()
            }
            iconButton(systemName: "doc.on.doc", tooltip: credential.kind.copyTitle) { copySecret() }
        }
    }

    private func iconButton(systemName: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(SigilIconButtonStyle())
        .help(tooltip)
    }

    private var serviceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(colorForService.opacity(0.12))
                .frame(width: 30, height: 30)
            Text(String(credential.service.prefix(1)).uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(colorForService)
        }
    }

    private func copiedBadge(_ field: CopiedField) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
            Text(field == .username ? "Username" : "Copied")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.green)
        .transition(.scale.combined(with: .opacity))
    }

    private var typeBadge: some View {
        Text(credential.kind.shortName)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 0.8)
            )
    }

    private var colorForService: Color {
        let hue = Double(credential.service.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 360) / 360.0
        return Color(hue: hue, saturation: 0.5, brightness: 0.8)
    }

    private var strength: PasswordStrength? {
        guard credential.kind == .password, let revealedSecret else { return nil }
        return StrengthEvaluator.evaluate(revealedSecret)
    }

    private func copySecret() {
        guard let secret = loadSecret() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(secret, forType: .string)
        copied = .secret
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = nil
        }
    }

    private func toggleReveal() {
        if revealed {
            revealed = false
            revealedSecret = nil
            return
        }

        guard let secret = loadSecret() else { return }
        revealedSecret = secret
        revealed = true
    }

    private func copyUsername() {
        guard !credential.username.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(credential.username, forType: .string)
        copied = .username
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = nil
        }
    }

    private func openURL() {
        var raw = credential.url
        if !raw.lowercased().hasPrefix("http") {
            raw = "https://" + raw
        }
        if let url = URL(string: raw) {
            NSWorkspace.shared.open(url)
        }
    }
}
