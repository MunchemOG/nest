import NestKit
import SwiftUI

/// Your limits for Swift: the week as a ring with your cap on it, the caps you drag, what they buy, and this project's share.
struct SwiftLimitsPanel: View {
    let page: SwiftPageModel

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s4) {
                HStack(spacing: NestSpace.s4) {
                    SwiftUsageRing(used: page.reported?.weekly ?? 0, cap: page.limits.weeklyCap)
                    VStack(alignment: .leading, spacing: NestSpace.s1) {
                        Text("Your limits")
                            .nestFont(.title)
                            .foregroundStyle(Color(NestColor.textPrimary))
                        Text(page.tasksLeftLine)
                            .nestFont(.bodyS)
                            .foregroundStyle(Color(Bird.swift.color))
                            .accessibilityIdentifier("swift.limits.left")
                        Text(page.fiveHourLine)
                            .nestFont(.caption)
                            .foregroundStyle(Color(NestColor.textSecondary))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                cap("Week", value: page.limits.weeklyCap, id: "swift.limits.week") { cap in
                    Task { await page.setWeeklyCap(cap) }
                }
                cap("Five hours", value: page.limits.fiveHourCap, id: "swift.limits.five") { cap in
                    Task { await page.setFiveHourCap(cap) }
                }
                SwiftSection("\(page.project.name)'s share of Swift's week") {
                    HStack(spacing: NestSpace.s3) {
                        Slider(value: Binding(get: { page.project.share ?? 1 },
                                              set: { page.setShare($0 >= 1 ? nil : SwiftPageModel.step($0)) }),
                               in: 0.1...1)
                            .tint(Color(NestColor.clay))
                            .accessibilityIdentifier("swift.limits.share")
                        Text(page.project.share.map { "\(Int(($0 * 100).rounded()))%" } ?? "Any")
                            .nestFont(.label)
                            .monospacedDigit()
                            .foregroundStyle(Color(NestColor.textPrimary))
                            .frame(minWidth: NestSpace.s7, alignment: .trailing)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.limits")
    }

    private func cap(_ title: String, value: Double, id: String, set: @escaping (Double) -> Void) -> some View {
        SwiftSection("\(title) · Swift stops at") {
            HStack(spacing: NestSpace.s3) {
                Slider(value: Binding(get: { value }, set: { set(SwiftPageModel.step($0)) }), in: 0.05...1)
                    .tint(Color(NestColor.clay))
                    .accessibilityIdentifier(id)
                Text("\(Int((value * 100).rounded()))%")
                    .nestFont(.label)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textPrimary))
                    .frame(minWidth: NestSpace.s7, alignment: .trailing)
            }
        }
    }
}
