import SwiftUI
import AppKit

struct CredentialRowView: View {
    let credential: Credential
    let loadSecret: () -> String?
    let onDelete: () -> Void
    let onEdit: () -> Void

    @State private var copied: CopiedField?
    @State private var hovering = false
    @State private var secretPreview: String?
    @State private var confirmingDelete = false

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
            Button("Delete", role: .destructive) { confirmingDelete = true }
        }
        .animation(.easeInOut(duration: 0.15), value: hovering)
        .animation(.spring(duration: 0.3), value: copied)
        .onAppear(perform: loadSecretPreviewIfNeeded)
        .popover(isPresented: $confirmingDelete, arrowEdge: .trailing) {
            DeleteConfirmation(
                service: credential.service,
                onConfirm: {
                    confirmingDelete = false
                    onDelete()
                },
                onCancel: { confirmingDelete = false }
            )
        }
    }

    private var usernameDisplay: String {
        if !credential.username.isEmpty { return credential.username }
        if let secretPreview { return secretPreview }
        return "—"
    }

    private func loadSecretPreviewIfNeeded() {
        guard secretPreview == nil,
              credential.username.isEmpty,
              credential.kind == .apiToken || credential.kind == .accessToken,
              let secret = loadSecret() else { return }
        secretPreview = previewString(for: secret)
    }

    private func previewString(for secret: String) -> String {
        let trimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return trimmed.isEmpty ? "—" : trimmed }
        return "\(trimmed.prefix(4))…\(trimmed.suffix(4))"
    }

    @ViewBuilder
    private var trailingContent: some View {
        if let copied {
            copiedBadge(copied)
        } else if hovering {
            hoverActions
        } else {
            typeBadge
        }
    }

    private var hoverActions: some View {
        HStack(spacing: 4) {
            iconButton(systemName: "person", tooltip: "Copy username") { copyUsername() }
            iconButton(systemName: "doc.on.doc", tooltip: credential.kind.copyTitle) { copySecret() }
            iconButton(systemName: "trash", tooltip: "Delete") { confirmingDelete = true }
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

    private func copySecret() {
        guard let secret = loadSecret() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(secret, forType: .string)
        copied = .secret
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = nil
        }
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

private struct DeleteConfirmation: View {
    let service: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.red.opacity(0.10)))

                VStack(spacing: 2) {
                    Text("Delete credential?")
                        .font(.system(size: 12, weight: .semibold))
                    Text(service)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            HStack(spacing: 6) {
                Button(action: onCancel) {
                    Text("Cancel").frame(maxWidth: .infinity)
                }
                .buttonStyle(MinimalConfirmButton(role: .cancel))

                Button(action: onConfirm) {
                    Text("Delete").frame(maxWidth: .infinity)
                }
                .buttonStyle(MinimalConfirmButton(role: .destroy))
            }
        }
        .padding(16)
        .frame(width: 220)
    }
}

private struct MinimalConfirmButton: ButtonStyle {
    enum Role { case cancel, destroy }
    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .frame(height: 26)
            .foregroundStyle(foreground)
            .background(
                background(pressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch role {
        case .cancel: return .primary
        case .destroy: return .red
        }
    }

    private func background(pressed: Bool) -> some ShapeStyle {
        switch role {
        case .cancel:
            return AnyShapeStyle(Color.primary.opacity(pressed ? 0.10 : 0.05))
        case .destroy:
            return AnyShapeStyle(Color.red.opacity(pressed ? 0.20 : 0.10))
        }
    }
}
