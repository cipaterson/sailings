import SwiftUI

struct VoyageDetailView: View {
    @Environment(AuthStore.self) private var auth
    let voyageID: Int
    @Binding var registrationsChanged: Int

    @State private var voyage: Voyage?
    @State private var errorMessage: String?
    @State private var actionError: String?
    @State private var isWorking = false
    @State private var showingRegisterSheet = false

    var body: some View {
        Group {
            if let voyage {
                Form {
                    Section {
                        LabeledContent("Voyage", value: voyage.purpose)
                        LabeledContent("Dates", value: voyage.voyageDates)
                        if let type = voyage.sailingType {
                            LabeledContent("Type", value: type)
                        }
                        if let training = voyage.training {
                            LabeledContent("Training", value: training)
                        }
                        LabeledContent("Crew", value: "\(voyage.participantsCount)")
                    }

                    if voyage.master?.isEmpty == false || voyage.engineer?.isEmpty == false
                        || voyage.lnContact?.isEmpty == false {
                        Section("Crew") {
                            if let master = voyage.master, !master.isEmpty {
                                LabeledContent("Master", value: master)
                            }
                            if let engineer = voyage.engineer, !engineer.isEmpty {
                                LabeledContent("Engineer", value: engineer)
                            }
                            if let contact = voyage.lnContact, !contact.isEmpty {
                                LabeledContent("LN Contact", value: contact)
                            }
                        }
                    }

                    if let comments = voyage.comments, !comments.isEmpty {
                        Section("Comments") { Text(comments) }
                    }

                    if let details = voyage.additionalDetails, !details.isEmpty {
                        Section("Additional Details") { Text(details) }
                    }

                    Section {
                        if let registration = voyage.myRegistration {
                            LabeledContent("Your registration") {
                                StatusBadge(status: registration.status)
                            }
                            Button(role: .destructive) {
                                Task { await cancel(registrationID: registration.id) }
                            } label: {
                                cancelLabel
                            }
                            .disabled(isWorking)
                        } else {
                            Button {
                                showingRegisterSheet = true
                            } label: {
                                Label("Register for this Voyage", systemImage: "plus.circle")
                            }
                            .disabled(isWorking)
                        }

                        if let actionError {
                            Text(actionError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else if let errorMessage {
                MessageView(icon: "exclamationmark.triangle", title: "Couldn't load voyage",
                            detail: errorMessage, retry: load)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(voyage?.purpose ?? "Voyage")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showingRegisterSheet) {
            RegisterSheet(voyageID: voyageID) { registration in
                showingRegisterSheet = false
                if registration != nil {
                    registrationsChanged += 1
                    Task { await load() }
                }
            }
        }
    }

    @ViewBuilder
    private var cancelLabel: some View {
        if isWorking {
            ProgressView()
        } else {
            Label("Cancel Registration", systemImage: "xmark.circle")
        }
    }

    private func load() async {
        do {
            voyage = try await APIClient.shared.voyage(id: voyageID)
            errorMessage = nil
        } catch {
            await auth.handle(error)
            errorMessage = error.localizedDescription
        }
    }

    private func cancel(registrationID: Int) async {
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await APIClient.shared.cancel(registrationID: registrationID)
            registrationsChanged += 1
            await load()
        } catch {
            await auth.handle(error)
            actionError = error.localizedDescription
        }
    }
}

/// Registering asks the two questions the web form asks: a comment, and whether
/// the member is willing to climb.
private struct RegisterSheet: View {
    @Environment(AuthStore.self) private var auth
    let voyageID: Int
    let onFinish: (Registration?) -> Void

    @State private var comment = ""
    @State private var climbing: Int?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Climbing") {
                    Picker("Willing to climb", selection: $climbing) {
                        Text("Not specified").tag(Int?.none)
                        Text("Yes").tag(Int?.some(1))
                        Text("No").tag(Int?.some(2))
                    }
                }

                Section("Comment") {
                    TextField("Anything the crewing operator should know", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Text("You'll be registered as an expression of interest. The crewing operator confirms the final crew.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onFinish(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Register") { Task { await submit() } }
                        .disabled(isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let registration = try await APIClient.shared.register(
                voyageID: voyageID, comment: comment, climbing: climbing
            )
            onFinish(registration)
        } catch {
            await auth.handle(error)
            errorMessage = error.localizedDescription
        }
    }
}
