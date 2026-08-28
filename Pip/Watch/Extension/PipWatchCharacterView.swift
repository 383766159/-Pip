import SwiftUI

/// Lightweight Watch rendering of Pip's approved 2.5D knot.
/// The body keeps its baked lighting while the face, shadow, and guide orb
/// remain separate animated layers for smooth watchOS performance.
struct PipWatchCharacterView: View {
    let status: WatchSessionStatus
    let phase: SessionPhase
    let phaseStartedAt: Date
    let elapsedSecondsInPhase: Int
    let phaseDuration: Int
    let size: CGFloat

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: status == .paused || status == .running && phase == .paused
            )
        ) { context in
            characterContent(at: context.date)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func characterContent(at date: Date) -> some View {
        let time = date.timeIntervalSinceReferenceDate
        let pose = pose(at: time, progress: visualProgress(at: date))
        let characterSize = size * 0.86

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            PipTheme.mintGlow.opacity(0.18 + pose.glow * 0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: characterSize * 0.54
                    )
                )
                .frame(width: characterSize, height: characterSize)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.08, green: 0.19, blue: 0.16)
                                .opacity(pose.shadowOpacity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.24
                    )
                )
                .frame(width: size * 0.48, height: size * 0.070)
                .scaleEffect(x: pose.shadowScaleX, y: pose.shadowScaleY)
                .blur(radius: size * 0.010)
                .offset(y: size * 0.30 + size * pose.shadowYOffset)

            PipWatchOrbTrail(
                start: pose.orbTrail,
                end: pose.orb,
                opacity: pose.orbTrailOpacity,
                bend: pose.orbTrailBend,
                size: characterSize
            )

            ZStack {
                Image("PipWatchKnotBody")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()

                PipWatchFace(
                    blink: pose.blink,
                    focusX: pose.eyeFocusX,
                    focusY: pose.eyeFocusY,
                    smile: pose.smile,
                    visible: pose.faceVisibility,
                    size: characterSize
                )
            }
            .frame(width: characterSize, height: characterSize)
            .scaleEffect(x: pose.scaleX, y: pose.scaleY)
            .rotation3DEffect(
                .degrees(pose.yaw),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.12
            )
            .rotationEffect(.degrees(pose.rotation))
            .offset(y: size * pose.verticalOffset)
            .shadow(
                color: Color(red: 0.08, green: 0.20, blue: 0.17).opacity(0.13),
                radius: size * 0.022,
                y: size * 0.018
            )

            PipWatchGuideOrb(scale: pose.orbScale, baseSize: size)
                .opacity(pose.orbOpacity)
                .offset(
                    x: characterSize * pose.orb.x,
                    y: characterSize * pose.orb.y + size * pose.verticalOffset * 0.22
                )
        }
        .frame(width: size, height: size)
    }

    private func visualProgress(at date: Date) -> Double {
        let duration = Double(max(phaseDuration, 1))
        guard status == .running, phase.isActive else {
            return min(1, max(0, Double(elapsedSecondsInPhase) / duration))
        }
        let elapsed = Double(elapsedSecondsInPhase) + max(0, date.timeIntervalSince(phaseStartedAt))
        return min(1, max(0, elapsed / duration))
    }

    private func pose(at time: TimeInterval, progress: Double) -> WatchCharacterPose {
        let idleBreath = sin(time * 1.18)
        let idleDrift = sin(time * 0.58 + 0.4)
        var pose = WatchCharacterPose.rest
        pose.faceVisibility = 1
        pose.orb = (0.20, 0.09)
        pose.orbTrail = pose.orb

        switch phase {
        case .lift:
            let progress = smoothstep(0, 1, progress)
            let arc = sin(progress * .pi)
            pose.deformation = progress
            pose.scaleX = 1 - 0.024 * progress
            pose.scaleY = 1 + 0.034 * progress
            pose.rotation = -5 * progress
            pose.yaw = 21 * progress
            pose.verticalOffset = -0.070 * progress
            pose.shadowScaleX = 1 - 0.20 * progress
            pose.shadowScaleY = 1 - 0.10 * progress
            pose.shadowOpacity = 0.14 - 0.035 * progress
            pose.faceX = -0.160
            pose.faceY = 0.102
            pose.eyeSpread = 0.91
            pose.eyeScale = 1.07
            pose.eyeFocusX = 0.08 * progress
            pose.eyeFocusY = -0.24 * progress
            pose.orb = (
                lerp(0.20, 0.02, progress) + 0.10 * arc,
                lerp(0.09, -0.39, progress) - 0.16 * arc
            )
            pose.orbTrail = (
                lerp(0.20, 0.02, max(0, progress - 0.16)),
                lerp(0.09, -0.39, max(0, progress - 0.16))
            )
            pose.orbScale = 0.82 + 0.18 * progress
            pose.orbTrailOpacity = 0.48 * arc
            pose.orbTrailBend = 0.05

        case .release:
            let progress = smoothstep(0, 1, progress)
            let drop = smoothstep(0, 0.58, progress)
            let recover = smoothstep(0.58, 1, progress)
            let impact = gaussian(progress, center: 0.54, width: 0.10)
            let shape = lerp(0.92, -0.72, drop) * (1 - recover)
            pose.deformation = shape
            pose.scaleX = lerp(0.975, 1.11, drop) * lerp(1, 1, recover) + 0.06 * impact
            pose.scaleY = lerp(1.035, 0.88, drop) - 0.05 * impact
            pose.rotation = lerp(-5, 3.5, drop) + 1.2 * impact
            pose.yaw = lerp(21, -14, drop)
            pose.verticalOffset = lerp(-0.070, 0.046, drop) + 0.018 * impact
            pose.shadowScaleX = lerp(0.80, 1.16, drop)
            pose.shadowScaleY = lerp(0.90, 0.92, drop)
            pose.shadowOpacity = lerp(0.105, 0.175, drop)
            pose.faceX = lerp(-0.160, -0.255, drop)
            pose.faceY = lerp(0.102, 0.046, drop)
            pose.eyeSpread = lerp(0.91, 1.05, drop)
            pose.eyeScale = lerp(1.07, 0.96, drop)
            pose.eyeFocusX = lerp(0.08, 0.22, drop)
            pose.eyeFocusY = lerp(-0.24, 0.18, drop)
            pose.orb = (
                lerp(0.02, 0.20, smoothstep(0, 0.90, progress)),
                lerp(-0.39, 0.09, smoothstep(0, 0.90, progress)) - 0.06 * sin(progress * .pi)
            )
            pose.orbTrail = pose.orb
            pose.orbScale = lerp(1, 0.82, progress) + 0.08 * impact
            pose.orbTrailOpacity = 0.48 * sin(progress * .pi)
            pose.orbTrailBend = -0.045

        case .completed:
            let pulse = sin(time * 1.25) * 0.5 + 0.5
            pose.scaleX = 1.03 + 0.04 * pulse
            pose.scaleY = 1.03 + 0.05 * pulse
            pose.rotation = 3.5 * sin(time * 0.72)
            pose.yaw = -10
            pose.verticalOffset = -0.025 * pulse
            pose.shadowScaleX = 0.94
            pose.shadowScaleY = 0.94
            pose.shadowOpacity = 0.11
            pose.smile = 1
            pose.orb = (0.29 + 0.07 * cos(time * 1.2), -0.12 + 0.20 * sin(time * 1.2))
            pose.orbTrail = pose.orb
            pose.orbScale = 0.94 + 0.10 * pulse
            pose.glow = 0.38

        case .paused:
            pose = poseForPausedPhase()

        case .idle, .cancelled:
            let play = 0.5 + 0.5 * sin(time * 0.42)
            pose.scaleX = 1 + 0.018 * idleBreath + 0.018 * play
            pose.scaleY = 1 + 0.023 * idleBreath - 0.012 * play
            pose.rotation = 1.8 * idleDrift
            pose.yaw = 5.5 * sin(time * 0.44)
            pose.verticalOffset = -0.012 * idleBreath
            pose.shadowScaleX = 1 - 0.04 * idleBreath
            pose.shadowScaleY = 1 - 0.03 * play
            pose.shadowOpacity = 0.14 + 0.01 * idleBreath
            pose.orb = (
                0.31 * cos(time * 0.82),
                -0.06 + 0.22 * sin(time * 0.82)
            )
            pose.orbTrail = pose.orb
            pose.orbScale = 0.84 + 0.12 * (0.5 + 0.5 * sin(time * 0.82))
            pose.orbOpacity = 0.82
        }

        pose.faceOffset = (pose.faceX, pose.faceY)
        return pose
    }

    private func poseForPausedPhase() -> WatchCharacterPose {
        var pose = WatchCharacterPose.rest
        if case .paused = phase {
            pose.scaleX = 1
            pose.scaleY = 1
            pose.orb = (0.20, 0.09)
            pose.orbTrail = pose.orb
        }
        pose.faceVisibility = 1
        return pose
    }

    private func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let x = min(max((value - edge0) / max(edge1 - edge0, 0.0001), 0), 1)
        return x * x * (3 - 2 * x)
    }

    private func lerp(_ start: Double, _ end: Double, _ progress: Double) -> Double {
        start + (end - start) * min(max(progress, 0), 1)
    }

    private func gaussian(_ value: Double, center: Double, width: Double) -> Double {
        let normalized = (value - center) / max(width, 0.0001)
        return exp(-normalized * normalized)
    }
}

