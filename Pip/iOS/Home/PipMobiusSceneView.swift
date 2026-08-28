import SwiftUI

// MARK: - Continuous motion model

/// Every visible value is continuous. V7 deliberately contains no pose-image
/// weights: a single approved body is deformed by the Metal warp.
struct PipMobiusPose: Equatable, Sendable {
    var deformation: Double
    var bend: Double
    var twist: Double
    var pinch: Double

    var scaleX: Double
    var scaleY: Double
    var rotation: Double
    var yaw: Double
    var verticalOffset: Double

    var shadowScaleX: Double
    var shadowScaleY: Double
    var shadowOpacity: Double
    var shadowYOffset: Double

    var blink: Double
    var eyeFocusX: Double
    var eyeFocusY: Double
    var eyeSpread: Double
    var eyeScale: Double
    var faceX: Double
    var faceY: Double
    var faceRotation: Double
    var smile: Double
    var mouthVisibility: Double
    var glow: Double

    var orbX: Double
    var orbY: Double
    var orbScale: Double
    var orbOpacity: Double
    var orbTrailX: Double
    var orbTrailY: Double
    var orbTrailOpacity: Double
    var orbTrailBend: Double

    static let rest = PipMobiusPose(
        deformation: 0,
        bend: 0,
        twist: 0,
        pinch: 0,
        scaleX: 1,
        scaleY: 1,
        rotation: 0,
        yaw: 0,
        verticalOffset: 0,
        shadowScaleX: 1,
        shadowScaleY: 1,
        shadowOpacity: 0.15,
        shadowYOffset: 0,
        blink: 0,
        eyeFocusX: 0,
        eyeFocusY: 0,
        eyeSpread: 1,
        eyeScale: 1,
        faceX: -0.225,
        faceY: 0.050,
        faceRotation: 0,
        smile: 0.58,
        mouthVisibility: 0,
        glow: 0,
        orbX: 0.20,
        orbY: 0.09,
        orbScale: 0.82,
        orbOpacity: 1,
        orbTrailX: 0.20,
        orbTrailY: 0.09,
        orbTrailOpacity: 0,
        orbTrailBend: 0
    )

    func blended(to target: PipMobiusPose, progress: Double) -> PipMobiusPose {
        let x = min(max(progress, 0), 1)
        let eased = x * x * (3 - 2 * x)
        func mix(_ start: Double, _ end: Double) -> Double {
            start + (end - start) * eased
        }

        return PipMobiusPose(
            deformation: mix(deformation, target.deformation),
            bend: mix(bend, target.bend),
            twist: mix(twist, target.twist),
            pinch: mix(pinch, target.pinch),
            scaleX: mix(scaleX, target.scaleX),
            scaleY: mix(scaleY, target.scaleY),
            rotation: mix(rotation, target.rotation),
            yaw: mix(yaw, target.yaw),
            verticalOffset: mix(verticalOffset, target.verticalOffset),
            shadowScaleX: mix(shadowScaleX, target.shadowScaleX),
            shadowScaleY: mix(shadowScaleY, target.shadowScaleY),
            shadowOpacity: mix(shadowOpacity, target.shadowOpacity),
            shadowYOffset: mix(shadowYOffset, target.shadowYOffset),
            blink: mix(blink, target.blink),
            eyeFocusX: mix(eyeFocusX, target.eyeFocusX),
            eyeFocusY: mix(eyeFocusY, target.eyeFocusY),
            eyeSpread: mix(eyeSpread, target.eyeSpread),
            eyeScale: mix(eyeScale, target.eyeScale),
            faceX: mix(faceX, target.faceX),
            faceY: mix(faceY, target.faceY),
            faceRotation: mix(faceRotation, target.faceRotation),
            smile: mix(smile, target.smile),
            mouthVisibility: mix(mouthVisibility, target.mouthVisibility),
            glow: mix(glow, target.glow),
            orbX: mix(orbX, target.orbX),
            orbY: mix(orbY, target.orbY),
            orbScale: mix(orbScale, target.orbScale),
            orbOpacity: mix(orbOpacity, target.orbOpacity),
            orbTrailX: mix(orbTrailX, target.orbTrailX),
            orbTrailY: mix(orbTrailY, target.orbTrailY),
            orbTrailOpacity: mix(orbTrailOpacity, target.orbTrailOpacity),
            orbTrailBend: mix(orbTrailBend, target.orbTrailBend)
        )
    }
}

