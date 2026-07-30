import SwiftUI
import WidgetKit

private let widgetGroupId = "group.app.nestly.family"

struct NestlyEntry: TimelineEntry {
  let date: Date
  let nestName: String
  let openTasks: Int
  let nextEvent: String
  let dinner: String
  let hasNest: Bool
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> NestlyEntry {
    NestlyEntry(
      date: Date(),
      nestName: "Nestly",
      openTasks: 3,
      nextEvent: "Soccer · Tue · 4:00 PM",
      dinner: "Pasta night",
      hasNest: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (NestlyEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = loadEntry()
    // Refresh periodically even if the app is closed.
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> NestlyEntry {
    let defaults = UserDefaults(suiteName: widgetGroupId)
    let hasNest = defaults?.bool(forKey: "has_nest") ?? false
    let openTasks = defaults?.integer(forKey: "open_tasks") ?? 0
    let nextEvent = defaults?.string(forKey: "next_event") ?? ""
    let dinner = defaults?.string(forKey: "dinner") ?? ""
    let nestName = defaults?.string(forKey: "nest_name") ?? "Nestly"
    return NestlyEntry(
      date: Date(),
      nestName: nestName.isEmpty ? "Nestly" : nestName,
      openTasks: openTasks,
      nextEvent: nextEvent,
      dinner: dinner,
      hasNest: hasNest
    )
  }
}

struct NestlyHomeWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    content
      .widgetURL(URL(string: "nestly://home"))
  }

  @ViewBuilder
  private var content: some View {
    if !entry.hasNest {
      VStack(alignment: .leading, spacing: 6) {
        Text("Nestly")
          .font(.headline.weight(.bold))
        Text("Open Nestly to see today’s nest snapshot.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(4)
    } else {
      VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
        HStack {
          Text(entry.nestName)
            .font(.headline.weight(.bold))
            .lineLimit(1)
          Spacer(minLength: 4)
          Text("\(entry.openTasks)")
            .font(.title2.weight(.bold))
            .monospacedDigit()
        }
        Text(entry.openTasks == 1 ? "open task" : "open tasks")
          .font(.caption)
          .foregroundStyle(.secondary)

        if family != .systemSmall {
          Divider().opacity(0.35)
          row(label: "Next", value: entry.nextEvent.isEmpty ? "Nothing scheduled" : entry.nextEvent)
          row(label: "Dinner", value: entry.dinner.isEmpty ? "Not planned" : entry.dinner)
        } else {
          Text(entry.nextEvent.isEmpty ? "No upcoming events" : entry.nextEvent)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(4)
    }
  }

  private func row(label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label.uppercased())
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.subheadline.weight(.medium))
        .lineLimit(2)
    }
  }
}

@main
struct NestlyHomeWidget: Widget {
  let kind: String = "NestlyHomeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOSApplicationExtension 17.0, *) {
        NestlyHomeWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        NestlyHomeWidgetEntryView(entry: entry)
          .padding()
          .background(Color(.systemBackground))
      }
    }
    .configurationDisplayName("Nestly Today")
    .description("Open tasks, next event, and tonight’s dinner — no vault data.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
