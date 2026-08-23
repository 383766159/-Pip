import SwiftUI

struct PipBackdrop: View {
    let colorScheme: ColorScheme

    var body: some View {
        ZStack {
            PipTheme.background(for: colorScheme)

            Circle()
                .fill(PipTheme.mintGlow.opacity(colorScheme == .dark ? 0.18 : 0.42))
                .frame(width: 340, height: 340)
                .blur(radius: 48)
                .offset(x: -90, y: -220)

            Circle()
                .fill(PipTheme.apricotSoft.opacity(colorScheme == .dark ? 0.12 : 0.34))
                .frame(width: 280, height: 280)
                .blur(radius: 54)
                .offset(x: 130, y: 180)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct PipHeaderButton: View {
    let systemName: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(PipTheme.ink(for: colorScheme))
                .frame(width: 40, height: 40)
                .background(PipTheme.surface(for: colorScheme), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct PipPrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.white)
        .background(PipTheme.mintDeep, in: Capsule())
        .shadow(color: PipTheme.mintDeep.opacity(0.28), radius: 12, y: 6)
    }
}

struct PipSecondaryButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole? = nil
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? Color.red : PipTheme.ink(for: colorScheme))
        .background(PipTheme.surface(for: colorScheme), in: Capsule())
        .overlay(
            Capsule()
                .stroke(role == .destructive ? Color.red.opacity(0.25) : PipTheme.mint.opacity(0.28), lineWidth: 1)
        )
    }
}

struct PipChip: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(PipTheme.mutedInk(for: colorScheme))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PipTheme.ink(for: colorScheme))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(PipTheme.surface(for: colorScheme), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }
}

struct PipSessionRing: View {
    let progress: Double
    let isLift: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(PipTheme.ringTrack(for: colorScheme), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    isLift ? PipTheme.mintDeep : PipTheme.warmApricot,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}

struct PipEffortBubble: View {
    let title: String
    let subtitle: String
    let isLift: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.headline.weight(.bold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(PipTheme.mutedInk(for: colorScheme))
        }
        .foregroundStyle(PipTheme.ink(for: colorScheme))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(PipTheme.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottom) {
            BubbleTail()
                .fill(PipTheme.surface(for: colorScheme))
                .frame(width: 16, height: 10)
                .offset(y: 8)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 10, y: 4)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(isLift ? PipTheme.mintDeep : PipTheme.warmApricot)
                .frame(width: 4)
                .padding(.vertical, 10)
                .padding(.leading, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct PipSweatDrops: View {
    let pulse: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Capsule()
                .fill(PipTheme.mintDeep.opacity(0.55))
                .frame(width: 8, height: 14)
                .scaleEffect(0.9 + 0.08 * pulse)
                .position(x: size.width * 0.78, y: size.height * 0.18)
            Capsule()
                .fill(PipTheme.mintDeep.opacity(0.4))
                .frame(width: 6, height: 11)
                .scaleEffect(0.7 + 0.12 * (1 - pulse))
                .position(x: size.width * 0.86, y: size.height * 0.34)
        }
        .accessibilityHidden(true)
    }
}

struct PipSparkles: View {
    let pulse: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            sparkle(size: 12)
                .position(x: size.width * 0.16, y: size.height * 0.22)
            sparkle(size: 9)
                .position(x: size.width * 0.84, y: size.height * 0.18)
            sparkle(size: 8)
                .position(x: size.width * 0.88, y: size.height * 0.62)
        }
        .scaleEffect(0.92 + 0.08 * pulse)
        .opacity(0.75 + 0.25 * pulse)
        .accessibilityHidden(true)
    }

    private func sparkle(size: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(PipTheme.warmApricot)
    }
}
