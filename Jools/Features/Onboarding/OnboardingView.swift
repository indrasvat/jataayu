import SwiftUI

/// Onboarding view for API key entry
struct OnboardingView: View {
    @EnvironmentObject private var dependencies: AppDependency
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: JoolsSpacing.xl) {
                Spacer()

                // Logo section
                VStack(spacing: JoolsSpacing.md) {
                    AppIconView()

                    Text("Jools")
                        .font(.system(size: 44, weight: .bold))
                        .tracking(-1.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9), Color(hex: "C084FC")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Your Pocket CTO")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))

                    // Feature pills
                    FeaturePillsView()
                        .padding(.top, JoolsSpacing.md)
                }

                Spacer()

                // API Key input section
                VStack(spacing: JoolsSpacing.md) {
                    VStack(alignment: .leading, spacing: JoolsSpacing.xs) {
                        Text("API KEY")
                            .font(.joolsCaption)
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)

                        SecureField("Enter your Jules API key", text: $viewModel.apiKey)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.joolsAccent.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: JoolsRadius.md)
                                    .stroke(Color.joolsAccent.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
                    }

                    Button(action: {
                        Task {
                            await viewModel.connect(using: dependencies)
                        }
                    }) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Connect")
                                    .font(.joolsBody)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.joolsAccentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
                    }
                    .opacity(viewModel.apiKey.isEmpty || viewModel.isLoading ? 0.5 : 1.0)
                    .disabled(viewModel.apiKey.isEmpty || viewModel.isLoading)

                    Link("Get your API key from jules.google.com",
                         destination: URL(string: "https://jules.google.com/settings")!)
                        .font(.joolsCaption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, JoolsSpacing.lg)

                Spacer()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Supporting Views

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F")

            // Animated gradient orbs
            Circle()
                .fill(Color.joolsAccent.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animateGradient ? -50 : 50, y: animateGradient ? -100 : -50)

            Circle()
                .fill(Color.joolsAccentSecondary.opacity(0.25))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: animateGradient ? 80 : -80, y: animateGradient ? 150 : 100)

            Circle()
                .fill(Color.joolsAccentDark.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: animateGradient ? -30 : 30, y: animateGradient ? 50 : -50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

struct AppIconView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient.joolsAccentGradient)
                .frame(width: 100, height: 100)
                .shadow(color: .joolsAccent.opacity(0.5), radius: isPulsing ? 30 : 20)

            LayersIcon()
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 50, height: 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct LayersIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top layer (diamond/rhombus)
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
        path.addLine(to: CGPoint(x: w, y: h * 0.25))
        path.closeSubpath()

        // Middle layer
        path.move(to: CGPoint(x: 0, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.75))
        path.addLine(to: CGPoint(x: w, y: h * 0.5))

        // Bottom layer
        path.move(to: CGPoint(x: 0, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.addLine(to: CGPoint(x: w, y: h * 0.75))

        return path
    }
}

struct FeaturePillsView: View {
    let features = [
        ("checkmark.circle.fill", "Plan Review"),
        ("clock.fill", "Real-time Updates"),
        ("wifi.slash", "Offline Ready"),
    ]

    var body: some View {
        FlowLayout(spacing: JoolsSpacing.xs) {
            ForEach(features, id: \.1) { icon, title in
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.joolsAccent)
                    Text(title)
                }
                .font(.joolsCaption)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.joolsAccent.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.joolsAccent.opacity(0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = arrange(maxWidth: maxWidth, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(maxWidth: bounds.width, subviews: subviews)

        // Center each row
        for (index, position) in result.positions.enumerated() {
            let rowWidth = result.rowWidths[result.rowIndices[index]]
            let xOffset = (bounds.width - rowWidth) / 2
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x + xOffset, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], rowWidths: [CGFloat], rowIndices: [Int]) {
        var positions: [CGPoint] = []
        var rowWidths: [CGFloat] = []
        var rowIndices: [Int] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowIndex = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                rowWidths.append(currentRowWidth - spacing)
                currentRowIndex += 1
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
                currentRowWidth = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowIndices.append(currentRowIndex)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            currentRowWidth = currentX
        }
        rowWidths.append(currentRowWidth - spacing)

        let totalWidth = rowWidths.max() ?? 0
        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions, rowWidths, rowIndices)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppDependency())
}
