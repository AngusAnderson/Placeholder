import SwiftUI

struct NameView: View {
    @State private var firstName = ""
    @State private var surname = ""
    @State private var username = ""

    @State private var showNextView = false

    @FocusState private var isUsernameFocused: Bool

    @Environment(UserProfileStore.self) private var userProfileStore

    @ObservedObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F5F1EE")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Text("Profile Setup")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.black)

                        OnboardingProgressView(
                            progress: 0.2,
                            step: 1
                        )
                        .padding(.top, 18)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("What’s your name?")
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(.black)

                            VStack(spacing: 20) {
                                NameInputField(
                                    title: "First Name",
                                    text: $firstName
                                )

                                NameInputField(
                                    title: "Last Name",
                                    text: $surname
                                )

                                usernameField
                            }
                            .disabled(
                                userProfileStore.isSavingProfileDetails
                            )

                            Text(
                                "Your display name uses your first and "
                                + "last name. Your username is your unique "
                                + "@handle."
                            )
                            .font(.footnote)
                            .foregroundStyle(.black.opacity(0.6))

                            if let errorMessage =
                                userProfileStore.errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(.top, 48)

                        nextButton
                            .padding(.top, 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(
                isPresented: $showNextView
            ) {
                LocationView(auth: auth)
            }
        }
    }

    // MARK: - Username field

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)

            HStack(spacing: 6) {
                Text("@")
                    .foregroundStyle(.black.opacity(0.5))

                TextField(
                    "",
                    text: $username,
                    prompt: Text("Choose a username")
                        .foregroundStyle(.black.opacity(0.4))
                )
                .foregroundStyle(.black)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .focused($isUsernameFocused)
                .onSubmit {
                    isUsernameFocused = false
                }
            }
            .font(.system(size: 17))
            .padding(16)
            .background(
                Color.white,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        Color.black.opacity(0.12),
                        lineWidth: 1
                    )
            }

            Text(
                "3–20 characters. Letters, numbers, "
                + "and underscores only. Saved in lowercase."
            )
            .font(.caption)
            .foregroundStyle(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Validation

    private var cleanedUsername: String {
        username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var isUsernameValid: Bool {
        let allowedCharacters = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyz0123456789_"
        )

        return cleanedUsername.count >= 3
            && cleanedUsername.count <= 20
            && cleanedUsername.unicodeScalars.allSatisfy {
                allowedCharacters.contains($0)
            }
    }

    private var canContinue: Bool {
        !firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && !surname.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && isUsernameValid
    }

    // MARK: - Continue

    private var nextButton: some View {
        Button {
            isUsernameFocused = false

            Task {
                let saved = await userProfileStore.saveProfileDetails(
                    firstName: firstName,
                    surname: surname,
                    username: username
                )

                if saved {
                    showNextView = true
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.black)
                    .frame(width: 54, height: 54)

                if userProfileStore.isSavingProfileDetails {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right")
                        .font(
                            .system(
                                size: 22,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(
            !canContinue
            || userProfileStore.isSavingProfileDetails
        )
        .opacity(
            canContinue
                && !userProfileStore.isSavingProfileDetails
                ? 1
                : 0.4
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
