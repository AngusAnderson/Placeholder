import SwiftUI

struct NextButton: View {
    @ObservedObject var onboarding: OnboardingViewModel
    @Binding var showNextView: Bool
    
    var body: some View {
        Button {
            Task {
                await onboarding.saveAndContinue(showNextView: $showNextView)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.black)
                    .frame(width: 54, height: 54)

                if onboarding.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
