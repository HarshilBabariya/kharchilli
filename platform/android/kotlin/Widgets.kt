package app.gharcha

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * The home-screen widgets. Each one is a layout filled with the text the Flutter side last saved (Store.saveForNative);
 * a view a layout does not have is simply skipped. All of them redraw when the app broadcasts REFRESH to any one of
 * them. Buttons open the app with the extra the quick_actions plugin reads, so they follow the launcher-shortcut routes.
 */
abstract class GharchaWidget(private val layout: String, private val rootRoute: String? = null) : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != REFRESH) return
        val manager = AppWidgetManager.getInstance(context)
        for (widget in listOf(SpendWidget(), QuickWidget(), TodayWidget(), BillsWidget(), ShoppingWidget())) {
            widget.onUpdate(context, manager, manager.getAppWidgetIds(ComponentName(context, widget.javaClass)))
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        if (ids.isEmpty()) return
        fun res(type: String, name: String) = context.resources.getIdentifier(name, type, context.packageName)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, res("layout", layout))
        for (line in TEXTS) {
            prefs.getString("flutter.widget_$line", null)?.let { views.setTextViewText(res("id", "widget_$line"), it) }
        }
        prefs.getString("flutter.widget_progress", null)?.toIntOrNull()?.let { views.setProgressBar(res("id", "widget_progress"), 100, it, false) }
        views.setOnClickPendingIntent(res("id", "widget_root"), open(context, rootRoute))
        for (route in ROUTES) {
            views.setOnClickPendingIntent(res("id", "widget_go_$route"), open(context, route))
        }
        manager.updateAppWidget(ids, views)
    }

    private fun open(context: Context, route: String?): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
        if (route != null) {
            intent.setAction(Intent.ACTION_RUN).putExtra(SHORTCUT, route).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        return PendingIntent.getActivity(context, route.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    companion object {
        const val REFRESH = "app.gharcha.WIDGET_REFRESH"
        const val SHORTCUT = "some unique action key"
        val TEXTS = listOf("title", "amount", "note", "left", "today_title", "today_amount", "today_note", "bills_title", "bill_1", "bill_2", "bill_3", "label_add", "label_voice", "label_reminders", "label_shopping", "shop_title", "shop_note") + (1..8).map { "shop_$it" }
        val ROUTES = listOf("add", "voice", "reminders", "shopping")
    }
}

class SpendWidget : GharchaWidget("widget_spend")

class QuickWidget : GharchaWidget("widget_quick")

class TodayWidget : GharchaWidget("widget_today")

class BillsWidget : GharchaWidget("widget_bills", "reminders")

class ShoppingWidget : GharchaWidget("widget_shopping", "shopping")
