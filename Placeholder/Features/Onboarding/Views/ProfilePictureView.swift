import PhotosUI
import SwiftUI
import UIKit

struct ProfilePictureView: View {
    @StateObject private var onboarding =
        OnboardingViewModel()

    @State private var showNextView = false
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?

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
                        progress: 0.6,
                        step: 3
                    )
                    .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add a profile picture")
                            .font(
                                .system(
                                    size: 30,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.black)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.top, 48)

                    PhotosPicker(
                        selection: $imageSelection,
                        matching: .images
                    ) {
                        imagePreview
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)

                    if let errorMessage = onboarding.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 10)
                    }

                    Button {
                        showNextView = true
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .opacity(0.7)
                    }
                    .padding(.top, 10)

                    Spacer()

                    Button {
                        uploadAndContinue()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.black)
                                .frame(width: 54, height: 54)

                            if onboarding.isUploadingImage {
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
                        selectedImage == nil ||
                        onboarding.isUploadingImage
                    )
                    .opacity(
                        selectedImage != nil &&
                        !onboarding.isUploadingImage
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
            .navigationDestination(
                isPresented: $showNextView
            ) {
                NotificationView()
            }
            .onChange(of: imageSelection) {
                Task {
                    await loadImage()
                }
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: .infinity,
                    minHeight: 375,
                    maxHeight: 375
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
        } else {
            Image(systemName: "photo.fill")
                .font(.system(size: 50))
                .foregroundStyle(.black)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 375,
                    maxHeight: 375
                )
                .background(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
        }
    }

    private func loadImage() async {
        guard let imageSelection else {
            return
        }

        do {
            guard let data = try await imageSelection
                .loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                return
            }

            await MainActor.run {
                selectedImage = image
                onboarding.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                onboarding.errorMessage =
                    "The selected image could not be loaded."
            }
        }
    }

    private func uploadAndContinue() {
        guard selectedImage != nil else {
            return
        }

        Task {
            let didUpload = await onboarding
                .uploadProfilePicture(
                    image: selectedImage
                )

            if didUpload {
                showNextView = true
            }
        }
    }
}
