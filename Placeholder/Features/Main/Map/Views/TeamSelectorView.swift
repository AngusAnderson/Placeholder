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

    private var selectedTeam: TeamSummary? {
        teams.first {
            $0.id == selection
        }
    }

    private var title: String {
        if let selectedTeam {
            return selectedTeam.name
        }

        if isLoading && !hasLoaded {
            return "Loading teams…"
        }

        if errorMessage != nil && teams.isEmpty {
            return "Teams unavailable"
        }

        if hasLoaded && teams.isEmpty {
            return "No teams yet"
        }

        return hint
    }

    var body: some View {
        Menu {
            menuContent
        } label: {
            selectorLabel
                .modifier(
                    TeamSelectorGlassModifier(
                        cornerRadius: cornerRadius
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select team")
        .accessibilityValue(title)
    }

    // MARK: - Label

    private var selectorLabel: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.cyan)
            }

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 15)
        .frame(width: maxWidth, height: 50)
        .contentShape(
            RoundedRectangle(cornerRadius: cornerRadius)
        )
    }

    // MARK: - Menu

    @ViewBuilder
    private var menuContent: some View {
        if !teams.isEmpty {
            Section("Your Teams") {
                ForEach(teams) { team in
                    Button {
                        selection = team.id
                    } label: {
                        if selection == team.id {
                            Label(
                                team.name,
                                systemImage: "checkmark"
                            )
                        } else {
                            Text(team.name)
                        }
                    }
                }
            }

            if selection != nil {
                Button("Clear Selection") {
                    selection = nil
                }
            }
        } else if isLoading {
            Text("Loading your teams…")
        } else if errorMessage == nil && hasLoaded {
            Text("You haven’t joined any teams yet.")
        }

        if errorMessage != nil {
            Section {
                Text("Couldn’t refresh your teams.")

                Button {
                    onRetry()
                } label: {
                    Label(
                        "Try Again",
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(isLoading)
            }
        }

        Divider()

        Button {
            onManageTeams()
        } label: {
            Label(
                "Manage Teams",
                systemImage: "person.3"
            )
        }
    }
}

// MARK: - Availability-aware glass styling

private struct TeamSelectorGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(
                        cornerRadius: cornerRadius
                    )
                )
        } else {
            content
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(
                        cornerRadius: cornerRadius
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: cornerRadius
                    )
                    .stroke(
                        Color.primary.opacity(0.12),
                        lineWidth: 1
                    )
                }
        }
    }
}
