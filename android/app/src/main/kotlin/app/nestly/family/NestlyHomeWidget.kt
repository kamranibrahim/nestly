package app.nestly.family

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Nestly Today home-screen widget — privacy-safe snapshot from Flutter.
 * Reads the same SharedPreferences keys written by [NestHomeWidget] in Dart.
 */
class NestlyHomeWidget : HomeWidgetProvider() {

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: android.os.Bundle?,
  ) {
    onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val options = appWidgetManager.getAppWidgetOptions(widgetId)
      val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
      val isSmall = minWidth < 250

      val views =
          if (isSmall) {
            buildSmall(context, widgetData)
          } else {
            buildMedium(context, widgetData)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun buildSmall(context: Context, data: SharedPreferences): RemoteViews {
    val hasNest = data.getBoolean("has_nest", false)
    val nestName = data.getString("nest_name", null).orEmpty().ifEmpty { "Nestly" }
    val heroTitle =
        data.getString("hero_title", null).orEmpty().ifEmpty {
          if (!hasNest) "Open Nestly to join a nest" else "Quiet day · enjoy it"
        }
    val accent = data.getString("accent", null).orEmpty().ifEmpty { "mint" }
    val whisper =
        when {
          !hasNest -> "Welcome"
          data.getString("hero_kind", "") == "tasks" -> {
            val event = data.getString("event_label", null).orEmpty()
            if (event.isNotEmpty() && event != "Nothing scheduled") event else "Today"
          }
          else -> "Today"
        }

    return RemoteViews(context.packageName, R.layout.nestly_widget_small).apply {
      setInt(R.id.widget_root, "setBackgroundResource", backgroundForAccent(accent))
      setTextViewText(R.id.widget_nest_name, if (hasNest) nestName else "Nestly")
      setTextViewText(R.id.widget_hero, heroTitle)
      setTextViewText(R.id.widget_whisper, whisper)
      setInt(R.id.widget_accent_dot, "setBackgroundResource", dotForAccent(accent))

      val home =
          HomeWidgetLaunchIntent.getActivity(
              context,
              MainActivity::class.java,
              Uri.parse("nestly://home"),
          )
      setOnClickPendingIntent(R.id.widget_root, home)
    }
  }

  private fun buildMedium(context: Context, data: SharedPreferences): RemoteViews {
    val hasNest = data.getBoolean("has_nest", false)
    val nestName = data.getString("nest_name", null).orEmpty().ifEmpty { "Nestly" }
    val accent = data.getString("accent", null).orEmpty().ifEmpty { "mint" }
    val tasks =
        data.getString("tasks_label", null).orEmpty().ifEmpty {
          val n = data.getInt("open_tasks", 0)
          if (n <= 0) "All clear" else if (n == 1) "1 open" else "$n open"
        }
    val event =
        data.getString("event_label", null).orEmpty().ifEmpty {
          data.getString("next_event", null).orEmpty().ifEmpty { "Nothing scheduled" }
        }
    val dinner =
        data.getString("dinner_label", null).orEmpty().ifEmpty {
          data.getString("dinner", null).orEmpty().ifEmpty { "Not planned" }
        }
    val updatedRaw = data.getString("updated_at", null).orEmpty()

    return RemoteViews(context.packageName, R.layout.nestly_widget_medium).apply {
      setInt(R.id.widget_root, "setBackgroundResource", backgroundForAccent(accent))
      setTextViewText(R.id.widget_nest_name, if (hasNest) nestName else "Nestly")
      setTextViewText(R.id.widget_today_label, if (hasNest) "Today" else "Welcome")

      if (!hasNest) {
        setViewVisibility(R.id.widget_empty, View.VISIBLE)
        setViewVisibility(R.id.widget_rows, View.GONE)
        setViewVisibility(R.id.widget_updated, View.GONE)
        setTextViewText(R.id.widget_empty, "Open Nestly to join a nest")
        val home =
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("nestly://home"),
            )
        setOnClickPendingIntent(R.id.widget_root, home)
      } else {
        setViewVisibility(R.id.widget_empty, View.GONE)
        setViewVisibility(R.id.widget_rows, View.VISIBLE)
        setTextViewText(R.id.widget_tasks_value, tasks)
        setTextViewText(R.id.widget_event_value, event)
        setTextViewText(R.id.widget_dinner_value, dinner)

        if (updatedRaw.isNotEmpty()) {
          setViewVisibility(R.id.widget_updated, View.VISIBLE)
          setTextViewText(R.id.widget_updated, "Updated ${relativeAge(updatedRaw)}")
        } else {
          setViewVisibility(R.id.widget_updated, View.GONE)
        }

        setOnClickPendingIntent(
            R.id.widget_row_tasks,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("nestly://tasks"),
            ),
        )
        setOnClickPendingIntent(
            R.id.widget_row_event,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("nestly://calendar"),
            ),
        )
        setOnClickPendingIntent(
            R.id.widget_row_dinner,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("nestly://meals"),
            ),
        )
      }
    }
  }

  private fun backgroundForAccent(accent: String): Int =
      when (accent) {
        "lavender" -> R.drawable.nestly_widget_bg_lavender
        "teal" -> R.drawable.nestly_widget_bg_teal
        "peach" -> R.drawable.nestly_widget_bg_peach
        else -> R.drawable.nestly_widget_bg_mint
      }

  private fun dotForAccent(accent: String): Int =
      when (accent) {
        "lavender" -> R.drawable.nestly_dot_lavender
        "teal" -> R.drawable.nestly_dot_teal
        "peach" -> R.drawable.nestly_dot_peach
        else -> R.drawable.nestly_dot_mint
      }

  private fun relativeAge(iso: String): String {
    return try {
      val instant = parseUpdatedAt(iso) ?: return "earlier"
      val seconds =
          java.time.Duration.between(instant, java.time.Instant.now()).seconds.coerceAtLeast(0)
      when {
        seconds < 45 -> "just now"
        seconds < 3600 -> {
          val m = (seconds / 60).toInt()
          if (m == 1) "1m ago" else "${m}m ago"
        }
        seconds < 86400 -> {
          val h = (seconds / 3600).toInt()
          if (h == 1) "1h ago" else "${h}h ago"
        }
        else -> {
          val d = (seconds / 86400).toInt()
          when {
            d < 7 && d == 1 -> "1d ago"
            d < 7 -> "${d}d ago"
            else -> "earlier"
          }
        }
      }
    } catch (_: Exception) {
      "earlier"
    }
  }

  private fun parseUpdatedAt(iso: String): java.time.Instant? {
    val trimmed = iso.trim()
    if (trimmed.isEmpty()) return null
    return try {
      java.time.Instant.parse(trimmed)
    } catch (_: Exception) {
      try {
        java.time.OffsetDateTime.parse(trimmed).toInstant()
      } catch (_: Exception) {
        try {
          java.time.LocalDateTime.parse(trimmed)
              .atZone(java.time.ZoneId.systemDefault())
              .toInstant()
        } catch (_: Exception) {
          null
        }
      }
    }
  }
}
