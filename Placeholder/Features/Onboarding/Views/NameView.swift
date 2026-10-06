import SwiftUI

struct NameView: View {
    @StateObject private var onboarding = OnboardingViewModel()
    @State private var showNextView = false

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
                                text: $onboarding.firstName
                            )

                            NameInputField(
                                title: "Last Name",
                                text: $onboarding.surname
                            )
                        }

                        if let errorMessage = onboarding.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                    Spacer()
                    
                    NextButton(
                        onboarding: onboarding,
                        showNextView: $showNextView
                    )
                    .disabled(
                        !onboarding.canContinueFromNameScreen ||
                        onboarding.isSaving
                    )
                    .opacity(
                        onboarding.canContinueFromNameScreen &&
                        !onboarding.isSaving
                            ? 1
                            : 0.4
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(isPresented: $showNextView) {
                LocationView()
            }
        }
    }
}
