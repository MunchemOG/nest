import NestKit
import SwiftUI

/// Swift's week: the hours you usually work, learned from Claude Code; when Swift will run your scheduled work;
/// and the jobs themselves, each with when it runs next.
struct SwiftWeekPanel: View {
    let page: SwiftPageModel

    private static let days = ["M", "T", "W", "T", "F", "S", "S"]
    /// Calendar weekdays in the grid's order, Monday first.
    private static let weekdays = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s3) {
                VStack(alignment: .leading, spacing: NestSpace.s1) {
                    Text("Swift's week")
                        .nestFont(.title)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Text("Your hours, learned from everything you do on this Mac and in Claude Code. Swift works outside them once you've been idle a while.")
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textMuted))
                        .fixedSize(horizontal: false, vertical: true)
                }
                grid
                legend
                if page.jobs.isEmpty {
                    Text("Nothing scheduled. Use the clock in the composer to schedule a prompt.")
                        .nestFont(.bodyS)
                        .foregroundStyle(Color(NestColor.textSecondary))
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(page.jobs) { job in row(job) }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.week")
    }

    private var planned: Set<[Int]> {
        let calendar = Calendar.current
        let now = Date.now
        return Set(page.jobs.compactMap { job in
            guard let next = job.nextRun(after: now, pattern: page.pattern),
                  next.timeIntervalSince(now) < 7 * 86_400 else { return nil }
            return [calendar.component(.weekday, from: next), calendar.component(.hour, from: next)]
        })
    }

    private var grid: some View {
        let planned = planned
        let cell = NestSpace.s1 + NestSpace.s1 / 2
        return HStack(alignment: .top, spacing: NestSpace.s1 / 2) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(" ").nestFont(.caption)
                ForEach([0, 6, 12, 18], id: \.self) { hour in
                    Text(String(format: "%02d", hour))
                        .nestFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Color(NestColor.textMuted))
                        .frame(height: cell * 6 + NestSpace.s1 / 4 * 6, alignment: .top)
                }
            }
            ForEach(Array(Self.weekdays.enumerated()), id: \.offset) { index, weekday in
                VStack(spacing: NestSpace.s1 / 4) {
                    Text(Self.days[index])
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textMuted))
                    ForEach(0..<24, id: \.self) { hour in
                        RoundedRectangle(cornerRadius: NestSpace.s1 / 2)
                            .fill(Color(color(weekday: weekday, hour: hour, planned: planned)))
                            .frame(height: cell)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your usual hours and Swift's planned runs this week")
    }

    private func color(weekday: Int, hour: Int, planned: Set<[Int]>) -> NestColor {
        if planned.contains([weekday, hour]) { return Bird.swift.color }
        return page.pattern.isYours(weekday: weekday, hour: hour) ? .textMuted : .line
    }

    private var legend: some View {
        HStack(spacing: NestSpace.s3) {
            key(.textMuted, "You")
            key(Bird.swift.color, "Swift")
            key(.line, "Free")
        }
    }

    private func key(_ color: NestColor, _ title: String) -> some View {
        HStack(spacing: NestSpace.s1) {
            RoundedRectangle(cornerRadius: NestSpace.s1 / 2).fill(Color(color)).frame(width: NestSpace.s3, height: NestSpace.s3)
            Text(title).nestFont(.caption).foregroundStyle(Color(NestColor.textSecondary))
        }
    }

    private func row(_ job: SwiftJob) -> some View {
        HStack(alignment: .top, spacing: NestSpace.s3) {
            if let project = page.projects.first(where: { $0.id == job.project }) {
                SwiftProjectTileView(project: project, size: NestSpace.s6)
            }
            VStack(alignment: .leading, spacing: NestSpace.s1 / 2) {
                HStack {
                    Text(job.title)
                        .nestFont(.label)
                        .foregroundStyle(Color(NestColor.textPrimary))
                        .lineLimit(1)
                    Spacer(minLength: NestSpace.s2)
                    Text(page.whenLine(job))
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textSecondary))
                        .lineLimit(1)
                }
                Text(job.settings.label + (job.ultracode ? " · Ultracode" : "") + " · " + job.mode.name)
                    .nestFont(.caption)
                    .foregroundStyle(Color(job.ultracode ? NestColor.claySoft : NestColor.textMuted))
                if let outcome = job.outcome {
                    Text(outcome)
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textMuted))
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, NestSpace.s1)
        .contextMenu {
            Button("Remove", role: .destructive) { page.removeJob(job.id) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("swift.job.\(job.id)")
    }
}
