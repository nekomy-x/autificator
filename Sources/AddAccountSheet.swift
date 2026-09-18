import SwiftUI

struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var issuer = ""
    @State private var secret = ""
    @State private var algorithm: TOTPAlgorithm = .sha1
    @State private var digits: Int = 6
    @State private var period: Int = 30
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            formView
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
            }
            Divider()
            actionsView
        }
        .frame(width: 360, height: 420)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            Text("Add Account")
                .font(.headline)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account Name *")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Google, GitHub, AWS", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Issuer / Service *")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. mycompany.com", text: $issuer)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Secret Key *")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Paste from clipboard") {
                            if let content = NSPasteboard.general.string(forType: .string) {
                                secret = content.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                    TextField("Base32 secret (e.g. JAGLM27RZ5...)", text: $secret)
                        .textFieldStyle(.roundedBorder)
                        .font(.callout)
                }

                Divider()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Algorithm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $algorithm) {
                            ForEach(TOTPAlgorithm.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Digits")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $digits) {
                            Text("6").tag(6)
                            Text("8").tag(8)
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Period")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $period) {
                            Text("30s").tag(30)
                            Text("60s").tag(60)
                        }
                        .labelsHidden()
                    }
                }

                if !secret.isEmpty {
                    previewSection
                }
            }
            .padding(16)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let previewCode = previewCode {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Valid secret — code:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(previewCode)
                        .font(.system(.headline, design: .monospaced, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Invalid Base32 secret key")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var previewCode: String? {
        let cleaned = secret.uppercased().replacingOccurrences(of: " ", with: "")
        guard let data = TOTPGenerator.base32Decode(cleaned), !data.isEmpty else { return nil }
        return TOTPGenerator.generateCode(secret: data, digits: digits, algorithm: algorithm)
    }

    private var actionsView: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Add Account") { addAccount() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || secret.isEmpty || previewCode == nil)
        }
        .padding(16)
    }

    private func addAccount() {
        guard !name.isEmpty else { errorMessage = "Account name is required"; return }
        guard !secret.isEmpty else { errorMessage = "Secret key is required"; return }

        let cleaned = secret.uppercased().replacingOccurrences(of: " ", with: "")
        guard TOTPGenerator.base32Decode(cleaned) != nil else {
            errorMessage = "Invalid Base32 secret key"
            return
        }

        AccountsManager.shared.addAccount(Account(
            name: name,
            issuer: issuer,
            secret: cleaned,
            algorithm: algorithm,
            digits: digits,
            period: period
        ))
        dismiss()
    }
}