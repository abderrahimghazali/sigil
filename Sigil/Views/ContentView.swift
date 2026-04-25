import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = CredentialsViewModel()
    @State private var showingAdd = false
    @State private var editingCredential: Credential?

    var body: some View {
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
        .frame(width: 340, height: 440)
        .sheet(isPresented: $showingAdd) {
            AddCredentialView(viewModel: viewModel, isPresented: $showingAdd)
        }
        .sheet(item: $editingCredential) { credential in
            AddCredentialView(
                viewModel: viewModel,
                isPresented: Binding(
                    get: { editingCredential != nil },
                    set: { if !$0 { editingCredential = nil } }
                ),
                existing: credential
            )
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                    Image(systemName: "seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Sigil")
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer()
            Button(action: { showingAdd = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
                        password: viewModel.password(for: credential),
                        onDelete: { viewModel.deleteCredential(credential) },
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
            Image(systemName: "seal")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary.opacity(0.5))
            VStack(spacing: 4) {
                Text("No credentials yet")
                    .font(.system(size: 13, weight: .medium))
                Text("Seal your first password")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Button("Add Credential") { showingAdd = true }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.indigo)
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
                    Text("credential\(viewModel.credentials.count == 1 ? "" : "s") · Keychain sealed")
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
}