enum PipMobiusMotion {
    static func pose(
        stage: PipStage,
        homeState: HomeState,
        progress: Double,
        time: TimeInterval,
        reduceMotion: Bool
    ) -> PipMobiusPose {
        let p = clamp(progress)
        _ = homeState

        if reduceMotion {
            return reducedPose(for: stage)
        }

        switch stage {
        case .idle:
            return idlePose(time: time)
        case .lift:
            return liftPose(progress: p)
        case .release:
            return releasePose(progress: p)
        case .done:
            return donePose(time: time)
        }
    }

    private static func reducedPose(for stage: PipStage) -> PipMobiusPose {
        var pose = PipMobiusPose.rest

        switch stage {
        case .idle:
            pose.orbOpacity = 0.62

        case .lift:
            pose.deformation = 0.92
            pose.bend = -0.20
            pose.twist = 0.14
            pose.pinch = 0.14
            pose.scaleX = 0.975
            pose.scaleY = 1.035
            pose.rotation = -5
            pose.yaw = 22
            pose.verticalOffset = -0.075
            pose.shadowScaleX = 0.79
            pose.shadowScaleY = 0.88
            pose.shadowOpacity = 0.105
            pose.shadowYOffset = 0.012
            pose.eyeFocusX = 0.08
            pose.eyeFocusY = -0.26
            pose.eyeSpread = 0.90
            pose.eyeScale = 1.08
            pose.faceX = -0.160
            pose.faceY = 0.102
            pose.faceRotation = -2.6
            pose.glow = 0.22
            pose.orbX = 0.02
            pose.orbY = -0.39
            pose.orbScale = 1
            pose.orbTrailX = 0.02
            pose.orbTrailY = -0.39

        case .release:
            pose.deformation = -0.72
            pose.bend = 0.20
            pose.twist = -0.14
            pose.pinch = -0.10
            pose.scaleX = 1.11
            pose.scaleY = 0.88
            pose.rotation = 3.5
            pose.yaw = -14
            pose.verticalOffset = 0.048
            pose.shadowScaleX = 1.18
            pose.shadowScaleY = 0.91
            pose.shadowOpacity = 0.175
            pose.shadowYOffset = 0.018
            pose.blink = 0.72
            pose.eyeFocusX = 0.22
            pose.eyeFocusY = 0.18
            pose.eyeSpread = 1.05
            pose.eyeScale = 0.96
            pose.faceX = -0.255
            pose.faceY = 0.046
            pose.faceRotation = 1.8

        case .done:
            pose.deformation = 0.10
            pose.bend = 0.10
            pose.twist = -0.08
            pose.scaleX = 1.04
            pose.scaleY = 1.04
            pose.rotation = 4
            pose.yaw = -12
            pose.verticalOffset = -0.025
            pose.smile = 1
            pose.mouthVisibility = 0.78
            pose.glow = 0.48
            pose.orbX = 0.32
            pose.orbY = -0.28
            pose.orbScale = 1.06
        }

        return pose
    }

