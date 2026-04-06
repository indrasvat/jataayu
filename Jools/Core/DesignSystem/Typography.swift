import SwiftUI

// MARK: - Jools Typography

extension Font {
    // Titles
    static let joolsLargeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let joolsTitle = Font.system(.title, design: .rounded).weight(.semibold)
    static let joolsTitle2 = Font.system(.title2, design: .rounded).weight(.semibold)
    static let joolsTitle3 = Font.system(.title3, design: .rounded).weight(.medium)

    // Body text
    static let joolsHeadline = Font.system(.headline, design: .default)
    static let joolsBody = Font.system(.body, design: .default)
    static let joolsCallout = Font.system(.callout, design: .default)
    static let joolsSubheadline = Font.system(.subheadline, design: .default)
    static let joolsFootnote = Font.system(.footnote, design: .default)
    static let joolsCaption = Font.system(.caption, design: .default)
    static let joolsCaption2 = Font.system(.caption2, design: .default)

    // Code
    static let joolsCode = Font.system(.body, design: .monospaced)
    static let joolsCodeSmall = Font.system(.footnote, design: .monospaced)
}

// MARK: - Text Style Modifiers

extension View {
    func joolsLargeTitle() -> some View {
        self.font(.joolsLargeTitle)
    }

    func joolsTitle() -> some View {
        self.font(.joolsTitle)
    }

    func joolsHeadline() -> some View {
        self.font(.joolsHeadline)
    }

    func joolsBody() -> some View {
        self.font(.joolsBody)
    }

    func joolsCaption() -> some View {
        self.font(.joolsCaption)
            .foregroundStyle(.secondary)
    }

    func joolsCode() -> some View {
        self.font(.joolsCode)
    }
}

struct MadeWithJoolsFooter: View {
    enum Style {
        case scroll
        case list
    }

    var style: Style = .scroll

    var body: some View {
        VStack(spacing: JoolsSpacing.sm) {
            PixelJoolsMark()
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

            HStack(spacing: 6) {
                Text("Made with")
                    .font(.joolsCaption)
                    .foregroundStyle(.secondary)

                Image(systemName: "heart.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.joolsAccent)
                    .accessibilityLabel("love")

                Text("by Jools")
                    .font(.joolsCaption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, style == .scroll ? JoolsSpacing.xl : JoolsSpacing.md)
        .padding(.bottom, style == .scroll ? JoolsSpacing.xxl : JoolsSpacing.lg)
        .accessibilityIdentifier("made-with-jools-footer")
    }
}

struct PixelJoolsWordmark: View {
    var iconSize: CGFloat = 22
    var titleFont: Font = .system(size: 32, weight: .bold, design: .rounded)
    var subtitle: String? = nil
    var titleTracking: CGFloat = -0.8

    var body: some View {
        HStack(spacing: JoolsSpacing.sm) {
            PixelJoolsBadge(cornerRadius: iconSize * 0.34) {
                PixelJoolsMark()
                    .padding(iconSize * 0.22)
            }
            .frame(width: iconSize, height: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text("Jools")
                    .font(titleFont)
                    .tracking(titleTracking)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct PixelJoolsBadge<Content: View>: View {
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.joolsAccentDark,
                            Color.joolsAccent,
                            Color.joolsAccentLight,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)

            content
        }
        .shadow(color: Color.joolsAccent.opacity(0.24), radius: 12, x: 0, y: 6)
    }
}

struct PixelJoolsMark: View {
    private let activeCells: [(x: Int, y: Int)] = [
        (2, 0), (3, 0), (4, 0),
        (1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
        (1, 2), (2, 2), (4, 2), (5, 2),
        (2, 3), (3, 3), (4, 3),
        (1, 4), (2, 4), (4, 4), (5, 4),
        (1, 5), (2, 5), (3, 5), (4, 5), (5, 5),
        (2, 6), (3, 6), (4, 6),
    ]

    var body: some View {
        GeometryReader { geometry in
            let gridSize = 7
            let cellSize = min(geometry.size.width, geometry.size.height) / CGFloat(gridSize)
            let pixelSize = cellSize * 0.88

            ZStack(alignment: .topLeading) {
                ForEach(Array(activeCells.enumerated()), id: \.offset) { _, cell in
                    RoundedRectangle(cornerRadius: cellSize * 0.24, style: .continuous)
                        .fill(pixelGradient(for: cell.y))
                        .frame(width: pixelSize, height: pixelSize)
                        .overlay {
                            RoundedRectangle(cornerRadius: cellSize * 0.24, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: cellSize * 0.06)
                        }
                        .offset(
                            x: CGFloat(cell.x) * cellSize + (cellSize - pixelSize) / 2,
                            y: CGFloat(cell.y) * cellSize + (cellSize - pixelSize) / 2
                        )
                }
            }
            .frame(width: CGFloat(gridSize) * cellSize, height: CGFloat(gridSize) * cellSize)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private func pixelGradient(for rowIndex: Int) -> LinearGradient {
        LinearGradient(
            colors: rowIndex < 3
                ? [Color.joolsAccentLight, Color.joolsAccent]
                : [Color.joolsAccentSecondary, Color.joolsAccentDark],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
