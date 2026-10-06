import SwiftUI

struct NotificationView: View {
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
                        progress: 0.8,
                        step: 4
                    )
                    .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Allow notifications")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.black)

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

    private func saveAndContinue() {
        Task {
            let wasSaved = await onboarding.saveName()

            if wasSaved {
                showNextView = true
            }
        }
    }
}
