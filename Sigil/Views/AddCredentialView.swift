import SwiftUI

struct AddCredentialView: View {
    @ObservedObject var viewModel: CredentialsViewModel
    @Binding var isPresented: Bool
    var existing: Credential? = nil

    @State private var kind: CredentialKind = .password
    @State private var service = ""
    @State private var username = ""
    @State private var secret = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var revealed = false
    @State private var showingGenerator = false
    @State private var error: String?

    private var isEditing: Bool { existing != nil }
    private var strength: PasswordStrength { StrengthEvaluator.evaluate(secret) }

    var body: some View {
        ZStack {
            if showingGenerator {
                PasswordGeneratorView(isPresented: $showingGenerator) { generated in
                    secret = generated
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                formView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 340, height: 440)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: showingGenerator)
        .onAppear(perform: prefillIfEditing)
    }

    private var formView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit \(kind.displayName)" : "New Credential")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(SigilIconButtonStyle())
                .help("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        typePicker
                        SigilField(label: "SERVICE", text: $service, placeholder: kind.servicePlaceholder)
                        SigilField(label: kind.accountLabel, text: $username, placeholder: kind.accountPlaceholder)
                        secretField
                        SigilField(label: "URL (OPTIONAL)", text: $url, placeholder: "https://example.com")
                        SigilField(label: "NOTES (OPTIONAL)", text: $notes, placeholder: "Any extra info", multiline: true)
                    }

                    if let error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(error)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Divider().opacity(0.3)

            HStack(spacing: 10) {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(SigilCommandButtonStyle(variant: .secondary))

                Button(isEditing ? "Save" : "Add Credential") { save() }
                    .buttonStyle(SigilCommandButtonStyle(variant: .primary))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private var typePicker: some View {
        SigilKindSelector(selection: $kind)
    }

    private var secretField: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(kind.secretLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .tracking(0.8)
                Spacer()
                if kind == .password {
                    Button(action: { showingGenerator = true }) {
                        Image(systemName: "lock.rotation")
                    }
                    .buttonStyle(SigilIconButtonStyle())
                    .help("Generate password")
                }
                Button(action: { revealed.toggle() }) {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                }
                .buttonStyle(SigilIconButtonStyle())
                .help(revealed ? "Hide" : "Reveal")
            }

            Group {
                if revealed {
                    TextField(kind.secretPlaceholder, text: $secret)
                } else {
                    SecureField(kind.secretPlaceholder, text: $secret)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )

            if kind == .password {
                StrengthMeterView(strength: strength)
            }
        }
    }

    private func prefillIfEditing() {
        guard let existing else { return }
        kind = existing.kind
        service = existing.service
        username = existing.username
        url = existing.url
        notes = existing.notes
        secret = viewModel.secret(for: existing) ?? ""
    }

    private func save() {
        error = nil
        let trimmedService = service.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)

        guard !trimmedService.isEmpty, !secret.isEmpty else {
            error = "Service and \(kind.secretLabel.lowercased()) are required"
            return
        }

        do {
            if let existing {
                var updated = existing
                updated.kind = kind
                updated.service = trimmedService
                updated.username = trimmedUsername
                updated.url = url.trimmingCharacters(in: .whitespaces)
                updated.notes = notes
                let originalSecret = viewModel.secret(for: existing)
                let secretChanged = secret != (originalSecret ?? "")
                try viewModel.updateCredential(updated, secret: secretChanged ? secret : nil)
            } else {
                try viewModel.addCredential(
                    kind: kind,
                    service: trimmedService,
                    username: trimmedUsername,
                    secret: secret,
                    url: url.trimmingCharacters(in: .whitespaces),
                    notes: notes
                )
            }
            isPresented = false
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SigilField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
                .tracking(0.8)

            Group {
                if multiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
        }
    }
}
