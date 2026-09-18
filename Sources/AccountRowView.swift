import SwiftUI
import AppKit

struct AccountRowView: View {
    let account: Account
    @Binding var copiedAccountId: UUID?

    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedIssuer: String = ""
    @State private var currentCode: String = "------"
    @State private var progress: Double = 1.0
    @State private var remaining: Int = 30
    @State private var timer: Timer?

    private var isCopied: Bool { copiedAccountId == account.id }

    var body: some View {
        HStack(spacing: 12) {
            progressRing
            accountInfo
            Spacer()
            codeButton
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCopied ? Color.green.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCopied ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { copyCode() }
        .contextMenu { contextMenuContent }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var progressColor: Color {
        if remaining <= 5 { return .red }
        else if remaining <= 10 { return .orange }
        return .blue
    }

    @ViewBuilder
    private var accountInfo: some View {
        if isEditing {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption))
                TextField("Issuer", text: $editedIssuer)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption))
                HStack(spacing: 6) {
                    Button("Save") { saveEdit() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Button("Cancel") { isEditing = false }
                        .controlSize(.small)
                }
            }
            .frame(width: 150)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(.body, design: .default, weight: .medium))
                    .lineLimit(1)
                    .help(account.name)
                if !account.issuer.isEmpty {
                    Text(account.issuer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text("\(account.algorithm.rawValue) · \(account.digits)d · \(account.period)s")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            VStack(spacing: 0) {
                Text("\(remaining)")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(progressColor)
            }
        }
        .frame(width: 44, height: 44)
    }

    private var codeButton: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formattedCode)
                .font(.system(.title2, design: .monospaced, weight: .bold))
                .foregroundStyle(isCopied ? .green : .primary)
                .scaleEffect(isCopied ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isCopied)

            Text(isCopied ? "Copied!" : "Tap to copy")
                .font(.caption2)
                .foregroundStyle(isCopied ? .green : .secondary)
                .animation(.easeInOut(duration: 0.2), value: isCopied)
        }
        .contentShape(Rectangle())
        .onTapGesture { copyCode() }
    }

    private var formattedCode: String {
        if currentCode.count == 6 {
            let idx = currentCode.index(currentCode.startIndex, offsetBy: 3)
            return "\(currentCode[..<idx]) \(currentCode[idx...])"
        }
        return currentCode
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Copy Code") { copyCode() }
        Divider()
        Button("Edit Name") {
            editedName = account.name
            editedIssuer = account.issuer
            isEditing = true
        }
        Divider()
        Button("Delete", role: .destructive) {
            AccountsManager.shared.deleteAccount(account)
        }
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentCode, forType: .string)
        copiedAccountId = account.id

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedAccountId == account.id { copiedAccountId = nil }
        }
    }

    private func saveEdit() {
        var updated = account
        updated.name = editedName
        updated.issuer = editedIssuer
        AccountsManager.shared.updateAccount(updated)
        isEditing = false
    }

    private func startTimer() {
        updateCode()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in updateCode() }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func updateCode() {
        remaining = TOTPGenerator.remainingSeconds(period: account.period)
        progress = TOTPGenerator.progress(period: account.period)
        if let code = TOTPGenerator.generateCode(for: account) { currentCode = code }
    }
}