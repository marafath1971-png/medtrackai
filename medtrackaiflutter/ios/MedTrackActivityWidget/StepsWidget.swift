import WidgetKit
import SwiftUI

/// Home-screen and lock-screen steps widget: today's ring and count, plus the
/// walking partner's count when paired.
///
/// The widget does not query HealthKit. The app writes a snapshot into the
/// shared app group (AppDelegate, `syncSteps`) and reloads this timeline. A
/// snapshot from an earlier day is shown as "open to update", never as
/// today's number.
struct StepsEntry: TimelineEntry {
    let date: Date
    let enabled: Bool
    /// False once the snapshot is from a previous day.
    let fresh: Bool
    let steps: Int
    let goal: Int
    let streak: Int
    let partnerName: String
    /// -1 when there is no partner.
    let partnerSteps: Int
    let partnerGoal: Int

    var hasPartner: Bool { enabled && partnerSteps >= 0 }
    var progress: Double { goal > 0 ? min(1, Double(steps) / Double(goal)) : 0 }
    var partnerProgress: Double {
        partnerGoal > 0 ? min(1, Double(max(0, partnerSteps)) / Double(partnerGoal)) : 0
    }
    var partnerLabel: String { partnerName.isEmpty ? "Partner" : partnerName }

    static let sample = StepsEntry(
        date: Date(), enabled: true, fresh: true, steps: 6240, goal: 8000,
        streak: 4, partnerName: "Sam", partnerSteps: 5120, partnerGoal: 8000)

    func stale(at date: Date) -> StepsEntry {
        StepsEntry(
            date: date, enabled: enabled, fresh: false, steps: 0, goal: goal,
            streak: streak, partnerName: partnerName,
            partnerSteps: partnerSteps >= 0 ? 0 : -1, partnerGoal: partnerGoal)
    }
}

struct StepsProvider: TimelineProvider {
    private static let dayFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date = Date()) -> String { dayFormat.string(from: date) }

    func placeholder(in context: Context) -> StepsEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        completion(context.isPreview ? .sample : read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        let now = read()
        var entries = [now]
        // At midnight yesterday's count stops being true, so the timeline
        // carries a second entry that blanks it until the app syncs again.
        if now.fresh,
           let midnight = Calendar.current.nextDate(
               after: Date(), matching: DateComponents(hour: 0, minute: 0),
               matchingPolicy: .nextTime) {
            entries.append(now.stale(at: midnight))
        }
        completion(Timeline(entries: entries, policy: .never))
    }

    private func read() -> StepsEntry {
        let d = UserDefaults(suiteName: "group.com.medtrackai")
        let fresh = d?.string(forKey: "steps.day") == Self.dayKey()
        let partnerRaw = d?.object(forKey: "steps.partnerSteps") as? Int ?? -1
        let entry = StepsEntry(
            date: Date(),
            enabled: d?.bool(forKey: "steps.enabled") ?? false,
            fresh: true,
            steps: d?.integer(forKey: "steps.steps") ?? 0,
            goal: d?.integer(forKey: "steps.goal") ?? 0,
            streak: d?.integer(forKey: "steps.streak") ?? 0,
            partnerName: d?.string(forKey: "steps.partnerName") ?? "",
            partnerSteps: partnerRaw,
            partnerGoal: d?.integer(forKey: "steps.partnerGoal") ?? 0)
        return fresh ? entry : entry.stale(at: Date())
    }
}

private let navy = Color(red: 0x1A / 255, green: 0x22 / 255, blue: 0x38 / 255)
private let lime = Color(red: 0xB4 / 255, green: 0xE8 / 255, blue: 0x69 / 255)
private let partnerBlue = Color(red: 0x8A / 255, green: 0xB4 / 255, blue: 0xFF / 255)

private struct Ring: View {
    let progress: Double
    let color: Color
    let width: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: width)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct StepsWidgetEntryView: View {
    var entry: StepsEntry
    @Environment(\.widgetFamily) var family

    private var footer: String {
        if !entry.enabled { return "Open MedAI to turn on steps" }
        if !entry.fresh { return "Open MedAI to update" }
        if entry.hasPartner {
            return "\(entry.partnerLabel) · \(entry.partnerSteps.formatted(.number.grouping(.automatic)))"
        }
        if entry.streak > 1 { return "\(entry.streak)-day streak" }
        if entry.goal > entry.steps {
            return "\((entry.goal - entry.steps).formatted()) to go"
        }
        return "Goal reached"
    }

    private var count: String { entry.enabled ? entry.steps.formatted() : "–" }

    private var rings: some View {
        ZStack {
            Ring(progress: entry.progress, color: lime, width: entry.hasPartner ? 7 : 9)
            if entry.hasPartner {
                Ring(progress: entry.partnerProgress, color: partnerBlue, width: 7)
                    .padding(10)
            }
        }
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                Gauge(value: entry.progress) {
                    Image(systemName: "figure.walk")
                } currentValueLabel: {
                    Text(count).minimumScaleFactor(0.5)
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Label("\(count) steps", systemImage: "figure.walk")
                        .font(.headline)
                    ProgressView(value: entry.progress)
                    Text(footer).font(.caption).lineLimit(1)
                }
            case .systemMedium:
                HStack(spacing: 16) {
                    rings.frame(width: 108, height: 108)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Steps today")
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                        Text(count)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6).lineLimit(1)
                        if entry.enabled {
                            Text("of \(entry.goal.formatted())")
                                .font(.caption).foregroundColor(.white.opacity(0.7))
                        }
                        Text(footer)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(entry.hasPartner ? partnerBlue : lime)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                }
            default:
                VStack(spacing: 6) {
                    ZStack {
                        rings
                        VStack(spacing: 0) {
                            Text(count)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.6).lineLimit(1)
                            if entry.enabled {
                                Text("of \(entry.goal.formatted())")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, entry.hasPartner ? 26 : 18)
                    }
                    Text(footer)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }
        .containerBackground(for: .widget) { navy }
        // medai://steps is routed by LinkService to the steps screen.
        .widgetURL(URL(string: "medai://steps"))
    }
}

struct StepsWidget: Widget {
    static let kind = "StepsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: StepsProvider()) { entry in
            StepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MedAI Steps")
        .description("Today's steps, your goal, and your walking partner.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
