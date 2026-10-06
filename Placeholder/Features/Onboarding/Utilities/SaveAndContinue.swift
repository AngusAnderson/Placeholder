import SwiftUI

extension OnboardingViewModel {
    func saveAndContinue(showNextView: Binding<Bool>) async {
        if await saveName() {
            showNextView.wrappedValue = true
        }
    }
}
