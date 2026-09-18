import Foundation
import Combine

final class AccountsManager: ObservableObject {
    static let shared = AccountsManager()
    @Published private(set) var accounts: [Account] = []
    private let keychain = KeychainManager.shared

    private init() { loadAccounts() }

    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
    }

    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }

    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }

    func deleteAccount(at offsets: IndexSet) {
        accounts.remove(atOffsets: offsets)
        saveAccounts()
    }

    private func loadAccounts() { accounts = keychain.loadAccounts() }
    private func saveAccounts() { keychain.saveAccounts(accounts) }
}