private struct WatchCharacterPose {
    var deformation = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var rotation = 0.0
    var yaw = 0.0
    var verticalOffset = 0.0
    var shadowScaleX = 1.0
    var shadowScaleY = 1.0
    var shadowOpacity = 0.14
    var shadowYOffset = 0.0
    var glow = 0.0
    var blink = 0.0
    var eyeFocusX = 0.0
    var eyeFocusY = 0.0
    var eyeSpread = 1.0
    var eyeScale = 1.0
    var faceX = -0.225
    var faceY = 0.050
    var faceOffset = (x: -0.225, y: 0.050)
    var faceVisibility = 1.0
    var smile = 0.58
    var orb = (x: 0.20, y: 0.09)
    var orbTrail = (x: 0.20, y: 0.09)
    var orbScale = 0.84
    var orbOpacity = 1.0
    var orbTrailOpacity = 0.0
    var orbTrailBend = 0.0

    static let rest = WatchCharacterPose()
}

private struct PipWatchFace: View {
    let blink: Double
    let focusX: Double
    let focusY: Double
    let smile: Double
    let visible: Double
    let size: CGFloat

    var body: some View {
        let eyeSize = max(5.2, size * 0.040)
        let eyeSpacing = size * 0.035
        let faceX = size * -0.225
        let eyeY = size * 0.050

        ZStack {
            HStack(spacing: eyeSpacing) {
                PipWatchEye(size: eyeSize, blink: blink, focusX: focusX, focusY: focusY)
                PipWatchEye(size: eyeSize, blink: blink, focusX: focusX, focusY: focusY)
            }
            .offset(x: faceX, y: eyeY)

            PipWatchSmile(amount: smile)
                .stroke(
                    Color(red: 0.08, green: 0.11, blue: 0.105).opacity(visible),
                    style: StrokeStyle(
                        lineWidth: max(1.1, size * 0.008),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size * 0.095, height: size * 0.052)
                .offset(x: faceX, y: eyeY + size * 0.055)
        }
        .frame(width: size, height: size)
    }
}

private struct PipWatchEye: View {
    let size: CGFloat
    let blink: Double
    let focusX: Double
    let focusY: Double

