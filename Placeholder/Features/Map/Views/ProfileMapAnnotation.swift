import SwiftUI
import UIKit

struct ProfileMapAnnotation: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(
                    width: 58,
                    height: 58
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: 50,
                        height: 50
                    )
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(
                        width: 50,
                        height: 50
                    )
                    .background(.gray)
                    .clipShape(Circle())
            }
        }
        .overlay {
            Circle()
                .stroke(
                    .black,
                    lineWidth: 2
                )
        }
        .shadow(
            color: .black.opacity(0.25),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}
