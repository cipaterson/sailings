import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth

    @State private var profile: Profile?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    Form {
                        Section {
                            LabeledContent("Name", value: profile.fullName)
                            LabeledContent("Email", value: profile.emailAddress)
                            if let membership = profile.membershipType {
                                LabeledContent("Membership", value: membership)
                            }
                            if let joined = profile.dateJoined {
                                LabeledContent("Joined", value: joined.asDay)
                            }
                        }

                        Section("Sailing Record") {
                            LabeledContent("Days sailed", value: "\(profile.sailingRecord.daysSailed)")
                            LabeledContent("Last sailed",
                                           value: profile.sailingRecord.lastSailed?.asDay ?? "—")
                            if let sailingClass = profile.sailingRecord.sailingClass, !sailingClass.isEmpty {
                                LabeledContent("Class", value: sailingClass)
                            }
                        }

                        Section("Qualifications") {
                            ForEach(profile.qualifications) { qualification in
                                QualificationRow(qualification: qualification)
                            }
                        }

                        Section("Training") {
                            ForEach(profile.training) { record in
                                LabeledContent(record.label,
                                               value: record.completedOn?.asDay ?? "—")
                            }
                        }

                        Section {
                            Button("Sign Out", role: .destructive) {
                                Task { await auth.signOut() }
                            }
                        }
                    }
                } else if let errorMessage {
                    MessageView(icon: "exclamationmark.triangle", title: "Couldn't load profile",
                                detail: errorMessage, retry: load)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func load() async {
        do {
            profile = try await APIClient.shared.profile()
            errorMessage = nil
        } catch {
            await auth.handle(error)
            errorMessage = error.localizedDescription
        }
    }
}

private struct QualificationRow: View {
    let qualification: Qualification

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(qualification.label)
                if let value = qualification.value, !value.isEmpty {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let expires = qualification.expiresOn {
                    Text(expires.asDay)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(color)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var color: Color {
        switch qualification.standing() {
        case .expired: .red
        case .expiringSoon: .orange
        case .current: .green
        case .none: .secondary
        }
    }

    private var note: String {
        switch qualification.standing() {
        case .expired: "Expired"
        case .expiringSoon: "Expiring soon"
        case .current: "Current"
        case .none: ""
        }
    }
}