    var body: some View {
        let openness = max(0.10, 1 - blink)

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.22, green: 0.25, blue: 0.24),
                            Color(red: 0.035, green: 0.050, blue: 0.047)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.28),
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )

            Circle()
                .fill(.white.opacity(0.94))
                .frame(width: size * 0.25, height: size * 0.25)
                .offset(
                    x: -size * 0.19 + size * 0.12 * focusX,
                    y: -size * 0.20 + size * 0.10 * focusY
                )
                .opacity(openness)
        }
        .frame(width: size, height: size)
        .scaleEffect(x: 1 + blink * 0.08, y: openness)
    }
}

private struct PipWatchSmile: Shape {
    var amount: Double

    func path(in rect: CGRect) -> Path {
        let depth = rect.height * (0.42 + 0.34 * CGFloat(amount))
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.16))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.16),
            control1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + depth),
            control2: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + depth)
        )
        return path
    }
}

private struct PipWatchGuideOrb: View {
    let scale: Double
    let baseSize: CGFloat

    var body: some View {
        let diameter = max(7, baseSize * 0.075 * scale)

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.96),
                        PipTheme.warmApricot.opacity(0.92),
                        Color(red: 1.0, green: 0.55, blue: 0.25)
                    ],
                    center: UnitPoint(x: 0.34, y: 0.28),
                    startRadius: 0,
                    endRadius: diameter * 0.62
                )
            )
            .frame(width: diameter, height: diameter)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.50), lineWidth: max(0.6, diameter * 0.035))
            }
            .shadow(color: PipTheme.warmApricot.opacity(0.44), radius: diameter * 0.28, y: diameter * 0.10)
    }
}

private struct PipWatchOrbTrail: View {
    let start: (x: Double, y: Double)
    let end: (x: Double, y: Double)
    let opacity: Double
    let bend: Double
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let startPoint = CGPoint(
                x: canvasSize.width * (0.5 + start.x),
                y: canvasSize.height * (0.5 + start.y)
            )
            let endPoint = CGPoint(
                x: canvasSize.width * (0.5 + end.x),
                y: canvasSize.height * (0.5 + end.y)
            )
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let length = max((dx * dx + dy * dy).squareRoot(), 0.001)
            let curve = min(canvasSize.width, canvasSize.height) * bend
            let control = CGPoint(
                x: (startPoint.x + endPoint.x) * 0.5 - (dy / length) * curve,
                y: (startPoint.y + endPoint.y) * 0.5 + (dx / length) * curve
            )

            var path = Path()
            path.move(to: startPoint)
            path.addQuadCurve(to: endPoint, control: control)
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [PipTheme.warmApricot.opacity(0), PipTheme.warmApricot.opacity(0.72)]),
                    startPoint: startPoint,
                    endPoint: endPoint
                ),
                style: StrokeStyle(lineWidth: max(1.1, size * 0.008), lineCap: .round)
            )
        }
        .opacity(opacity)
    }
}
