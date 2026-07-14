import SwiftUI

/// Colour-codes a registration status the way the crew list reads it.
struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status {
        case RegistrationStatus.accepted: .green
        case RegistrationStatus.eoi: .orange
        case RegistrationStatus.notRequired: .secondary
        default: .secondary
        }
    }

    var body: some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

/// Shown instead of a list when a screen has nothing to show or the request failed.
struct MessageView: View {
    let icon: String
    let title: String
    var detail: String?
    var retry: (() async -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            if let detail { Text(detail) }
        } actions: {
            if let retry {
                Button("Try Again") { Task { await retry() } }
            }
        }
    }
}

extension Date {
    var asDay: String { formatted(.dateTime.day().month(.abbreviated).year()) }
}
