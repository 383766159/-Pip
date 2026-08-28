import Foundation
import SwiftUI

struct PipMascotPose: Equatable, Sendable {
    var stretchY: Double
    var stretchX: Double
    var brow: Double
    var mouth: Double
    var eyeClose: Double
    var blush: Double
    var effort: Double
    var smile: Double
    var bounce: Double
    var shake: Double
    var tilt: Double
    var turn: Double

    static let rest = PipMascotPose(
        stretchY: 1,
        stretchX: 1,
        brow: 0.08,
        mouth: 0,
        eyeClose: 0,
        blush: 0.48,
        effort: 0,
        smile: 1,
        bounce: 0,
        shake: 0,
        tilt: 0,
        turn: 0
    )
}

enum PipMascotMotion {
    static func pose(
        stage: PipStage,
        homeState: HomeState,
        progress: Double,
        time: TimeInterval,
        reduceMotion: Bool
    ) -> PipMascotPose {
        if reduceMotion {
            return staticPose(stage: stage, homeState: homeState)
        }

        switch homeState {
        case .idle:
            return idlePose(at: time)
        case .done:
            return donePose(at: time)
        case .session:
            switch stage {
            case .lift:
                return sampled(knots: liftKnots, progress: progress, time: time)
            case .release:
                return sampled(knots: releaseKnots, progress: progress, time: time)
            case .done:
                return donePose(at: time)
            case .idle:
                return idlePose(at: time)
            }
        }
    }

    static func staticPose(stage: PipStage, homeState: HomeState) -> PipMascotPose {
        switch homeState {
        case .idle:
            return .rest
        case .done:
            var pose = knot(at: 1, in: releaseKnots)
            pose.smile = 1.25
            pose.mouth = 0
            pose.eyeClose = 0
            return pose
        case .session:
            switch stage {
            case .lift:
                return knot(at: 0.62, in: liftKnots)
            case .release:
                return knot(at: 0.42, in: releaseKnots)
            case .done:
                var pose = PipMascotPose.rest
                pose.smile = 1.25
                return pose
            case .idle:
                return .rest
            }
        }
    }

    private static func idlePose(at time: TimeInterval) -> PipMascotPose {
        let breath = sin(time * 1.35)
        var pose = PipMascotPose.rest
        pose.stretchY = 1.0 + 0.018 * breath
        pose.stretchX = 1.0 - 0.012 * breath
        pose.blush = 0.44 + 0.04 * breath
        pose.eyeClose = 0.92 * blink(at: time, every: 4.7)
        pose.tilt = 0.65 * sin(time * 0.58)
        pose.turn = 3.2 * sin(time * 0.72)
        return pose
    }

    private static func donePose(at time: TimeInterval) -> PipMascotPose {
        let cycle = 0.5 - 0.5 * cos(time * 3.8)
        let hop = smoothstep(cycle)
        var pose = PipMascotPose.rest
        pose.smile = 1.35
        pose.stretchY = 1.01 + 0.035 * hop
        pose.stretchX = 0.995 - 0.018 * hop
        pose.bounce = -7 * hop
        pose.blush = 0.7
        pose.eyeClose = max(0.12 * hop, 0.85 * blink(at: time + 0.7, every: 3.9))
        pose.tilt = 1.2 * sin(time * 1.9)
        pose.turn = 4.0 * sin(time * 1.45)
        return pose
    }

    private struct Knot {
        var t: Double
        var pose: PipMascotPose

        init(
            t: Double,
            stretchY: Double,
            stretchX: Double,
            brow: Double,
            mouth: Double,
            eyeClose: Double,
            blush: Double,
            effort: Double,
            smile: Double,
            bounce: Double = 0,
            tilt: Double = 0,
            turn: Double = 0
        ) {
            self.t = t
            self.pose = PipMascotPose(
                stretchY: stretchY,
                stretchX: stretchX,
                brow: brow,
                mouth: mouth,
                eyeClose: eyeClose,
                blush: blush,
                effort: effort,
                smile: smile,
                bounce: bounce,
                shake: 0,
                tilt: tilt,
                turn: turn
            )
        }
    }

