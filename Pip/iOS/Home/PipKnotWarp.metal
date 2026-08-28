#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

/// Inverse-maps one rasterized SwiftUI layer. The body, eyes and mouth enter
/// this shader together, which keeps the expression attached to the clay.
///
/// deformation: -1 = low/wide, +1 = tall/upright
/// bend/twist/pinch: continuous secondary soft-body motion
[[ stitchable ]]
float2 pipKnotWarp(
    float2 position,
    float2 size,
    float deformation,
    float bend,
    float twist,
    float pinch
) {
    const float2 halfSize = max(size * 0.5, float2(1.0));
    float2 point = (position - halfSize) / halfSize;

    const float tall = max(deformation, 0.0);
    const float flat = max(-deformation, 0.0);
    const float scaleX = max(0.45, 1.0 - 0.24 * tall + 0.31 * flat);
    const float scaleY = max(0.45, 1.0 + 0.38 * tall - 0.27 * flat);

    // Inverse scale produces the visible stretch without switching source art.
    point.x /= scaleX;
    point.y /= scaleY;

    const float verticalEnvelope = saturate(1.0 - point.y * point.y);
    const float radialEnvelope = saturate(1.0 - 0.32 * dot(point, point));

    // Broad lean, gentle shear and a soft wave create a clay-like response.
    point.x -= bend * verticalEnvelope * (0.17 + 0.045 * point.y);
    point.x -= twist * point.y * 0.105 * radialEnvelope;
    point.y -= twist
        * sin(point.x * 3.14159265)
        * verticalEnvelope
        * radialEnvelope
        * 0.075;

    // A localized radial displacement makes the inner lobe breathe instead of
    // making the entire character look like a uniformly stretched sticker.
    const float2 cavityCenter = float2(0.10, -0.05);
    const float2 cavityVector = point - cavityCenter;
    const float cavityDistanceSquared = dot(cavityVector, cavityVector);
    const float cavityFalloff = exp(-cavityDistanceSquared * 3.8);
    const float2 cavityDirection = cavityVector
        * rsqrt(max(cavityDistanceSquared, 0.0025));
    point += cavityDirection * pinch * cavityFalloff * 0.085;

    return point * halfSize + halfSize;
}
