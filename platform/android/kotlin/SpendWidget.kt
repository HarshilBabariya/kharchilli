package app.gharcha

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home-screen widget. It shows the three lines the Flutter side last saved (Store.saveWidget) and redraws when the app
 * broadcasts REFRESH. Its buttons open the app with the extra the quick_actions plugin reads, so they follow the same
 * routes as the launcher shortcuts.
 */
class SpendWidget : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != REFRESH) return
        val manager = AppWidgetManager.getInstance(context)
        onUpdate(context, manager, manager.getAppWidgetIds(ComponentName(context, SpendWidget::class.java)))
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        fun res(type: String, name: String) = context.resources.getIdentifier(name, type, context.packageName)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, res("layout", "spend_widget"))
        for (line in listOf("title", "amount", "note")) {
            prefs.getString("flutter.widget_$line", null)?.let { views.setTextViewText(res("id", "widget_$line"), it) }
        }
        views.setOnClickPendingIntent(res("id", "widget_root"), open(context, null))
        views.setOnClickPendingIntent(res("id", "widget_add"), open(context, "add"))
        views.setOnClickPendingIntent(res("id", "widget_voice"), open(context, "voice"))
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
    }
}
