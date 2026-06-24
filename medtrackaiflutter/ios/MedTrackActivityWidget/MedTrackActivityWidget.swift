import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, nextMedName: "Aspirin", nextMedTime: "08:00", mascotMood: "happy")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func getEntry() -> SimpleEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.medtrackai")
        let streak = sharedDefaults?.integer(forKey: "streak") ?? 0
        let nextMedName = sharedDefaults?.string(forKey: "nextMedName") ?? "All Done!"
        let nextMedTime = sharedDefaults?.string(forKey: "nextMedTime") ?? "--:--"
        let mascotMood = sharedDefaults?.string(forKey: "mascotMood") ?? "neutral"
        return SimpleEntry(date: Date(), streak: streak, nextMedName: nextMedName, nextMedTime: nextMedTime, mascotMood: mascotMood)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let nextMedName: String
    let nextMedTime: String
    let mascotMood: String
}

struct MedTrackActivityWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Text(getEmoji(for: entry.mascotMood))
                        .font(.system(size: 20))
                    Text("\(entry.streak)🔥")
                        .font(.system(size: 10, weight: .bold))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(getEmoji(for: entry.mascotMood) + " \(entry.streak) Day Streak")
                    .font(.headline)
                Text(entry.nextMedName)
                    .font(.subheadline)
                Text(entry.nextMedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        default:
            // systemSmall
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.05), Color(red: 0.1, green: 0.1, blue: 0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(getEmoji(for: entry.mascotMood))
                            .font(.title)
                        Spacer()
                        Text("\(entry.streak)🔥")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text("Up Next")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(entry.nextMedName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(entry.nextMedTime)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.0, green: 0.9, blue: 0.7)) // Neon green accent
                }
                .padding()
            }
        }
    }

    func getEmoji(for mood: String) -> String {
        switch mood {
        case "happy": return "🤖"
        case "sad": return "🥺"
        case "proud": return "😎"
        case "sleepy": return "😴"
        default: return "🤖"
        }
    }
}

struct MedTrackActivityWidget: Widget {
    let kind: String = "MedTrackActivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MedTrackActivityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MedAI Dashboard")
        .description("View your streak and next medication.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
