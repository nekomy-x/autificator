import SwiftUI

struct ContentView: View {
    @ObservedObject private var accountsManager = AccountsManager.shared
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var copiedAccountId: UUID?
    @State private var hoveredId: UUID?

    var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return accountsManager.accounts
        }
        return accountsManager.accounts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.issuer.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            if filteredAccounts.isEmpty {
                emptyStateView
            } else {
                accountsList
            }
            Divider()
            footerView
        }
        .frame(width: 360, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            AddAccountSheet()
        }
    }

    private var headerView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Autificator")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search accounts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.callout)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding(16)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text("No accounts yet")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Click + to add your first account")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var accountsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredAccounts) { account in
                    AccountRowView(account: account, copiedAccountId: $copiedAccountId)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(hoveredId == account.id ? Color.blue.opacity(0.05) : Color.clear)
                        )
                        .onHover { hovering in
                            hoveredId = hovering ? account.id : nil
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .padding(8)
        }
    }

    private var footerView: some View {
        HStack {
            Label("\(accountsManager.accounts.count)", systemImage: "person.crop.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if let first = accountsManager.accounts.first,
               let code = TOTPGenerator.generateCode(for: first) {
                Label("Demo: \(code)", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}