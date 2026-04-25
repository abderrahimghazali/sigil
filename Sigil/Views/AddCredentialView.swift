import SwiftUI

struct AddCredentialView: View {
    @ObservedObject var viewModel: CredentialsViewModel
    @Binding var isPresented: Bool
    var existing: Credential? = nil

    @State private var service = ""
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var revealed = false
    @State private var showingGenerator = false
    @State private var error: String?

    private var isEditing: Bool { existing != nil }
    private var strength: PasswordStrength { StrengthEvaluator.evaluate(password) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Credential" : "New Credential")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 16) {
                    Button(action: { showingGenerator = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                            Text("Generate strong password")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 10) {
                        Rectangle().fill(.quaternary).frame(height: 1)
                        Text("CREDENTIAL DETAILS")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .tracking(1)
                        Rectangle().fill(.quaternary).frame(height: 1)
                    }

                    VStack(spacing: 12) {
                        SigilField(label: "SERVICE", text: $service, placeholder: "GitHub, Google, AWS...")
                        SigilField(label: "USERNAME", text: $username, placeholder: "user@example.com")
                        passwordField
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
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                Button(isEditing ? "Save" : "Add Credential") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .controlSize(.regular)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 340, height: 440)
        .onAppear(perform: prefillIfEditing)
        .sheet(isPresented: $showingGenerator) {
            PasswordGeneratorView(isPresented: $showingGenerator) { generated in
                password = generated
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("PASSWORD")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .tracking(0.8)
                Spacer()
                Button(action: { revealed.toggle() }) {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            Group {
                if revealed {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
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

            StrengthMeterView(strength: strength)
        }
    }

    private func prefillIfEditing() {
        guard let existing else { return }
        service = existing.service
        username = existing.username
        url = existing.url
        notes = existing.notes
        password = viewModel.password(for: existing) ?? ""
    }

    private func save() {
        error = nil
        let trimmedService = service.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)

        guard !trimmedService.isEmpty, !password.isEmpty else {
            error = "Service and password are required"
            return
        }

        do {
            if let existing {
                var updated = existing
                updated.service = trimmedService
                updated.username = trimmedUsername
                updated.url = url.trimmingCharacters(in: .whitespaces)
                updated.notes = notes
                let originalPassword = viewModel.password(for: existing)
                let passwordChanged = password != (originalPassword ?? "")
                try viewModel.updateCredential(updated, password: passwordChanged ? password : nil)
            } else {
                try viewModel.addCredential(
                    service: trimmedService,
                    username: trimmedUsername,
                    password: password,
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
