import SwiftUI
import PhotosUI

struct ProfilePictureView: View {
    @StateObject private var onboarding = OnboardingViewModel()
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
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.black)

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)
                    
                    ZStack {
                        if let uiImage = selectedImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
//                            Rectangle()
//                                .fill(Color(.white))
//                                .frame(maxWidth: .infinity, maxHeight: 200)
//                                .overlay(
//                                    Text("No image selected")
//                                        .foregroundStyle(Color(hex: "#000"))
//                                )
//                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            ZStack {
                                PhotosPicker(selection: $imageSelection, matching: .images) {
                                    Text(selectedImage == nil ? "Choose Image" : "Change Image")
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                        .padding()
                                        .background(Color(hex: "#fff"))
                                        .foregroundStyle(Color(hex: "#000"))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    
                                }
                                .onChange(of: imageSelection) {
                                    Task {
                                        await loadImage()
                                    }
                                }
                            }
                            
                        }
                    }

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
    
    @MainActor
    private func loadImage() async {
        guard let item = imageSelection else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
                let uiImage =  UIImage(data: data) {
                selectedImage = uiImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}
