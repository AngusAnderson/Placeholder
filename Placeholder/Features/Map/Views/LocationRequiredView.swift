import SwiftUI
import UIKit

struct LocationRequiredView: View {
    @ObservedObject var locationPermission:
        LocationPermissionManager

    var body: some View {
        ZStack {
            Color(hex: "#F5F1EE")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "location.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.black)

                Text("Location access required")
                    .font(
                        .system(
                            size: 28,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text(
                    """
                    Placeholder needs Always location access for the app \
                    to function correctly. Please enable it in Settings \
                    to continue.
                    """
                )
                .font(.system(size: 16))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

                permissionStatusText

                Button("Open Settings") {
                    openSettings()
                }
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.black)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )

                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }

    @ViewBuilder
    private var permissionStatusText: some View {
        switch locationPermission.authorizationStatus {
        case .authorizedWhenInUse:
            Text(
                """
                Location is currently set to While Using the App. Change \
                it to Always in Settings.
                """
            )
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)

        case .denied:
            Text(
                "Location access has been disabled for Placeholder."
            )
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)

        case .restricted:
            Text(
                "Location access is restricted on this device."
            )
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)

        case .notDetermined:
            Text(
                "Location permission has not been decided yet."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        case .authorizedAlways:
            Text(
                "Always location access is enabled."
            )
            .font(.footnote)
            .foregroundStyle(.green)
            .multilineTextAlignment(.center)

        @unknown default:
            Text(
                "The location permission status is unknown."
            )
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}