    private static func idlePose(time: TimeInterval) -> PipMobiusPose {
        var pose = PipMobiusPose.rest
        let breathe = sin(time * 1.25)
        let drift = sin(time * 0.58 + 0.25)
        let cycle = positiveRemainder(time, divisor: 7.2) / 7.2
        let play = smoothWindow(
            cycle,
            riseStart: 0.46,
            riseEnd: 0.60,
            fallStart: 0.82,
            fallEnd: 0.97
        )
        let playPulse = sinePulse(play)

        // A clearly visible, but fully continuous, low/wide playful squash.
        pose.deformation = -0.56 * play + 0.035 * breathe
        pose.bend = 0.24 * playPulse + 0.055 * drift
        pose.twist = -0.15 * play + 0.045 * sin(time * 0.73)
        pose.pinch = -0.09 * play + 0.025 * breathe
        pose.scaleX = 1 + 0.024 * breathe + 0.045 * play
        pose.scaleY = 1 + 0.030 * breathe - 0.035 * play
        pose.rotation = 2.4 * drift + 5.0 * playPulse
        pose.yaw = 7.5 * sin(time * 0.44) - 5.0 * play
        pose.verticalOffset = -0.014 * breathe + 0.035 * play - 0.025 * playPulse
        pose.shadowScaleX = 1 - 0.055 * breathe + 0.16 * play
        pose.shadowScaleY = 1 - 0.09 * play
        pose.shadowOpacity = 0.15 + 0.024 * play + 0.010 * breathe

        let angle = time * 0.92 - 0.25
        let previousAngle = angle - 0.38
        pose.orbX = 0.34 * cos(angle)
        pose.orbY = -0.07 + 0.29 * sin(angle)
        pose.orbTrailX = 0.34 * cos(previousAngle)
        pose.orbTrailY = -0.07 + 0.29 * sin(previousAngle)
        pose.orbScale = 0.82 + 0.18 * ((sin(angle) + 1) * 0.5)
        pose.orbOpacity = 0.78 + 0.20 * ((cos(angle) + 1) * 0.5)
        pose.orbTrailOpacity = 0.40
        pose.orbTrailBend = 0.035

        pose.eyeFocusX = clampSigned(pose.orbX / 0.34) * 0.34
        pose.eyeFocusY = clampSigned(pose.orbY / 0.36) * 0.22
        pose.blink = max(
            idleBlink(at: time),
            gaussian(cycle, center: 0.73, width: 0.040)
        )
        pose.eyeSpread = lerp(1, 1.05, play)
        pose.eyeScale = lerp(1, 0.96, play)
        pose.faceX = lerp(-0.225, -0.255, play)
        pose.faceY = lerp(0.050, 0.044, play)
        pose.faceRotation = 1.8 * playPulse
        pose.glow = 0.10 * play
        return pose
    }

    /// Ends at the exact boundary pose used by releasePose(progress: 0).
    private static func liftPose(progress p: Double) -> PipMobiusPose {
        var pose = PipMobiusPose.rest
        let anticipation = pulse(in: p, start: 0, end: 0.17)
        let shape = smoothstep(0.10, 0.68, p)
        let holdProgress = clamp((p - 0.68) / 0.32)
        let holdWave = settledCycle(holdProgress)

        // The main silhouette change lives in the GPU warp, not an image swap.
        pose.deformation = 0.92 * shape + 0.055 * holdWave
        pose.bend = 0.10 * anticipation - 0.20 * shape + 0.035 * holdWave
        pose.twist = 0.14 * shape + 0.12 * sinePulse(shape) + 0.025 * holdWave
        pose.pinch = 0.14 * shape + 0.040 * holdWave
        pose.scaleX = 1 + 0.025 * anticipation - 0.025 * shape
        pose.scaleY = 1 - 0.030 * anticipation + 0.035 * shape
        pose.rotation = 3.0 * anticipation - 5.0 * shape + 1.0 * holdWave
        pose.yaw = 22 * shape + 2.5 * anticipation
        pose.verticalOffset = 0.016 * anticipation - 0.075 * shape - 0.006 * holdWave
        pose.shadowScaleX = 1 + 0.07 * anticipation - 0.21 * shape
        pose.shadowScaleY = 1 - 0.12 * shape
        pose.shadowOpacity = 0.15 - 0.045 * shape
        pose.shadowYOffset = 0.012 * shape

        pose.faceX = lerp(-0.225, -0.160, shape)
        pose.faceY = lerp(0.050, 0.102, shape)
        pose.faceRotation = -2.6 * shape
        pose.eyeSpread = lerp(1, 0.90, shape)
        pose.eyeScale = lerp(1, 1.08, shape)
        pose.eyeFocusX = 0.08 * shape
        pose.eyeFocusY = -0.26 * shape
        pose.blink = gaussian(p, center: 0.075, width: 0.023)
        pose.glow = 0.22 * shape

        let orbProgress = smoothstep(0.04, 0.70, p)
        let orb = liftOrbPosition(orbProgress)
        let priorProgress = orbProgress <= 0 || orbProgress >= 1
            ? orbProgress
            : clamp(orbProgress - 0.15)
        let priorOrb = liftOrbPosition(priorProgress)
        let landing = gaussian(p, center: 0.72, width: 0.060)
        pose.orbX = orb.x
        pose.orbY = orb.y - 0.025 * landing
        pose.orbTrailX = priorOrb.x
        pose.orbTrailY = priorOrb.y
        pose.orbScale = 0.82 + 0.18 * orbProgress + 0.11 * landing
        pose.orbOpacity = 1
        pose.orbTrailOpacity = 0.52 * sinePulse(orbProgress)
        pose.orbTrailBend = pose.orbTrailOpacity > 0 ? 0.055 : 0
        return pose
    }

