import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth

    @State private var emailAddress = ""
    @State private var password = ""
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool {
        !emailAddress.isEmpty && !password.isEmpty && !auth.isSubmitting
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sailboat.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Sailings")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                TextField("Email address", text: $emailAddress)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .email)
                    .onSubmit { focus = .password }

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .focused($focus, equals: .password)
                    .onSubmit { if canSubmit { submit() } }
            }
            .textFieldStyle(.roundedBorder)

            if let errorMessage = auth.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                if auth.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Sign In").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .submitLabel(.go)
    }

    private func submit() {
        focus = nil
        Task { await auth.signIn(emailAddress: emailAddress, password: password) }
    }
}
