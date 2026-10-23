import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(UserProfileStore.self) private var userProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var surname = ""
    @State private var username = ""

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var newProfileImage: UIImage?

    @State private var isSaving = false
    @State private var isSavingUsername = false
    @State private var showSavedConfirmation = false

    var body: some View {
        @Bindable var store = userProfileStore

        NavigationStack {
            Form {
                profilePictureSection

                nameSection

                usernameSection
                
                NavigationLink {
                    AutomaticActivitySettingsView()
                } label: {
                    Label(
                        "Automatic Activity",
                        systemImage: "figure.walk"
                    )
                }
                
                #if DEBUG
                Section("Developer Tools") {
                    Button {
                        Task { @MainActor in
                            await AutomaticActivityCoordinator.shared.synchronize()
                        }
                    } label: {
                        Label(
                            "Sync Health Activity Now",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                }
                #endif

                if let errorMessage = store.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#2B2B2B"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#F5E4D0"))
                }
            }
            .task {
                await userProfileStore.loadProfileIfNeeded()
                populateDrafts()
            }
            .onChange(of: userProfileStore.profile) {
                populateDrafts()
            }
            .onChange(of: selectedPhoto) {
                loadSelectedPhoto()
            }
            .alert("Profile updated", isPresented: $showSavedConfirmation) {
                Button("OK", role: .cancel) { }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var profilePictureSection: some View {
        Section("Profile Picture") {
            HStack {
                ProfilePicturePreview(
                    currentImage: userProfileStore.profileImage,
                    newImage: newProfileImage
                )

                Spacer()

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Text("Choose Photo")
                }

                if newProfileImage != nil {
                    Button("Save") {
                        Task {
                            await saveProfilePicture()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("First name", text: $firstName)
                .textContentType(.givenName)

            TextField("Surname", text: $surname)
                .textContentType(.familyName)

            if hasNameChanged {
                Button {
                    Task {
                        await saveName()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Name")
                    }
                }
            }
        }
    }

    private var usernameSection: some View {
        Section("Username") {
            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)

            if hasUsernameChanged {
                Button {
                    Task {
                        await saveUsername()
                    }
                } label: {
                    if isSavingUsername {
                        ProgressView()
                    } else {
                        Text("Save Username")
                    }
                }
            }
        }
    }

    private var hasNameChanged: Bool {
        firstName != (userProfileStore.firstName ?? "") ||
        surname != (userProfileStore.surname ?? "")
    }

    private var hasUsernameChanged: Bool {
        username != (userProfileStore.username ?? "")
    }

    private func populateDrafts() {
        if firstName.isEmpty {
            firstName = userProfileStore.firstName ?? ""
        }

        if surname.isEmpty {
            surname = userProfileStore.surname ?? ""
        }

        if username.isEmpty {
            username = userProfileStore.username ?? ""
        }
    }

    private func loadSelectedPhoto() {
        guard let selectedPhoto else {
            newProfileImage = nil
            return
        }

        Task {
            do {
                let data = try await selectedPhoto.loadTransferable(type: Data.self)

                guard let data,
                      let image = UIImage(data: data)
                else {
                    userProfileStore.errorMessage = "Could not load the selected image."
                    return
                }

                newProfileImage = image
            } catch {
                userProfileStore.errorMessage = error.localizedDescription
            }
        }
    }

    private func saveName() async {
        isSaving = true
        defer { isSaving = false }

        let saved = await userProfileStore.saveName(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            surname: surname.trimmingCharacters(in: .whitespaces)
        )

        if saved {
            showSavedConfirmation = true
        }
    }

    private func saveUsername() async {
        isSavingUsername = true
        defer { isSavingUsername = false }

        let saved = await userProfileStore.saveUsername(
            username.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if saved {
            // Eventually show an aleart or haptic feedback
        }
    }

    private func saveProfilePicture() async {
        guard let imageToSave = newProfileImage else {
            return
        }

        guard !isSaving else {
            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        let saved = await userProfileStore.saveProfilePicture(imageToSave)

        if saved {
            newProfileImage = nil
            selectedPhoto = nil
            showSavedConfirmation = true
        }
    }
}
