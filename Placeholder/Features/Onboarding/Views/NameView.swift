import SwiftUI

struct NameView: View {
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
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

                    VStack(spacing: 16) {
                        NameInputField(
                            title: "First Name",
                            text: $firstName
                        )

                        NameInputField(
                            title: "Last Name",
                            text: $lastName
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 48)

                Spacer()

                Button {
                    submitName()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(.black)
                        .clipShape(Circle())
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitName() {
        let cleanedFirstName = firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanedLastName = lastName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        print("Name: \(cleanedFirstName) \(cleanedLastName)")
    }
}
