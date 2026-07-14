import SwiftUI

struct MyRegistrationsView: View {
    @Environment(AuthStore.self) private var auth
    @Binding var registrationsChanged: Int

    @State private var registrations: [Registration] = []
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && registrations.isEmpty {
                    ProgressView()
                } else if let errorMessage {
                    MessageView(icon: "exclamationmark.triangle", title: "Couldn't load registrations",
                                detail: errorMessage, retry: load)
                } else if registrations.isEmpty {
                    MessageView(icon: "checklist", title: "No registrations yet",
                                detail: "Register for a voyage and it will show up here.")
                } else {
                    List {
                        ForEach(registrations) { registration in
                            RegistrationRow(registration: registration)
                        }
                        .onDelete(perform: cancel)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Registrations")
            .refreshable { await load() }
            .task(id: registrationsChanged) { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            registrations = try await APIClient.shared.registrations()
            errorMessage = nil
        } catch {
            await auth.handle(error)
            errorMessage = error.localizedDescription
        }
    }

    private func cancel(at offsets: IndexSet) {
        let targets = offsets.map { registrations[$0] }
        Task {
            for registration in targets {
                do {
                    try await APIClient.shared.cancel(registrationID: registration.id)
                } catch {
                    await auth.handle(error)
                    errorMessage = error.localizedDescription
                }
            }
            registrationsChanged += 1
            await load()
        }
    }
}

private struct RegistrationRow: View {
    let registration: Registration

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(registration.sailing.purpose)
                    .font(.headline)
                Spacer()
                StatusBadge(status: registration.status)
            }

            Text(registration.sailing.voyageDates)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let comment = registration.comment, !comment.isEmpty {
                Text(comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let climbing = registration.climbing {
                Text("Climbing: \(climbing)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
