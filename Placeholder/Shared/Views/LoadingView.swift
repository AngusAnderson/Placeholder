import SwiftUI

struct LoadingView: View {
    
    private let colourMap: [Int: [String]] = [
        1: ["ED2124", "2772BD"],
        2: ["2872bd", "ed2124"],
        3: ["acdfe8", "fa621a"],
        4: ["2227b2", "fa4001"],
        5: ["0a4644", "1e1e1e"]
    ]

    @State private var key: Int = 0
    @State private var colours: [String] = []

    var body: some View {
        ZStack {
            Color(hex: "#" + (colours.first ?? "ED2124"))
                .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(Color(hex: "#" + (colours.dropFirst().first ?? "2772BD")))
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 7)
                    }
                    .frame(width: 200, height: 200)

                Rectangle()
                    .fill(Color(hex: "#FDE8D4"))
                    .overlay {
                        Rectangle()
                            .stroke(.black, lineWidth: 7)
                        
                        Text("Placeholder")
                            .foregroundStyle(Color(hex: "#000000"))
                            .font(.system(size: 36, weight: .black))
                            .italic()
                    }
                    .frame(width: 240, height: 70)
            }
            .offset(y: -80)
        }
        .onAppear {
            key = Int.random(in: 1...5)
            colours = colourMap[key] ?? []
        }
    }
}
