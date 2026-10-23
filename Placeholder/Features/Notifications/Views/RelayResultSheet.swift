import SwiftUI

struct RelayResultSheet: View {
    let notification: RelayEndNotification
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: notification.isCompleted ? "flag.checkered" : "xmark.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(notification.isCompleted ? Color.cyan : Color.secondary)
                    Text(notification.title).font(.largeTitle.bold())
                    Text(notification.message).multilineTextAlignment(.center)
                    if let start = notification.result.startName,
                       let finish = notification.result.finishName {
                        Text("\(start) → \(finish)").foregroundStyle(.secondary)
                    }
                    if let target = notification.result.targetMetres {
                        Text(String(format: "Journey target: %.2f km", target / 1000))
                            .font(.headline)
                    }
                    Text(notification.createdAt, style: .date)
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }.padding(24).frame(maxWidth: .infinity)
            }
            .navigationTitle("Relay Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
    }
}
