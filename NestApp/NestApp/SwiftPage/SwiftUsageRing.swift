import NestKit
import SwiftUI

/// The week as a ring: what is used in Swift's colour, the room left up to your cap as a full track, a thin line past it,
/// and a white mark at the cap.
struct SwiftUsageRing: View {
    /// How much of the week is used (0 to 1).
    let used: Double
    /// Your cap (0 to 1).
    let cap: Double

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    private let stroke = NestSpace.s2

    var body: some View {
        ZStack {
            Circle()
                .trim(from: cap, to: 1)
                .stroke(Color(NestColor.line), lineWidth: NestSpace.s1 / 2)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: min(used, cap), to: cap)
                .stroke(Color(NestColor.lineStrong), style: StrokeStyle(lineWidth: stroke, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: used)
                .stroke(Color(Bird.swift.color), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Capsule()
                .fill(Color(NestColor.textPrimary))
                .frame(width: NestSpace.s1 / 2, height: stroke + NestSpace.s2)
                .offset(y: -(NestSpace.s9 - stroke) / 2)
                .rotationEffect(.degrees(cap * 360))
            VStack(spacing: 0) {
                Text("\(Int((used * 100).rounded()))%")
                    .nestFont(.title)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textPrimary))
                Text("of the week")
                    .nestFont(.caption)
                    .foregroundStyle(Color(NestColor.textMuted))
            }
        }
        .frame(width: NestSpace.s9, height: NestSpace.s9)
        .animation(reduceMotionOverride ?? systemReduceMotion ? nil : .nest(NestMotion.slow), value: cap)
        .animation(reduceMotionOverride ?? systemReduceMotion ? nil : .nest(NestMotion.slow), value: used)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int((used * 100).rounded()))% of the week used, your cap is \(Int((cap * 100).rounded()))%")
        .accessibilityIdentifier("swift.limits.ring")
    }
}
