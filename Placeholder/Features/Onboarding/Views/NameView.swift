import SwiftUI

struct NameView: View {
    @State private var firstName = ""
    @State private var surname = ""

    @State private var showNextView = false
    
    private(set) var isSavingName = false

    @Environment(UserProfileStore.self) private var userProfileStore
    
    @ObservedObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F5F1EE")
                    .ignoresSafeArea()

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
                            .font(.system(size: 30, weight: .medium))
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
                        }

                        if let errorMessage = userProfileStore.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                    Spacer()

                    nextButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(isPresented: $showNextView) {
                LocationView(auth: auth)
            }
        }
    }

    private var canContinue: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !surname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var nextButton: some View {
        Button {
            Task {
                let saved = await userProfileStore.saveName(
                    firstName: firstName,
                    surname: surname
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

                if userProfileStore.isSavingName {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(!canContinue || userProfileStore.isSavingName)
        .opacity(canContinue && !userProfileStore.isSavingName ? 1 : 0.4)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