    private static let liftKnots: [Knot] = [
        Knot(t: 0.00, stretchY: 1.00, stretchX: 1.00, brow: 0.08, mouth: 0.00, eyeClose: 0.00, blush: 0.48, effort: 0.00, smile: 1.00),
        Knot(t: 0.12, stretchY: 0.96, stretchX: 1.035, brow: 0.18, mouth: 0.18, eyeClose: 0.00, blush: 0.52, effort: 0.08, smile: 0.78, tilt: -0.35, turn: -0.7),
        Knot(t: 0.32, stretchY: 1.03, stretchX: 0.98, brow: 0.38, mouth: 0.50, eyeClose: 0.02, blush: 0.61, effort: 0.30, smile: 0.34, tilt: 0.20, turn: 0.35),
        Knot(t: 0.58, stretchY: 1.13, stretchX: 0.91, brow: 0.60, mouth: 0.75, eyeClose: 0.05, blush: 0.72, effort: 0.58, smile: 0.08, tilt: -0.15, turn: -0.25),
        Knot(t: 0.82, stretchY: 1.20, stretchX: 0.86, brow: 0.76, mouth: 0.95, eyeClose: 0.08, blush: 0.82, effort: 0.82, smile: 0.00, tilt: 0.10, turn: 0.20),
        Knot(t: 1.00, stretchY: 1.23, stretchX: 0.84, brow: 0.84, mouth: 1.05, eyeClose: 0.10, blush: 0.86, effort: 0.90, smile: 0.00)
    ]

    private static let releaseKnots: [Knot] = [
        Knot(t: 0.00, stretchY: 1.23, stretchX: 0.84, brow: 0.84, mouth: 1.05, eyeClose: 0.10, blush: 0.86, effort: 0.90, smile: 0.00),
        Knot(t: 0.18, stretchY: 1.17, stretchX: 0.88, brow: 0.60, mouth: 1.30, eyeClose: 0.18, blush: 0.80, effort: 0.70, smile: 0.05, tilt: 0.35, turn: 0.7),
        Knot(t: 0.42, stretchY: 1.06, stretchX: 0.97, brow: 0.25, mouth: 0.55, eyeClose: 0.45, blush: 0.66, effort: 0.30, smile: 0.65, tilt: -0.20, turn: -0.35),
        Knot(t: 0.65, stretchY: 0.98, stretchX: 1.025, brow: 0.08, mouth: 0.12, eyeClose: 0.60, blush: 0.55, effort: 0.08, smile: 1.08, tilt: 0.10, turn: 0.20),
        Knot(t: 0.83, stretchY: 1.01, stretchX: 0.995, brow: 0.05, mouth: 0.03, eyeClose: 0.18, blush: 0.50, effort: 0.02, smile: 1.05),
        Knot(t: 1.00, stretchY: 1.00, stretchX: 1.00, brow: 0.08, mouth: 0.00, eyeClose: 0.00, blush: 0.48, effort: 0.00, smile: 1.00)
    ]

    private static func sampled(knots: [Knot], progress: Double, time: TimeInterval) -> PipMascotPose {
        var pose = knot(at: progress, in: knots)
        let tremor = smoothstep((pose.effort - 0.62) / 0.38)
        let organicWave = sin(time * 15.7) + 0.35 * sin(time * 23.1 + 0.8)
        pose.shake = organicWave * 0.55 * tremor
        pose.tilt += pose.shake * 0.12
        pose.turn += sin(time * 0.9) * 0.65 * (1 - pose.effort)
        return clamped(pose)
    }

    private static func knot(at t: Double, in knots: [Knot]) -> PipMascotPose {
        let clamped = min(max(t, 0), 1)
        guard let last = knots.last, let first = knots.first else {
            return .rest
        }
        if clamped <= first.t { return first.pose }
        if clamped >= last.t { return last.pose }

        for index in 1..<knots.count {
            let right = knots[index]
            let left = knots[index - 1]
            if clamped <= right.t {
                let span = max(right.t - left.t, 0.0001)
                let local = (clamped - left.t) / span
                return hermitePose(leftIndex: index - 1, knots: knots, t: local)
            }
        }
        return last.pose
    }