    /// Starts exactly where Lift ends, passes through a broad release squash,
    /// and returns exactly to Rest for the next repetition.
    private static func releasePose(progress p: Double) -> PipMobiusPose {
        var pose = PipMobiusPose.rest
        let drop = smoothstep(0, 0.58, p)
        let recover = smoothstep(0.58, 1, p)
        let impact = gaussian(p, center: 0.54, width: 0.082)

        let rawDeformation = lerp(0.92, -0.72, drop)
        let rawBend = lerp(-0.20, 0.20, drop)
        let rawTwist = lerp(0.14, -0.14, drop)
        let rawPinch = lerp(0.14, -0.10, drop) + 0.08 * impact
        pose.deformation = lerp(rawDeformation, 0, recover)
        pose.bend = lerp(rawBend, 0, recover)
        pose.twist = lerp(rawTwist, 0, recover)
        pose.pinch = lerp(rawPinch, 0, recover)

        let rawScaleX = lerp(0.975, 1.11, drop) + 0.070 * impact
        let rawScaleY = lerp(1.035, 0.88, drop) - 0.060 * impact
        pose.scaleX = lerp(rawScaleX, 1, recover)
        pose.scaleY = lerp(rawScaleY, 1, recover)
        pose.rotation = lerp(lerp(-5, 3.5, drop) + 1.5 * impact, 0, recover)
        pose.yaw = lerp(lerp(22, -14, drop), 0, recover)
        pose.verticalOffset = lerp(
            lerp(-0.075, 0.048, drop) + 0.022 * impact,
            0,
            recover
        )

        let rawShadowX = lerp(0.79, 1.18, drop) + 0.09 * impact
        let rawShadowY = lerp(0.88, 0.91, drop)
        let rawShadowOpacity = lerp(0.105, 0.175, drop) + 0.018 * impact
        pose.shadowScaleX = lerp(rawShadowX, 1, recover)
        pose.shadowScaleY = lerp(rawShadowY, 1, recover)
        pose.shadowOpacity = lerp(rawShadowOpacity, 0.15, recover)
        pose.shadowYOffset = lerp(lerp(0.012, 0.018, drop), 0, recover)

        pose.faceX = lerp(lerp(-0.160, -0.255, drop), -0.225, recover)
        pose.faceY = lerp(lerp(0.102, 0.046, drop), 0.050, recover)
        pose.faceRotation = lerp(lerp(-2.6, 1.8, drop), 0, recover)
        pose.eyeSpread = lerp(lerp(0.90, 1.05, drop), 1, recover)
        pose.eyeScale = lerp(lerp(1.08, 0.96, drop), 1, recover)
        pose.eyeFocusX = lerp(lerp(0.08, 0.22, drop), 0, recover)
        pose.eyeFocusY = lerp(lerp(-0.26, 0.18, drop), 0, recover)
        pose.blink = gaussian(p, center: 0.55, width: 0.090)
        pose.glow = lerp(0.22 * (1 - drop), 0, recover)

        let orbProgress = smoothstep(0, 0.90, p)
        let orb = releaseOrbPosition(orbProgress)
        let priorProgress = orbProgress <= 0 || orbProgress >= 1
            ? orbProgress
            : clamp(orbProgress - 0.15)
        let priorOrb = releaseOrbPosition(priorProgress)
        pose.orbX = orb.x
        pose.orbY = orb.y + 0.018 * impact
        pose.orbTrailX = priorOrb.x
        pose.orbTrailY = priorOrb.y
        pose.orbScale = lerp(1, 0.82, orbProgress) + 0.10 * impact
        pose.orbOpacity = 1
        pose.orbTrailOpacity = 0.52 * sinePulse(orbProgress)
        pose.orbTrailBend = pose.orbTrailOpacity > 0 ? -0.045 : 0
        return pose
    }

