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
        shake: 0
    )
}

enum PipMascotMotion {
    static let framesPerPhase = 120

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
                return knot(at: 0.72, in: liftKnots)
            case .release:
                return knot(at: 0.28, in: releaseKnots)
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
        let breath = 0.5 + 0.5 * sin(time * 2.15)
        var pose = PipMascotPose.rest
        pose.stretchY = 1.0 + 0.035 * breath
        pose.stretchX = 1.0 - 0.022 * breath
        pose.bounce = -6 * breath
        pose.blush = 0.42 + 0.08 * breath
        return pose
    }

    private static func donePose(at time: TimeInterval) -> PipMascotPose {
        let hop = max(0, sin(time * 5.2))
        var pose = PipMascotPose.rest
        pose.smile = 1.35
        pose.stretchY = 1.04 + 0.05 * hop
        pose.stretchX = 0.97 - 0.03 * hop
        pose.bounce = -10 * hop
        pose.blush = 0.7
        pose.eyeClose = 0.12 * hop
        return pose
    }

    private struct Knot {
        var t: Double
        var stretchY: Double
        var stretchX: Double
        var brow: Double
        var mouth: Double
        var eyeClose: Double
        var blush: Double
        var effort: Double
        var smile: Double
    }

    private static let liftKnots: [Knot] = [
        Knot(t: 0.00, stretchY: 1.00, stretchX: 1.00, brow: 0.08, mouth: 0.00, eyeClose: 0.00, blush: 0.48, effort: 0.00, smile: 1.00),
        Knot(t: 0.08, stretchY: 0.94, stretchX: 1.08, brow: 0.22, mouth: 0.22, eyeClose: 0.00, blush: 0.55, effort: 0.12, smile: 0.70),
        Knot(t: 0.16, stretchY: 0.84, stretchX: 1.16, brow: 0.48, mouth: 0.48, eyeClose: 0.04, blush: 0.66, effort: 0.32, smile: 0.20),
        Knot(t: 0.28, stretchY: 0.96, stretchX: 1.04, brow: 0.62, mouth: 0.62, eyeClose: 0.05, blush: 0.74, effort: 0.50, smile: 0.00),
        Knot(t: 0.46, stretchY: 1.16, stretchX: 0.88, brow: 0.80, mouth: 0.82, eyeClose: 0.08, blush: 0.84, effort: 0.74, smile: 0.00),
        Knot(t: 0.68, stretchY: 1.30, stretchX: 0.80, brow: 0.93, mouth: 0.96, eyeClose: 0.12, blush: 0.93, effort: 0.90, smile: 0.00),
        Knot(t: 0.86, stretchY: 1.38, stretchX: 0.75, brow: 0.98, mouth: 1.00, eyeClose: 0.15, blush: 0.98, effort: 0.97, smile: 0.00),
        Knot(t: 1.00, stretchY: 1.40, stretchX: 0.74, brow: 1.00, mouth: 1.00, eyeClose: 0.16, blush: 1.00, effort: 1.00, smile: 0.00)
    ]

    private static let releaseKnots: [Knot] = [
        Knot(t: 0.00, stretchY: 1.40, stretchX: 0.74, brow: 1.00, mouth: 1.00, eyeClose: 0.16, blush: 1.00, effort: 1.00, smile: 0.00),
        Knot(t: 0.10, stretchY: 1.34, stretchX: 0.78, brow: 0.78, mouth: 1.28, eyeClose: 0.10, blush: 0.90, effort: 0.72, smile: 0.00),
        Knot(t: 0.22, stretchY: 1.22, stretchX: 0.86, brow: 0.42, mouth: 1.50, eyeClose: 0.18, blush: 0.76, effort: 0.42, smile: 0.15),
        Knot(t: 0.40, stretchY: 1.08, stretchX: 0.96, brow: 0.18, mouth: 0.55, eyeClose: 0.72, blush: 0.62, effort: 0.18, smile: 0.85),
        Knot(t: 0.58, stretchY: 1.00, stretchX: 1.02, brow: 0.08, mouth: 0.12, eyeClose: 0.92, blush: 0.55, effort: 0.06, smile: 1.10),
        Knot(t: 0.76, stretchY: 0.97, stretchX: 1.05, brow: 0.05, mouth: 0.04, eyeClose: 0.28, blush: 0.50, effort: 0.02, smile: 1.05),
        Knot(t: 1.00, stretchY: 1.00, stretchX: 1.00, brow: 0.08, mouth: 0.00, eyeClose: 0.00, blush: 0.48, effort: 0.00, smile: 1.00)
    ]

    private static func sampled(knots: [Knot], progress: Double, time: TimeInterval) -> PipMascotPose {
        let t = min(max(progress, 0), 1)
        let frame = t * Double(framesPerPhase - 1)
        let i = Int(frame)
        let fraction = frame - Double(i)
        let a = knot(at: Double(i) / Double(framesPerPhase - 1), in: knots)
        let b = knot(at: Double(min(i + 1, framesPerPhase - 1)) / Double(framesPerPhase - 1), in: knots)
        var pose = mix(a, b, cosine(fraction))
        if pose.effort > 0.55 {
            pose.shake = sin(time * 26) * 2.4 * pose.effort
        }
        return pose
    }

    private static func knot(at t: Double, in knots: [Knot]) -> PipMascotPose {
        let clamped = min(max(t, 0), 1)
        guard let last = knots.last, let first = knots.first else {
            return .rest
        }
        if clamped <= first.t { return pose(from: first) }
        if clamped >= last.t { return pose(from: last) }

        for index in 1..<knots.count {
            let right = knots[index]
            let left = knots[index - 1]
            if clamped <= right.t {
                let span = max(right.t - left.t, 0.0001)
                let local = cosine((clamped - left.t) / span)
                return mix(pose(from: left), pose(from: right), local)
            }
        }
        return pose(from: last)
    }

    private static func pose(from knot: Knot) -> PipMascotPose {
        PipMascotPose(
            stretchY: knot.stretchY,
            stretchX: knot.stretchX,
            brow: knot.brow,
            mouth: knot.mouth,
            eyeClose: knot.eyeClose,
            blush: knot.blush,
            effort: knot.effort,
            smile: knot.smile,
            bounce: 0,
            shake: 0
        )
    }

    private static func mix(_ a: PipMascotPose, _ b: PipMascotPose, _ t: Double) -> PipMascotPose {
        PipMascotPose(
            stretchY: lerp(a.stretchY, b.stretchY, t),
            stretchX: lerp(a.stretchX, b.stretchX, t),
            brow: lerp(a.brow, b.brow, t),
            mouth: lerp(a.mouth, b.mouth, t),
            eyeClose: lerp(a.eyeClose, b.eyeClose, t),
            blush: lerp(a.blush, b.blush, t),
            effort: lerp(a.effort, b.effort, t),
            smile: lerp(a.smile, b.smile, t),
            bounce: lerp(a.bounce, b.bounce, t),
            shake: lerp(a.shake, b.shake, t)
        )
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private static func cosine(_ t: Double) -> Double {
        0.5 - 0.5 * cos(min(max(t, 0), 1) * .pi)
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
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let ink = Color(red: 0.12, green: 0.16, blue: 0.17)
        let mintLight = Color(red: 0.72, green: 0.93, blue: 0.85)
        let mint = PipTheme.mint
        let mintDeep = Color(red: 0.30, green: 0.68, blue: 0.58)
        let blush = Color(red: 1.00, green: 0.67, blue: 0.43)

        let plantedBottom = size.height * 0.90
        let baseHeight = size.height * 0.78
        let height = baseHeight * pose.stretchY
        let width = size.width * 0.62 * pose.stretchX
        let center = CGPoint(
            x: size.width * 0.50 + pose.shake,
            y: plantedBottom - height * 0.50 + pose.bounce
        )

        let droplet = dropletPath(center: center, width: width, height: height)

        if pose.effort > 0.2 {
            drawSweat(in: &context, center: center, width: width, height: height, ink: mintDeep)
        }

        let gradient = Gradient(colors: [mintLight, mint, mintDeep])
        context.fill(
            droplet,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: center.x - width * 0.35, y: center.y - height * 0.45),
                endPoint: CGPoint(x: center.x + width * 0.30, y: center.y + height * 0.48)
            )
        )
        context.stroke(
            droplet,
            with: .color(ink),
            style: StrokeStyle(lineWidth: max(4, size * 0.028), lineJoin: .round)
        )

        var highlight = Path()
        let hx = center.x - width * 0.16
        let hy = center.y - height * 0.22
        highlight.addEllipse(in: CGRect(x: hx - width * 0.13, y: hy - height * 0.10, width: width * 0.26, height: height * 0.20))
        context.fill(highlight, with: .color(.white.opacity(0.42)))

        var bubble = Path()
        bubble.addEllipse(in: CGRect(x: center.x + width * 0.18, y: center.y + height * 0.16, width: width * 0.08, height: height * 0.05))
        context.fill(bubble, with: .color(.white.opacity(0.22)))

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

        if pose.smile > 1.12 {
            drawSparkles(in: &context, center: center, width: width, height: height)
        }
    }

    private func dropletPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        let half = width / 2
        let top = CGPoint(x: center.x, y: center.y - height / 2)
        let bottom = CGPoint(x: center.x, y: center.y + height / 2)
        var path = Path()
        path.move(to: top)
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: center.x + half * 0.18, y: top.y + height * 0.20),
            control2: CGPoint(x: center.x + half, y: bottom.y - height * 0.30)
        )
        path.addCurve(
            to: top,
            control1: CGPoint(x: center.x - half, y: bottom.y - height * 0.30),
            control2: CGPoint(x: center.x - half * 0.18, y: top.y + height * 0.20)
        )
        path.closeSubpath()
        return path
    }

    private func drawFace(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        ink: Color,
        blush: Color
    ) {
        let faceY = center.y + height * 0.04
        let eyeY = faceY - height * 0.02
        let eyeSpread = width * 0.20
        let eyeW = width * 0.15
        let eyeH = height * 0.13 * (1 - 0.55 * pose.eyeClose)
        let leftEye = CGPoint(x: center.x - eyeSpread, y: eyeY)
        let rightEye = CGPoint(x: center.x + eyeSpread, y: eyeY)

        drawBlush(in: &context, at: CGPoint(x: leftEye.x - width * 0.02, y: faceY + height * 0.08), width: width, blush: blush)
        drawBlush(in: &context, at: CGPoint(x: rightEye.x + width * 0.02, y: faceY + height * 0.08), width: width, blush: blush)

        drawEye(in: &context, at: leftEye, width: eyeW, height: max(eyeH, 1), ink: ink)
        drawEye(in: &context, at: rightEye, width: eyeW, height: max(eyeH, 1), ink: ink)
        drawBrow(in: &context, at: leftEye, width: eyeW, height: height, ink: ink, flipped: false)
        drawBrow(in: &context, at: rightEye, width: eyeW, height: height, ink: ink, flipped: true)
        drawMouth(in: &context, center: CGPoint(x: center.x, y: faceY + height * 0.14), width: width, height: height, ink: ink)
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
        if value < 0.45 {
            let openness = 1 - value / 0.45
            var path = Path()
            let w = width * (0.16 + 0.06 * pose.smile) * (0.7 + 0.3 * openness)
            let h = height * 0.045 * pose.smile * openness
            path.move(to: CGPoint(x: center.x - w, y: center.y - h * 0.2))
            path.addQuadCurve(
                to: CGPoint(x: center.x + w, y: center.y - h * 0.2),
                control: CGPoint(x: center.x, y: center.y + h * 2.2)
            )
            context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: max(3.4, width * 0.045), lineCap: .round))
            return
        }

        if value < 0.85 {
            let grit = (value - 0.45) / 0.40
            var path = Path()
            let w = width * (0.14 - 0.02 * grit)
            path.move(to: CGPoint(x: center.x - w, y: center.y))
            path.addLine(to: CGPoint(x: center.x + w, y: center.y + height * 0.01 * grit))
            context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: max(3.2, width * 0.05), lineCap: .round))
            return
        }

        if value < 1.22 {
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
            return
        }

        let open = min((value - 1.22) / 0.28, 1)
        let w = width * (0.08 + 0.04 * open)
        let h = height * (0.07 + 0.04 * open)
        var oval = Path()
        oval.addEllipse(in: CGRect(x: center.x - w, y: center.y - h * 0.35, width: w * 2, height: h))
        context.fill(oval, with: .color(ink))
        var inner = Path()
        inner.addEllipse(in: CGRect(x: center.x - w * 0.55, y: center.y - h * 0.05, width: w * 1.1, height: h * 0.45))
        context.fill(inner, with: .color(Color(red: 0.75, green: 0.28, blue: 0.32).opacity(0.85)))
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
        context.fill(path, with: .color(PipTheme.mintGlow.opacity(0.35 + 0.45 * pose.effort)))
        context.stroke(path, with: .color(ink.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2))
    }

    private func drawSparkles(
        in context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
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
            context.fill(star, with: .color(PipTheme.warmApricot.opacity(0.9)))
            context.fill(cross, with: .color(PipTheme.warmApricot.opacity(0.9)))
        }
    }
}