    private static func hermitePose(leftIndex: Int, knots: [Knot], t: Double) -> PipMascotPose {
        PipMascotPose(
            stretchY: hermite(\.stretchY, leftIndex: leftIndex, knots: knots, t: t),
            stretchX: hermite(\.stretchX, leftIndex: leftIndex, knots: knots, t: t),
            brow: hermite(\.brow, leftIndex: leftIndex, knots: knots, t: t),
            mouth: hermite(\.mouth, leftIndex: leftIndex, knots: knots, t: t),
            eyeClose: hermite(\.eyeClose, leftIndex: leftIndex, knots: knots, t: t),
            blush: hermite(\.blush, leftIndex: leftIndex, knots: knots, t: t),
            effort: hermite(\.effort, leftIndex: leftIndex, knots: knots, t: t),
            smile: hermite(\.smile, leftIndex: leftIndex, knots: knots, t: t),
            bounce: hermite(\.bounce, leftIndex: leftIndex, knots: knots, t: t),
            shake: 0,
            tilt: hermite(\.tilt, leftIndex: leftIndex, knots: knots, t: t),
            turn: hermite(\.turn, leftIndex: leftIndex, knots: knots, t: t)
        )
    }

    private static func hermite(
        _ keyPath: KeyPath<PipMascotPose, Double>,
        leftIndex: Int,
        knots: [Knot],
        t: Double
    ) -> Double {
        let rightIndex = leftIndex + 1
        let left = knots[leftIndex]
        let right = knots[rightIndex]
        let span = max(right.t - left.t, 0.0001)
        let p0 = left.pose[keyPath: keyPath]
        let p1 = right.pose[keyPath: keyPath]
        let m0 = tangent(keyPath, at: leftIndex, knots: knots) * span
        let m1 = tangent(keyPath, at: rightIndex, knots: knots) * span
        let x = min(max(t, 0), 1)
        let x2 = x * x
        let x3 = x2 * x
        return (2 * x3 - 3 * x2 + 1) * p0
            + (x3 - 2 * x2 + x) * m0
            + (-2 * x3 + 3 * x2) * p1
            + (x3 - x2) * m1
    }

    private static func tangent(
        _ keyPath: KeyPath<PipMascotPose, Double>,
        at index: Int,
        knots: [Knot]
    ) -> Double {
        guard index > 0, index < knots.count - 1 else {
            return 0
        }
        let previous = knots[index - 1]
        let next = knots[index + 1]
        let span = max(next.t - previous.t, 0.0001)
        return (next.pose[keyPath: keyPath] - previous.pose[keyPath: keyPath]) / span
    }

    private static func clamped(_ pose: PipMascotPose) -> PipMascotPose {
        var result = pose
        result.stretchY = min(max(result.stretchY, 0.94), 1.24)
        result.stretchX = min(max(result.stretchX, 0.83), 1.04)
        result.brow = min(max(result.brow, 0), 1)
        result.mouth = min(max(result.mouth, 0), 1.5)
        result.eyeClose = min(max(result.eyeClose, 0), 1)
        result.blush = min(max(result.blush, 0), 1)
        result.effort = min(max(result.effort, 0), 1)
        result.smile = min(max(result.smile, 0), 1.4)
        result.tilt = min(max(result.tilt, -2), 2)
        result.turn = min(max(result.turn, -5), 5)
        return result
    }

    private static func smoothstep(_ value: Double) -> Double {
        let x = min(max(value, 0), 1)
        return x * x * (3 - 2 * x)
    }

    private static func blink(at time: TimeInterval, every interval: Double) -> Double {
        let phase = time.truncatingRemainder(dividingBy: interval)
        let distance = (phase - 0.18) / 0.055
        return exp(-(distance * distance))
    }
}