    /// Time zero is exactly Rest, so Release -> Done has no visual jump.
    private static func donePose(time: TimeInterval) -> PipMobiusPose {
        var pose = PipMobiusPose.rest
        let entrance = smoothstep(0.08, 0.64, time)
        let popProgress = clamp(time / 0.86)
        let pop = softPulse(popProgress)
        let breathe = sin(time * 1.08)

        pose.deformation = 0.18 * pop + 0.07 * breathe * entrance
        pose.bend = 0.20 * sin(time * 0.82) * entrance
        pose.twist = -0.14 * sin(time * 0.61) * entrance
        pose.pinch = 0.08 * pop
        pose.scaleX = 1 + 0.10 * pop + 0.018 * breathe * entrance
        pose.scaleY = 1 + 0.12 * pop + 0.026 * breathe * entrance
        pose.rotation = 8.0 * pop + 3.2 * sin(time * 0.72) * entrance
        pose.yaw = -14 * entrance + 5 * sin(time * 0.54) * entrance
        pose.verticalOffset = -0.10 * pop - 0.014 * breathe * entrance
        pose.shadowScaleX = 1 - 0.18 * pop - 0.04 * entrance
        pose.shadowScaleY = 1 - 0.08 * pop
        pose.shadowOpacity = 0.15 - 0.060 * pop
        pose.faceX = lerp(-0.225, -0.212, entrance)
        pose.faceY = lerp(0.050, 0.052, entrance)
        pose.faceRotation = 2.2 * entrance
        pose.eyeFocusX = 0.25 * sin(time * 0.68) * entrance
        pose.eyeFocusY = -0.12 * entrance
        pose.blink = max(
            idleBlink(at: time),
            gaussian(time, center: 0.48, width: 0.075)
        )
        pose.smile = lerp(0.58, 1, entrance)
        pose.mouthVisibility = smoothstep(0.24, 0.64, time)
        pose.glow = 0.52 * entrance

        let orbit = smoothstep(0.12, 0.72, time)
        let angle = time * 1.28 - 0.35
        let previousAngle = angle - 0.42
        let targetX = 0.37 * cos(angle)
        let targetY = -0.08 + 0.31 * sin(angle)
        let priorX = 0.37 * cos(previousAngle)
        let priorY = -0.08 + 0.31 * sin(previousAngle)
        pose.orbX = lerp(0.20, targetX, orbit)
        pose.orbY = lerp(0.09, targetY, orbit)
        pose.orbTrailX = lerp(0.20, priorX, orbit)
        pose.orbTrailY = lerp(0.09, priorY, orbit)
        pose.orbScale = 0.82 + 0.24 * orbit
        pose.orbOpacity = 1
        pose.orbTrailOpacity = 0.58 * orbit
        pose.orbTrailBend = 0.045 * orbit
        return pose
    }

    private static func liftOrbPosition(_ progress: Double) -> (x: Double, y: Double) {
        let arc = sinePulse(progress)
        return (
            x: lerp(0.20, 0.02, progress) + 0.10 * arc,
            y: lerp(0.09, -0.39, progress) - 0.18 * arc
        )
    }

    private static func releaseOrbPosition(_ progress: Double) -> (x: Double, y: Double) {
        let arc = sinePulse(progress)
        return (
            x: lerp(0.02, 0.20, progress) + 0.18 * arc,
            y: lerp(-0.39, 0.09, progress) - 0.060 * arc
        )
    }

