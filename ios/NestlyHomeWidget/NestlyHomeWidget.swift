import SwiftUI
import WidgetKit

private let widgetGroupId = "group.app.nestly.family"

// Casaio pastel tokens (match lib/theme/app_colors.dart)
private enum CasaioColor {
  static let ink = Color(red: 0.110, green: 0.110, blue: 0.118)
  static let inkSecondary = Color(red: 0.388, green: 0.388, blue: 0.400)
  static let inkMuted = Color(red: 0.557, green: 0.557, blue: 0.576)
  static let mint = Color(red: 0.831, green: 0.906, blue: 0.702)
  static let lavender = Color(red: 0.698, green: 0.698, blue: 0.902)
  static let teal = Color(red: 0.773, green: 0.910, blue: 0.878)
  static let peach = Color(red: 1.0, green: 0.847, blue: 0.659)
  static let wash = Color(red: 0.980, green: 0.980, blue: 0.984)
  static let surfaceMuted = Color(red: 0.969, green: 0.969, blue: 0.973)
}

struct CasaioEntry: TimelineEntry {
  let date: Date
  let nestName: String
  let openTasks: Int
  let nextEvent: String
  let dinner: String
  let hasNest: Bool
  let updatedAt: Date?
  let heroKind: String
  let heroTitle: String
  let tasksLabel: String
  let eventLabel: String
  let dinnerLabel: String
  let accent: String
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> CasaioEntry {
    CasaioEntry(
      date: Date(),
      nestName: "The Casaio Family",
      openTasks: 3,
      nextEvent: "Soccer · Tue · 4:00 PM",
      dinner: "Pasta night",
      hasNest: true,
      updatedAt: Date(),
      heroKind: "tasks",
      heroTitle: "3 open tasks",
      tasksLabel: "3 open",
      eventLabel: "Soccer · Tue · 4:00 PM",
      dinnerLabel: "Pasta night",
      accent: "lavender"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (CasaioEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = loadEntry()
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> CasaioEntry {
    let defaults = UserDefaults(suiteName: widgetGroupId)
    let hasNest = defaults?.bool(forKey: "has_nest") ?? false
    let openTasks = defaults?.integer(forKey: "open_tasks") ?? 0
    let nextEvent = defaults?.string(forKey: "next_event") ?? ""
    let dinner = defaults?.string(forKey: "dinner") ?? ""
    let nestName = defaults?.string(forKey: "nest_name") ?? "Casaio"
    let updatedRaw = defaults?.string(forKey: "updated_at") ?? ""
    let heroKind = defaults?.string(forKey: "hero_kind") ?? ""
    let heroTitle = defaults?.string(forKey: "hero_title") ?? ""
    let tasksLabel = defaults?.string(forKey: "tasks_label") ?? ""
    let eventLabel = defaults?.string(forKey: "event_label") ?? ""
    let dinnerLabel = defaults?.string(forKey: "dinner_label") ?? ""
    let accent = defaults?.string(forKey: "accent") ?? ""

    let resolvedHero = resolveHero(
      kind: heroKind,
      title: heroTitle,
      accent: accent,
      openTasks: openTasks,
      nextEvent: nextEvent,
      dinner: dinner,
      hasNest: hasNest
    )

    return CasaioEntry(
      date: Date(),
      nestName: nestName.isEmpty ? "Casaio" : nestName,
      openTasks: openTasks,
      nextEvent: nextEvent,
      dinner: dinner,
      hasNest: hasNest,
      updatedAt: Self.parseISO(updatedRaw),
      heroKind: resolvedHero.kind,
      heroTitle: resolvedHero.title,
      tasksLabel: tasksLabel.isEmpty
        ? (openTasks <= 0
          ? NSLocalizedString("All clear", comment: "")
          : String(format: NSLocalizedString("%d open", comment: ""), openTasks))
        : tasksLabel,
      eventLabel: eventLabel.isEmpty
        ? (nextEvent.isEmpty ? NSLocalizedString("Nothing scheduled", comment: "") : nextEvent)
        : eventLabel,
      dinnerLabel: dinnerLabel.isEmpty
        ? (dinner.isEmpty ? NSLocalizedString("Not planned", comment: "") : dinner)
        : dinnerLabel,
      accent: resolvedHero.accent
    )
  }

  private static func parseISO(_ raw: String) -> Date? {
    guard !raw.isEmpty else { return nil }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = formatter.date(from: raw) { return d }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: raw)
  }
}

private struct ResolvedHero {
  let kind: String
  let title: String
  let accent: String
}

private func resolveHero(
  kind: String,
  title: String,
  accent: String,
  openTasks: Int,
  nextEvent: String,
  dinner: String,
  hasNest: Bool
) -> ResolvedHero {
  if !hasNest {
    return ResolvedHero(
      kind: "quiet",
      title: title.isEmpty
        ? NSLocalizedString("Open Casaio to join a nest", comment: "")
        : title,
      accent: "mint"
    )
  }
  if !kind.isEmpty && !title.isEmpty {
    return ResolvedHero(
      kind: kind,
      title: title,
      accent: accent.isEmpty ? "mint" : accent
    )
  }
  // Fallback for older App Group payloads
  if openTasks > 0 {
    let label = openTasks == 1
      ? NSLocalizedString("1 open task", comment: "")
      : String(format: NSLocalizedString("%d open tasks", comment: ""), openTasks)
    return ResolvedHero(kind: "tasks", title: label, accent: "lavender")
  }
  if !nextEvent.isEmpty {
    return ResolvedHero(kind: "event", title: nextEvent, accent: "teal")
  }
  if !dinner.isEmpty {
    return ResolvedHero(kind: "dinner", title: dinner, accent: "peach")
  }
  return ResolvedHero(
    kind: "quiet",
    title: NSLocalizedString("Quiet day · enjoy it", comment: ""),
    accent: "mint"
  )
}

struct NestlyHomeWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      if family == .systemSmall {
        smallBody
          .widgetURL(URL(string: "casaio://home"))
      } else if entry.hasNest {
        mediumBody
      } else {
        mediumBody
          .widgetURL(URL(string: "casaio://home"))
      }
    }
  }

  private var accentColor: Color {
    switch entry.accent {
    case "lavender": return CasaioColor.lavender
    case "teal": return CasaioColor.teal
    case "peach": return CasaioColor.peach
    default: return CasaioColor.mint
    }
  }

  private var smallBody: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        Text(entry.hasNest ? entry.nestName : "Casaio")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(CasaioColor.ink)
          .lineLimit(1)
        Spacer(minLength: 4)
        Circle()
          .fill(accentColor)
          .frame(width: 10, height: 10)
      }

      Spacer(minLength: 0)

      Text(entry.heroTitle)
        .font(.title3.weight(.bold))
        .foregroundStyle(CasaioColor.ink)
        .lineLimit(3)
        .minimumScaleFactor(0.85)

      if entry.hasNest && entry.heroKind == "tasks" && !entry.eventLabel.isEmpty
          && entry.eventLabel != NSLocalizedString("Nothing scheduled", comment: "")
      {
        Text(entry.eventLabel)
          .font(.caption.weight(.semibold))
          .foregroundStyle(CasaioColor.inkSecondary)
          .lineLimit(2)
      } else if entry.hasNest && entry.heroKind != "quiet" {
        Text(NSLocalizedString("Today", comment: ""))
          .font(.caption.weight(.semibold))
          .foregroundStyle(CasaioColor.inkMuted)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(2)
  }

  private var mediumBody: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline) {
        Text(entry.hasNest ? entry.nestName : "Casaio")
          .font(.headline.weight(.bold))
          .foregroundStyle(CasaioColor.ink)
          .lineLimit(1)
        Spacer(minLength: 8)
        Text(entry.hasNest
          ? NSLocalizedString("Today", comment: "")
          : NSLocalizedString("Welcome", comment: ""))
          .font(.caption.weight(.bold))
          .foregroundStyle(CasaioColor.inkMuted)
      }

      if (!entry.hasNest) {
        Text(NSLocalizedString("Open Casaio to join a nest", comment: ""))
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(CasaioColor.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
      } else {
        VStack(spacing: 8) {
          linkRow(
            uri: "casaio://tasks",
            dot: CasaioColor.lavender,
            label: NSLocalizedString("Tasks", comment: ""),
            value: entry.tasksLabel
          )
          linkRow(
            uri: "casaio://calendar",
            dot: CasaioColor.teal,
            label: NSLocalizedString("Next", comment: ""),
            value: entry.eventLabel
          )
          linkRow(
            uri: "casaio://meals",
            dot: CasaioColor.mint,
            label: NSLocalizedString("Dinner", comment: ""),
            value: entry.dinnerLabel
          )
        }

        Spacer(minLength: 0)

        if let updated = entry.updatedAt {
          Text(String(format: NSLocalizedString("Updated %@", comment: ""), relativeAge(from: updated)))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(CasaioColor.inkMuted)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(2)
  }

  @ViewBuilder
  private func linkRow(uri: String, dot: Color, label: String, value: String) -> some View {
    let row = HStack(spacing: 10) {
      Circle()
        .fill(dot)
        .frame(width: 8, height: 8)
      Text(label)
        .font(.caption.weight(.bold))
        .foregroundStyle(CasaioColor.inkMuted)
        .frame(width: 48, alignment: .leading)
      Text(value)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(CasaioColor.ink)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 2)

    if #available(iOSApplicationExtension 14.0, *) {
      Link(destination: URL(string: uri)!) { row }
    } else {
      row
    }
  }

  private func relativeAge(from date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 45 { return NSLocalizedString("just now", comment: "") }
    let minutes = seconds / 60
    if minutes < 60 {
      return String(format: NSLocalizedString("%dm ago", comment: ""), minutes)
    }
    let hours = minutes / 60
    if hours < 24 {
      return String(format: NSLocalizedString("%dh ago", comment: ""), hours)
    }
    let days = hours / 24
    if days < 7 {
      return String(format: NSLocalizedString("%dd ago", comment: ""), days)
    }
    return NSLocalizedString("earlier", comment: "")
  }
}

@main
struct NestlyHomeWidget: Widget {
  let kind: String = "NestlyHomeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOSApplicationExtension 17.0, *) {
        NestlyHomeWidgetEntryView(entry: entry)
          .containerBackground(for: .widget) {
            widgetBackground(for: entry)
          }
      } else {
        NestlyHomeWidgetEntryView(entry: entry)
          .padding()
          .background(widgetBackground(for: entry))
      }
    }
    .configurationDisplayName(NSLocalizedString("Casaio Today", comment: ""))
    .description(NSLocalizedString("Open tasks, next event, and tonight’s dinner — no vault data.", comment: ""))
    .supportedFamilies([.systemSmall, .systemMedium])
  }

  @ViewBuilder
  private func widgetBackground(for entry: CasaioEntry) -> some View {
    let top: Color = {
      switch entry.accent {
      case "lavender": return CasaioColor.lavender.opacity(0.42)
      case "teal": return CasaioColor.teal.opacity(0.42)
      case "peach": return CasaioColor.peach.opacity(0.45)
      default: return CasaioColor.mint.opacity(0.48)
      }
    }()

    LinearGradient(
      colors: [top, CasaioColor.wash],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
