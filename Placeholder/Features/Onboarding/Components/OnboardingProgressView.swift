import SwiftUI

struct OnboardingProgressView: View {
    let progress: Double
    let step: Int

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)

                        Capsule()
                            .fill(Color.green)
                            .frame(
                                width: geometry.size.width * clampedProgress,
                                height: 5
                            )
                    }
                }
                .frame(height: 5)

                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
            }

            HStack {
                Text("\(step)/5 Complete")
                    .font(.system(size: 12))
                    .foregroundStyle(.black)

                Spacer()
            }
        }
    }
}