    private static func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let x = clamp((value - edge0) / max(edge1 - edge0, 0.0001))
        return x * x * (3 - 2 * x)
    }

    private static func smoothWindow(
        _ value: Double,
        riseStart: Double,
        riseEnd: Double,
        fallStart: Double,
        fallEnd: Double
    ) -> Double {
        smoothstep(riseStart, riseEnd, value) * (1 - smoothstep(fallStart, fallEnd, value))
    }

    private static func pulse(in value: Double, start: Double, end: Double) -> Double {
        guard value > start, value < end else { return 0 }
        let wave = sin(((value - start) / max(end - start, 0.0001)) * .pi)
        return wave * wave
    }

    private static func gaussian(_ value: Double, center: Double, width: Double) -> Double {
        let normalized = (value - center) / max(width, 0.0001)
        let distance = abs(normalized)
        guard distance < 3 else { return 0 }
        let edgeFade = 1 - smoothstep(2.45, 3, distance)
        return exp(-normalized * normalized) * edgeFade
    }

    private static func sinePulse(_ value: Double) -> Double {
        guard value > 0, value < 1 else { return 0 }
        return sin(value * .pi)
    }

    private static func softPulse(_ value: Double) -> Double {
        guard value > 0, value < 1 else { return 0 }
        let wave = sin(value * .pi)
        return wave * wave
    }

    private static func settledCycle(_ value: Double) -> Double {
        guard value > 0, value < 1 else { return 0 }
        let envelope = sin(value * .pi)
        return sin(value * .pi * 2) * envelope * envelope
    }

    private static func idleBlink(at time: TimeInterval) -> Double {
        let cycle = positiveRemainder(time, divisor: 5.2)
        return max(
            gaussian(cycle, center: 3.84, width: 0.074),
            gaussian(cycle, center: 4.04, width: 0.058) * 0.62
        )
    }

    private static func positiveRemainder(_ value: Double, divisor: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: divisor)
        return result >= 0 ? result : result + divisor
    }

    private static func lerp(_ start: Double, _ end: Double, _ progress: Double) -> Double {
        if progress <= 0 { return start }
        if progress >= 1 { return end }
        return start + (end - start) * progress
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func clampSigned(_ value: Double) -> Double {
        min(max(value, -1), 1)
    }
}

// MARK: - 2.5D character