struct PipMascotCanvas: View {
    let pose: PipMascotPose
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            draw(in: &context, size: canvasSize)
        }
        .frame(width: size, height: size)
        .rotation3DEffect(
            .degrees(pose.turn),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.34
        )
        .rotationEffect(.degrees(pose.tilt), anchor: .bottom)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let ink = Color(red: 0.12, green: 0.16, blue: 0.17)
        let mintLight = Color(red: 0.72, green: 0.93, blue: 0.85)
        let mint = PipTheme.mint
        let mintDeep = Color(red: 0.30, green: 0.68, blue: 0.58)
        let blush = Color(red: 1.00, green: 0.67, blue: 0.43)

        let plantedBottom = size.height * 0.88
        let baseHeight = size.height * 0.70
        let height = baseHeight * pose.stretchY
        let width = size.width * 0.64 * pose.stretchX
        let center = CGPoint(
            x: size.width * 0.50 + pose.shake,
            y: plantedBottom - height * 0.50 + pose.bounce
        )

        let droplet = dropletPath(center: center, width: width, height: height)
        let lifted = max(0, -pose.bounce)

        drawContactShadow(
            in: &context,
            center: center,
            width: width,
            plantedBottom: plantedBottom,
            lifted: lifted,
            size: size
        )

        if pose.effort > 0.05 {
            drawSweat(in: &context, center: center, width: width, height: height, ink: mintDeep)
        }

        let depthOffset = max(2, size.width * 0.012)
        let depthPath = dropletPath(
            center: CGPoint(x: center.x + size.width * 0.004, y: center.y + depthOffset),
            width: width,
            height: height
        )
        context.fill(depthPath, with: .color(mintDeep.opacity(0.72)))

        let gradient = Gradient(colors: [Color.white, mintLight, mint, mintDeep])
        context.fill(
            droplet,
            with: .radialGradient(
                gradient,
                center: CGPoint(x: center.x - width * 0.24, y: center.y - height * 0.30),
                startRadius: 0,
                endRadius: max(width, height) * 0.82
            )
        )

        context.drawLayer { layer in
            layer.clip(to: droplet)
            layer.fill(
                droplet,
                with: .linearGradient(
                    Gradient(colors: [.clear, .clear, mintDeep.opacity(0.34)]),
                    startPoint: CGPoint(x: center.x - width * 0.38, y: center.y),
                    endPoint: CGPoint(x: center.x + width * 0.50, y: center.y)
                )
            )

            var reflectedLight = Path()
            reflectedLight.addEllipse(
                in: CGRect(
                    x: center.x - width * 0.42,
                    y: center.y + height * 0.28,
                    width: width * 0.84,
                    height: height * 0.22
                )
            )
            layer.fill(reflectedLight, with: .color(PipTheme.mintGlow.opacity(0.16)))
        }

        context.stroke(
            droplet,
            with: .color(ink.opacity(0.90)),
            style: StrokeStyle(lineWidth: max(4, size.width * 0.026), lineJoin: .round)
        )
        context.stroke(
            droplet,
            with: .color(.white.opacity(0.16)),
            style: StrokeStyle(lineWidth: max(1, size.width * 0.007), lineJoin: .round)
        )

        var highlight = Path()
        highlight.move(to: CGPoint(x: center.x - width * 0.25, y: center.y - height * 0.28))
        highlight.addCurve(
            to: CGPoint(x: center.x - width * 0.32, y: center.y + height * 0.02),
            control1: CGPoint(x: center.x - width * 0.35, y: center.y - height * 0.20),
            control2: CGPoint(x: center.x - width * 0.37, y: center.y - height * 0.07)
        )
        context.stroke(
            highlight,
            with: .color(.white.opacity(0.50)),
            style: StrokeStyle(lineWidth: max(3, width * 0.055), lineCap: .round)
        )

        var bubble = Path()
        bubble.addEllipse(
            in: CGRect(
                x: center.x - width * 0.25,
                y: center.y - height * 0.36,
                width: width * 0.09,
                height: height * 0.055
            )
        )
        context.fill(bubble, with: .color(.white.opacity(0.58)))

        context.drawLayer { layer in
            layer.clip(to: droplet)
            drawFace(
                in: &layer,
                center: center,
                width: width,
                height: height,
                ink: ink,
                blush: blush
            )
        }

        if pose.smile > 1.0 {
            drawSparkles(in: &context, center: center, width: width, height: height)
        }
    }

    private func dropletPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        let half = width / 2
        let lean = CGFloat(pose.turn / 5) * width * 0.025
        let top = CGPoint(x: center.x + lean, y: center.y - height / 2)
        let bottom = CGPoint(x: center.x, y: center.y + height / 2)
        let rightShoulder = CGPoint(x: center.x + half * 0.72, y: center.y - height * 0.10)
        let leftShoulder = CGPoint(x: center.x - half * 0.72, y: center.y - height * 0.10)
        var path = Path()
        path.move(to: top)
        path.addCurve(
            to: rightShoulder,
            control1: CGPoint(x: top.x + half * 0.10, y: top.y + height * 0.14),
            control2: CGPoint(x: center.x + half * 0.55, y: center.y - height * 0.28)
        )
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: center.x + half * 1.12, y: center.y + height * 0.20),
            control2: CGPoint(x: center.x + half * 0.56, y: bottom.y)
        )
        path.addCurve(
            to: leftShoulder,
            control1: CGPoint(x: center.x - half * 0.56, y: bottom.y),
            control2: CGPoint(x: center.x - half * 1.12, y: center.y + height * 0.20)
        )
        path.addCurve(
            to: top,
            control1: CGPoint(x: center.x - half * 0.55, y: center.y - height * 0.28),
            control2: CGPoint(x: top.x - half * 0.10, y: top.y + height * 0.14)
        )
        path.closeSubpath()
        return path
    }

    private func drawContactShadow(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        plantedBottom: CGFloat,
        lifted: CGFloat,
        size: CGSize
    ) {
        let liftRatio = min(lifted / max(size.height * 0.08, 1), 1)
        let shadowWidth = width * (0.72 - 0.16 * liftRatio)
        let shadowHeight = max(5, size.height * (0.032 + 0.008 * pose.effort))
        var shadow = Path()
        shadow.addEllipse(
            in: CGRect(
                x: center.x - shadowWidth / 2,
                y: plantedBottom - shadowHeight * 0.15,
                width: shadowWidth,
                height: shadowHeight
            )
        )
        context.fill(
            shadow,
            with: .radialGradient(
                Gradient(colors: [.black.opacity(0.20 - 0.08 * liftRatio), .clear]),
                center: CGPoint(x: center.x, y: plantedBottom + shadowHeight * 0.35),
                startRadius: 0,
                endRadius: shadowWidth * 0.52
            )
        )
    }

    private func drawFace(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color,
        blush: Color
    ) {
        let faceShift = width * 0.035 * CGFloat(pose.turn / 5)
        let faceCenter = CGPoint(x: center.x + faceShift, y: center.y)
        let faceY = faceCenter.y + height * 0.04
        let eyeY = faceY - height * 0.02
        let eyeSpread = width * 0.20
        let eyeW = width * 0.15
        let eyeH = height * 0.13 * (1 - 0.88 * pose.eyeClose)
        let leftEye = CGPoint(x: faceCenter.x - eyeSpread, y: eyeY)
        let rightEye = CGPoint(x: faceCenter.x + eyeSpread, y: eyeY)

        drawBlush(in: &context, at: CGPoint(x: leftEye.x - width * 0.02, y: faceY + height * 0.08), width: width, blush: blush)
        drawBlush(in: &context, at: CGPoint(x: rightEye.x + width * 0.02, y: faceY + height * 0.08), width: width, blush: blush)

        drawEye(in: &context, at: leftEye, width: eyeW, height: max(eyeH, 1), ink: ink)
        drawEye(in: &context, at: rightEye, width: eyeW, height: max(eyeH, 1), ink: ink)
        drawBrow(in: &context, at: leftEye, width: eyeW, height: height, ink: ink, flipped: false)
        drawBrow(in: &context, at: rightEye, width: eyeW, height: height, ink: ink, flipped: true)
        drawMouth(in: &context, center: CGPoint(x: faceCenter.x, y: faceY + height * 0.14), width: width, height: height, ink: ink)
    }

    private func drawBlush(
        in context: inout GraphicsContext,
        at point: CGPoint,
        width: CGFloat,
        blush: Color
    ) {
        var path = Path()
        let w = width * 0.16
        path.addEllipse(in: CGRect(x: point.x - w / 2, y: point.y - w * 0.32, width: w, height: w * 0.64))
        context.fill(path, with: .color(blush.opacity(0.28 + 0.42 * pose.blush)))
    }

    private func drawEye(
        in context: inout GraphicsContext,
        at point: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color
    ) {
        var white = Path()
        white.addEllipse(in: CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height))
        context.fill(white, with: .color(.white))
        context.stroke(white, with: .color(ink), style: StrokeStyle(lineWidth: max(2, width * 0.12)))

        let pupilW = width * 0.58
        let pupilH = height * 0.62
        var pupil = Path()
        pupil.addEllipse(in: CGRect(x: point.x - pupilW / 2, y: point.y - pupilH / 2 + height * 0.04, width: pupilW, height: pupilH))
        context.fill(pupil, with: .color(ink))

        var shine = Path()
        shine.addEllipse(in: CGRect(x: point.x - width * 0.08, y: point.y - height * 0.28, width: width * 0.22, height: height * 0.22))
        context.fill(shine, with: .color(.white.opacity(0.95)))
    }

    private func drawBrow(
        in context: inout GraphicsContext,
        at eye: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color,
        flipped: Bool
    ) {
        let drop = height * 0.028 * pose.brow
        let inward = width * 0.35 * pose.brow
        let y = eye.y - height * 0.12
        let sign: CGFloat = flipped ? 1 : -1
        var path = Path()
        path.move(to: CGPoint(x: eye.x + sign * width * 0.58, y: y - height * 0.01 + drop * 0.2))
        path.addQuadCurve(
            to: CGPoint(x: eye.x - sign * width * 0.22, y: y + drop),
            control: CGPoint(x: eye.x + sign * width * 0.08, y: y - height * 0.02 - inward * 0.04)
        )
        context.stroke(
            path,
            with: .color(ink),
            style: StrokeStyle(lineWidth: max(3.2, width * 0.18), lineCap: .round)
        )
    }

    private func drawMouth(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color
    ) {
        let value = pose.mouth
        let smileAlpha = 1 - ease((value - 0.28) / 0.24)
        let gritAlpha = ease((value - 0.24) / 0.22) * (1 - ease((value - 0.72) / 0.22))
        let teethAlpha = ease((value - 0.66) / 0.24) * (1 - ease((value - 1.10) / 0.20))
        let openAlpha = ease((value - 1.04) / 0.24)

        drawMouthLayer(in: &context, opacity: smileAlpha) { layer in
            drawSmileMouth(in: &layer, center: center, width: width, height: height, ink: ink)
        }
        drawMouthLayer(in: &context, opacity: gritAlpha) { layer in
            drawGritMouth(in: &layer, center: center, width: width, height: height, ink: ink, value: value)
        }
        drawMouthLayer(in: &context, opacity: teethAlpha) { layer in
            drawTeethMouth(in: &layer, center: center, width: width, height: height, ink: ink)
        }
        drawMouthLayer(in: &context, opacity: openAlpha) { layer in
            drawOpenMouth(in: &layer, center: center, width: width, height: height, ink: ink, value: value)
        }
    }

    private func drawMouthLayer(
        in context: inout GraphicsContext,
        opacity: Double,
        content: (inout GraphicsContext) -> Void
    ) {
        guard opacity > 0.001 else {
            return
        }
        context.drawLayer { layer in
            layer.opacity = opacity
            content(&layer)
        }
    }

    private func drawSmileMouth(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color
    ) {
        var path = Path()
        let w = width * (0.13 + 0.035 * pose.smile)
        let h = height * 0.042 * max(pose.smile, 0.2)
        path.move(to: CGPoint(x: center.x - w, y: center.y - h * 0.2))
        path.addQuadCurve(
            to: CGPoint(x: center.x + w, y: center.y - h * 0.2),
            control: CGPoint(x: center.x, y: center.y + h * 2.2)
        )
        context.stroke(
            path,
            with: .color(ink),
            style: StrokeStyle(lineWidth: max(3.4, width * 0.045), lineCap: .round)
        )
    }

    private func drawGritMouth(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color,
        value: Double
    ) {
        let grit = min(max((value - 0.35) / 0.55, 0), 1)
        var path = Path()
        let w = width * (0.14 - 0.018 * grit)
        path.move(to: CGPoint(x: center.x - w, y: center.y))
        path.addLine(to: CGPoint(x: center.x + w, y: center.y + height * 0.01 * grit))
        context.stroke(
            path,
            with: .color(ink),
            style: StrokeStyle(lineWidth: max(3.2, width * 0.05), lineCap: .round)
        )
    }

    private func drawTeethMouth(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color
    ) {
        let w = width * 0.15
        let h = height * 0.07
        var gum = Path()
        gum.addRoundedRect(
            in: CGRect(x: center.x - w, y: center.y - h * 0.45, width: w * 2, height: h),
            cornerSize: CGSize(width: h * 0.45, height: h * 0.45)
        )
        context.fill(gum, with: .color(ink))

        let toothW = w * 0.42
        let toothH = h * 0.42
        var left = Path()
        left.addRoundedRect(
            in: CGRect(x: center.x - toothW - 1, y: center.y - toothH * 0.15, width: toothW, height: toothH),
            cornerSize: CGSize(width: 2, height: 2)
        )
        var right = Path()
        right.addRoundedRect(
            in: CGRect(x: center.x + 1, y: center.y - toothH * 0.15, width: toothW, height: toothH),
            cornerSize: CGSize(width: 2, height: 2)
        )
        context.fill(left, with: .color(.white))
        context.fill(right, with: .color(.white))
    }

    private func drawOpenMouth(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color,
        value: Double
    ) {
        let open = ease((value - 1.04) / 0.36)
        let w = width * (0.08 + 0.04 * open)
        let h = height * (0.07 + 0.04 * open)
        var oval = Path()
        oval.addEllipse(in: CGRect(x: center.x - w, y: center.y - h * 0.35, width: w * 2, height: h))
        context.fill(oval, with: .color(ink))

        var inner = Path()
        inner.addEllipse(
            in: CGRect(
                x: center.x - w * 0.55,
                y: center.y - h * 0.05,
                width: w * 1.1,
                height: h * 0.45
            )
        )
        context.fill(inner, with: .color(Color(red: 0.75, green: 0.28, blue: 0.32).opacity(0.85)))
    }

    private func ease(_ value: Double) -> Double {
        let x = min(max(value, 0), 1)
        return x * x * (3 - 2 * x)
    }

    private func drawSweat(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color
    ) {
        let fall = pose.effort * height * 0.08
        drawSweatDrop(
            in: &context,
            at: CGPoint(x: center.x + width * 0.42, y: center.y - height * 0.28 + fall),
            scale: 1,
            ink: ink
        )
        drawSweatDrop(
            in: &context,
            at: CGPoint(x: center.x + width * 0.50, y: center.y - height * 0.08 + fall * 1.4),
            scale: 0.72,
            ink: ink
        )
    }

    private func drawSweatDrop(
        in context: inout GraphicsContext,
        at point: CGPoint,
        scale: CGFloat,
        ink: Color
    ) {
        let w: CGFloat = 7 * scale
        let h: CGFloat = 12 * scale
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - h / 2))
        path.addQuadCurve(
            to: CGPoint(x: point.x, y: point.y + h / 2),
            control: CGPoint(x: point.x + w, y: point.y)
        )
        path.addQuadCurve(
            to: CGPoint(x: point.x, y: point.y - h / 2),
            control: CGPoint(x: point.x - w, y: point.y)
        )
        let visibility = ease((pose.effort - 0.05) / 0.32)
        context.fill(
            path,
            with: .color(PipTheme.mintGlow.opacity((0.25 + 0.5 * pose.effort) * visibility))
        )
        context.stroke(
            path,
            with: .color(ink.opacity(0.42 * visibility)),
            style: StrokeStyle(lineWidth: 1.2)
        )
    }

    private func drawSparkles(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
        let visibility = ease((pose.smile - 1.0) / 0.25)
        let points = [
            CGPoint(x: center.x - width * 0.58, y: center.y - height * 0.18),
            CGPoint(x: center.x + width * 0.52, y: center.y - height * 0.32),
            CGPoint(x: center.x + width * 0.46, y: center.y + height * 0.16)
        ]
        for (index, point) in points.enumerated() {
            let radius: CGFloat = index == 0 ? 6 : 4.5
            var star = Path()
            star.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius * 0.25, width: radius * 2, height: radius * 0.5))
            var cross = Path()
            cross.addEllipse(in: CGRect(x: point.x - radius * 0.25, y: point.y - radius, width: radius * 0.5, height: radius * 2))
            context.fill(star, with: .color(PipTheme.warmApricot.opacity(0.9 * visibility)))
            context.fill(cross, with: .color(PipTheme.warmApricot.opacity(0.9 * visibility)))
        }
    }
}
