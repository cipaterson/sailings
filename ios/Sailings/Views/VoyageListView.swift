import SwiftUI

struct VoyageListView: View {
    @Environment(AuthStore.self) private var auth
    @Binding var registrationsChanged: Int

    @State private var voyages: [Voyage] = []
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && voyages.isEmpty {
                    ProgressView()
                } else if let errorMessage {
                    MessageView(icon: "exclamationmark.triangle", title: "Couldn't load voyages",
                                detail: errorMessage, retry: load)
                } else if voyages.isEmpty {
                    MessageView(icon: "sailboat", title: "No upcoming voyages",
                                detail: "Scheduled voyages will appear here.")
                } else {
                    List(voyages) { voyage in
                        NavigationLink(value: voyage) {
                            VoyageRow(voyage: voyage)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Voyages")
            .navigationDestination(for: Voyage.self) { voyage in
                VoyageDetailView(voyageID: voyage.id, registrationsChanged: $registrationsChanged)
            }
            .refreshable { await load() }
            .task(id: registrationsChanged) { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            voyages = try await APIClient.shared.voyages()
            errorMessage = nil
        } catch {
            await auth.handle(error)
            errorMessage = error.localizedDescription
        }
    }
}

private struct VoyageRow: View {
    let voyage: Voyage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(voyage.purpose)
                    .font(.headline)
                Spacer()
                if let registration = voyage.myRegistration {
                    StatusBadge(status: registration.status)
                }
            }

            Text(voyage.voyageDates)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if let type = voyage.sailingType {
                    Label(type, systemImage: "tag")
                }
                Label("\(voyage.participantsCount)", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