struct PipMobiusSceneView: View {
    let pose: PipMobiusPose
    let size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let characterSize = size * 0.86
        let verticalOffset = size * CGFloat(pose.verticalOffset)

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            PipTheme.mintGlow.opacity(0.12 + pose.glow * 0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: characterSize * 0.52
                    )
                )
                .frame(width: characterSize, height: characterSize)
                .opacity(0.74 + pose.glow * 0.26)

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
                        endRadius: size * 0.25
                    )
                )
                .frame(width: size * 0.50, height: size * 0.076)
                .scaleEffect(
                    x: CGFloat(pose.shadowScaleX),
                    y: CGFloat(pose.shadowScaleY)
                )
                .blur(radius: size * 0.010)
                .offset(
                    y: size * (0.294 + CGFloat(pose.shadowYOffset))
                        + verticalOffset * 0.18
                )

            PipOrbTrail(pose: pose)
                .frame(width: characterSize, height: characterSize)

            PipContinuouslyDeformingKnot(
                pose: pose,
                characterSize: characterSize
            )
            .scaleEffect(
                x: CGFloat(pose.scaleX),
                y: CGFloat(pose.scaleY),
                anchor: .center
            )
            .rotation3DEffect(
                .degrees(pose.yaw),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: 0.12
            )
            .rotationEffect(.degrees(pose.rotation))
            .offset(y: verticalOffset)
            .shadow(
                color: Color(red: 0.08, green: 0.20, blue: 0.17)
                    .opacity(colorScheme == .dark ? 0.22 : 0.075),
                radius: size * 0.024,
                y: size * 0.018
            )

            PipGuideOrb(scale: pose.orbScale, baseSize: size)
                .opacity(pose.orbOpacity)
                .offset(
                    x: characterSize * CGFloat(pose.orbX),
                    y: characterSize * CGFloat(pose.orbY) + verticalOffset * 0.22
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct PipContinuouslyDeformingKnot: View {
    let pose: PipMobiusPose
    let characterSize: CGFloat

    var body: some View {
        ZStack {
            Image("PipSoftKnotBody")
                .resizable()
                .interpolation(.high)
                .scaledToFit()

            PipSoftKnotFace(pose: pose, characterSize: characterSize)
        }
        .frame(width: characterSize, height: characterSize)
        // Body and face share one sampled layer, so the eyes never slide away
        // from the clay while the silhouette stretches, bends and rebounds.
        .distortionEffect(
            ShaderLibrary.pipKnotWarp(
                .float2(Float(characterSize), Float(characterSize)),
                .float(Float(pose.deformation)),
                .float(Float(pose.bend)),
                .float(Float(pose.twist)),
                .float(Float(pose.pinch))
            ),
            maxSampleOffset: CGSize(
                width: characterSize * 0.28,
                height: characterSize * 0.28
            )
        )
    }
}

private struct PipSoftKnotFace: View {
    let pose: PipMobiusPose
    let characterSize: CGFloat

    var body: some View {
        let eyeSize = max(characterSize * 0.040 * CGFloat(pose.eyeScale), 5.4)
        let eyeSpacing = characterSize * 0.035 * CGFloat(pose.eyeSpread)
        let faceX = characterSize * CGFloat(pose.faceX)
        let eyeY = characterSize * CGFloat(pose.faceY)

        ZStack {
            HStack(spacing: eyeSpacing) {
                PipClayEye(
                    size: eyeSize,
                    blink: pose.blink,
                    focusX: pose.eyeFocusX,
                    focusY: pose.eyeFocusY
                )
                PipClayEye(
                    size: eyeSize,
                    blink: pose.blink,
                    focusX: pose.eyeFocusX,
                    focusY: pose.eyeFocusY
                )
            }
            .rotationEffect(.degrees(pose.faceRotation))
            .offset(x: faceX, y: eyeY)

            PipSmileShape(amount: pose.smile)
                .stroke(
                    Color(red: 0.08, green: 0.11, blue: 0.105)
                        .opacity(pose.mouthVisibility),
                    style: StrokeStyle(
                        lineWidth: max(1.4, characterSize * 0.009),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(
                    width: characterSize * 0.095,
                    height: characterSize * 0.052
                )
                .rotationEffect(.degrees(pose.faceRotation))
                .offset(
                    x: faceX,
                    y: eyeY + characterSize * 0.055
                )
        }
        .frame(width: characterSize, height: characterSize)
    }
}

private struct PipClayEye: View {
    let size: CGFloat
    let blink: Double
    let focusX: Double
    let focusY: Double

    var body: some View {
        let openness = max(0.09, 1 - blink)

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
                    x: -size * 0.19 + size * 0.12 * CGFloat(focusX),
                    y: -size * 0.20 + size * 0.10 * CGFloat(focusY)
                )
                .opacity(openness)
        }
        .frame(width: size, height: size)
        .scaleEffect(x: 1 + CGFloat(blink) * 0.08, y: CGFloat(openness))
        .shadow(color: .black.opacity(0.16), radius: size * 0.10, y: size * 0.07)
    }
}

private struct PipGuideOrb: View {
    let scale: Double
    let baseSize: CGFloat

    var body: some View {
        let diameter = max(8, baseSize * 0.075 * CGFloat(scale))

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
                    .stroke(.white.opacity(0.50), lineWidth: max(0.7, diameter * 0.035))
            }
            .shadow(
                color: PipTheme.warmApricot.opacity(0.48),
                radius: diameter * 0.30,
                y: diameter * 0.10
            )
    }
}

private struct PipOrbTrail: View {
    let pose: PipMobiusPose

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let start = CGPoint(
                x: width * (0.5 + CGFloat(pose.orbTrailX)),
                y: height * (0.5 + CGFloat(pose.orbTrailY))
            )
            let end = CGPoint(
                x: width * (0.5 + CGFloat(pose.orbX)),
                y: height * (0.5 + CGFloat(pose.orbY))
            )
            let dx = end.x - start.x
            let dy = end.y - start.y
            let length = max((dx * dx + dy * dy).squareRoot(), 0.001)
            let bend = min(width, height) * CGFloat(pose.orbTrailBend)
            let control = CGPoint(
                x: (start.x + end.x) * 0.5 - (dy / length) * bend,
                y: (start.y + end.y) * 0.5 + (dx / length) * bend
            )

            Path { path in
                path.move(to: start)
                path.addQuadCurve(to: end, control: control)
            }
            .stroke(
                LinearGradient(
                    colors: [
                        PipTheme.warmApricot.opacity(0),
                        PipTheme.warmApricot.opacity(0.72)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: max(1.4, width * 0.008),
                    lineCap: .round
                )
            )
        }
        .opacity(pose.orbTrailOpacity)
    }
}

private struct PipSmileShape: Shape {
    var amount: Double

    var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

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
