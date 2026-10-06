import SwiftUI
import UIKit

struct LocationView: View {
    @StateObject private var locationPermission =
        LocationPermissionManager()

    @StateObject private var onboarding = OnboardingViewModel()
    @State private var showNextView = false

    var body: some View {
        ZStack {
            Color(hex: "#F5F1EE")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Profile Setup")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.black)

                OnboardingProgressView(
                    progress: 0.4,
                    step: 2
                )
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Allow location sharing")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.black)

                    Text(
                        """
                        In order for the app to work correctly, you will need to share your location with us. It will only be used where mandatory.
                        """
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(.black)

                    permissionStatusContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 48)

                Spacer()

                NextButton(
                    onboarding: onboarding,
                    showNextView: $showNextView
                )
                .disabled(!locationPermission.isAlwaysAuthorized)
                .opacity(
                    locationPermission.isAlwaysAuthorized
                        ? 1
                        : 0.4
                )
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
        .navigationDestination(isPresented: $showNextView) {
            ProfilePictureView()
        }
        .onAppear {
            locationPermission.requestInitialPermission()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            locationPermission.refreshAuthorizationStatus()
        }
    }

    @ViewBuilder
    private var permissionStatusContent: some View {
        switch locationPermission.authorizationStatus {
        case .notDetermined:
            Text("Location permission is required to continue.")
                .font(.footnote)
                .foregroundStyle(.secondary)

        case .authorizedWhenInUse:
            VStack(alignment: .leading, spacing: 10) {
                Text(
                    """
                    Background access is required to record activity
                    """
                )
                .font(.footnote)
                .foregroundStyle(.red)

                Button("Allow background location") {
                    locationPermission.requestAlwaysUpgrade()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.black)

                Button("Open Settings") {
                    openAppSettings()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.black)
            }

        case .authorizedAlways:
            Label(
                "Background location access enabled.",
                systemImage: "checkmark.circle.fill"
            )
            .font(.footnote)
            .foregroundStyle(.green)

        case .denied:
            VStack(alignment: .leading, spacing: 10) {
                Text(
                    """
                    Location access is required to record activity while \
                    the app is in the background.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.red)

                Button("Open Settings") {
                    openAppSettings()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.black)
            }

        case .restricted:
            Text(
                """
                Location access is restricted on this device and cannot \
                be changed by Placeholder.
                """
            )
            .font(.footnote)
            .foregroundStyle(.red)

        @unknown default:
            Text("Unable to determine location permission.")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}
