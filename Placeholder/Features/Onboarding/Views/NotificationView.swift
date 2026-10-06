import SwiftUI

struct NotificationView: View {
    @ObservedObject var auth: AuthViewModel

    @StateObject private var notificationPermission =
        NotificationPermissionManager()

    @State private var showHomeView = false

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
                            .font(
                                .system(
                                    size: 30,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.black)

                        Text(
                            """
                            We use notifications to let you know when new \
                            events take place, when someone adds you as a \
                            friend, and the results of an event. This is \
                            completely optional.
                            """
                        )
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.top, 48)

                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 16)
                    }

                    Spacer()

                    Button {
                        completeOnboardingAndContinue()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.black)
                                .frame(width: 54, height: 54)

                            if auth.isLoading {
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
                    .disabled(auth.isLoading)
                    .opacity(auth.isLoading ? 0.4 : 1)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .trailing
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(
                isPresented: $showHomeView
            ) {
                HomeView()
            }
            .task {
                await notificationPermission.requestPermission()
            }
        }
    }

    private func completeOnboardingAndContinue() {
        Task {
            await auth.completeOnboarding()

            if auth.onboardingCompleted == true {
                showHomeView = true
            }
        }
    }
}
