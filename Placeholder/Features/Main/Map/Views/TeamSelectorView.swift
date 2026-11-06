import SwiftUI

struct TeamSelectorView: View {
    let teams: [TeamSummary]
    let isLoading: Bool
    let hasLoaded: Bool
    let errorMessage: String?
    @Binding var selection: Int64?
    var hint: String = "Select a team"
    var maxWidth: CGFloat = 200
    var cornerRadius: CGFloat = 20
    var onManageTeams: () -> Void = {}
    var onRetry: () -> Void = {}

    private var selectedTeam: TeamSummary? { teams.first { $0.id == selection } }
    private var title: String {
        if let selectedTeam { return selectedTeam.name }
        if isLoading && !hasLoaded { return "Loading teams…" }
        if errorMessage != nil && teams.isEmpty { return "Teams unavailable" }
        if hasLoaded && teams.isEmpty { return "No teams yet" }
        return hint
    }

    private var isFlexible: Bool { maxWidth == .infinity }

    var body: some View {
        Menu {
            menuContent
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "person.3.fill").foregroundStyle(.cyan)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .animation(nil, value: title)

                Spacer(minLength: 6)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .modifier(SelectorFrameModifier(isFlexible: isFlexible, width: maxWidth))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(SelectorFrameModifier(isFlexible: isFlexible, width: maxWidth))
        .mapControlGlass(cornerRadius: cornerRadius)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityLabel("Select team")
        .accessibilityValue(title)
    }

    @ViewBuilder
    private var menuContent: some View {
        if !teams.isEmpty {
            Section("Your Teams") {
                ForEach(teams) { team in
                    Button { selection = team.id } label: {
                        if selection == team.id { Label(team.name, systemImage: "checkmark") }
                        else { Text(team.name) }
                    }
                }
            }
            if selection != nil { Button("Clear Selection") { selection = nil } }
        } else if isLoading {
            Text("Loading your teams…")
        } else if errorMessage == nil && hasLoaded {
            Text("You haven’t joined any teams yet.")
        }
        if errorMessage != nil {
            Section {
                Text("Couldn’t refresh your teams.")
                Button(action: onRetry) { Label("Try Again", systemImage: "arrow.clockwise") }
                    .disabled(isLoading)
            }
        }
        Divider()
        Button(action: onManageTeams) { Label("Manage Teams", systemImage: "person.3") }
    }
}

private struct SelectorFrameModifier: ViewModifier {
    let isFlexible: Bool
    let width: CGFloat

    func body(content: Content) -> some View {
        if isFlexible {
            content
                .frame(maxWidth: .infinity, minHeight: 50)
        } else {
            content
                .frame(width: width, height: 50)
                .fixedSize(horizontal: true, vertical: true)
        }
    }
}
