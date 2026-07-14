import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    enum State {
        case restoring
        case signedOut
        case signedIn
    }

    private(set) var state: State = .restoring
    private(set) var profile: Profile?
    var errorMessage: String?
    private(set) var isSubmitting = false

    /// Called at launch: a token in the Keychain is only good if the server still
    /// honours it, so prove it with a real request rather than assuming.
    func restore() async {
        guard let token = KeychainStore.token else {
            state = .signedOut
            return
        }

        await APIClient.shared.setToken(token)
        do {
            profile = try await APIClient.shared.profile()
            state = .signedIn
        } catch {
            await discardCredentials()
        }
    }

    func signIn(emailAddress: String, password: String) async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let response = try await APIClient.shared.login(
                emailAddress: emailAddress.trimmingCharacters(in: .whitespaces),
                password: password
            )
            KeychainStore.token = response.token
            await APIClient.shared.setToken(response.token)
            profile = response.user
            state = .signedIn
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        // Revoke server-side too, so the token dies with the session rather than
        // lingering until someone deletes the row.
        try? await APIClient.shared.logout()
        await discardCredentials()
    }

    /// Any 401 mid-session means the token is gone (logged out elsewhere, account
    /// disabled). Drop it and return to the login screen.
    func handle(_ error: Error) async {
        if case APIError.unauthorized = error {
            await discardCredentials()
        }
    }

    private func discardCredentials() async {
        KeychainStore.token = nil
        await APIClient.shared.setToken(nil)
        profile = nil
        state = .signedOut
    }
}
