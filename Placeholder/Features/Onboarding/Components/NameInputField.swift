import SwiftUI

struct NameInputField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.black)

            TextField("", text: $text)
                .font(.system(size: 20))
                .foregroundStyle(.black)
                .tint(.black)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: 70, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
