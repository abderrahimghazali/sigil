import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = CredentialsViewModel()
    @State private var showingAdd = false
    @State private var editingCredential: Credential?

    var body: some View {
        ZStack {
            if showingAdd {
                AddCredentialView(viewModel: viewModel, isPresented: $showingAdd)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if let editing = editingCredential {
                AddCredentialView(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { editingCredential != nil },
                        set: { if !$0 { editingCredential = nil } }
                    ),
                    existing: editing
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                listView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 340, height: 440)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: showingAdd)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: editingCredential)
        .alert(
            "Sigil",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            header

            if viewModel.credentials.count > 2 {
                searchBar
            }

            Divider().opacity(0.3)

            if viewModel.credentials.isEmpty {
                emptyState
            } else if viewModel.filteredCredentials.isEmpty {
                noResults
            } else {
                credentialList
            }

            Divider().opacity(0.3)

            footer
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 7) {
                SigilMark(size: 20, cornerRadius: 5)
                Text("Sigil")
                    .font(.system(size: 13, weight: .semibold))
                if let version = appVersion {
                    Text(version)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
            Spacer()
            HStack(spacing: 5) {
                headerButton(systemName: "square.and.arrow.down", tooltip: "Import") {
                    importCredentials()
                }
                headerButton(systemName: "square.and.arrow.up", tooltip: "Export") {
                    exportCredentials()
                }
                .disabled(viewModel.credentials.isEmpty)
            }
            Button(action: { showingAdd = true }) {
                Image(systemName: "plus")
            }
            .buttonStyle(SigilIconButtonStyle(isProminent: true))
            .contentShape(Rectangle())
            .help("Add credential")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private func headerButton(systemName: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(SigilIconButtonStyle())
        .contentShape(Rectangle())
        .help(tooltip)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Search...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var credentialList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(viewModel.filteredCredentials) { credential in
                    CredentialRowView(
                        credential: credential,
                        loadSecret: { viewModel.secret(for: credential) },
                        onDelete: { deleteCredential(credential) },
                        onEdit: { editingCredential = credential }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            SigilMark(size: 44)
                .opacity(0.55)
            VStack(spacing: 4) {
                Text("No credentials yet")
                    .font(.system(size: 13, weight: .medium))
                Text("Seal your first secret")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Button("Add Credential") { showingAdd = true }
                .buttonStyle(SigilCommandButtonStyle(variant: .primary))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No matches")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 4) {
                if !viewModel.credentials.isEmpty {
                    Text("\(viewModel.credentials.count)")
                        .foregroundStyle(.secondary)
                    Text("item\(viewModel.credentials.count == 1 ? "" : "s") · Keychain sealed")
                } else {
                    Circle()
                        .fill(.green.opacity(0.7))
                        .frame(width: 5, height: 5)
                    Text("Sealed by macOS Keychain")
                }
            }
            Spacer()
            Button {
                if let url = URL(string: "https://github.com/abderrahimghazali/sigil") {
                    AppDelegate.shared.closePopover()
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image("GitHubMark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("View on GitHub")
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func deleteCredential(_ credential: Credential) {
        do {
            try viewModel.deleteCredential(credential)
        } catch {
            viewModel.error = error.localizedDescription
        }
    }

    private func exportCredentials() {
        do {
            let data = try viewModel.exportData()
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.nameFieldStringValue = exportFilename()
            panel.message = "Exports include plaintext secrets. Store the file somewhere safe."

            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            viewModel.error = "Exported \(viewModel.credentials.count) item\(viewModel.credentials.count == 1 ? "" : "s")."
        } catch {
            viewModel.error = error.localizedDescription
        }
    }

    private func importCredentials() {
        do {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.json]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.message = "Choose a Sigil JSON export to import."

            guard panel.runModal() == .OK, let url = panel.url else { return }
            let data = try Data(contentsOf: url)
            let summary = try viewModel.importCredentials(from: data)
            viewModel.error = "Imported \(summary.total) item\(summary.total == 1 ? "" : "s") (\(summary.added) new, \(summary.updated) updated)."
        } catch {
            viewModel.error = error.localizedDescription
        }
    }

    private func exportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "Sigil-Export-\(formatter.string(from: Date())).json"
    }
}
