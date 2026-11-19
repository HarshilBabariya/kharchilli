package app.gharcha

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.content.SharedPreferences
import android.provider.Telephony
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * Queues the text of SMS notifications that mention a currency amount, for the Flutter side to read on its next start
 * or resume (Store.takeCaptured). It writes straight into the shared_preferences file, so no Flutter engine is needed
 * while the app is closed. Nothing is read unless the user grants notification access.
 */
class PaymentListener : NotificationListenerService() {
    private val smsApps = setOf(
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        "com.android.mms",
        "com.android.messaging",
        "com.oneplus.mms",
        "com.motorola.messaging",
        "com.coloros.mms"
    )
    private val money = Regex("""(?:₹|\brs\.?|\binr)\s*[0-9]""", RegexOption.IGNORE_CASE)
    private val moved = Regex("""\b(debited|credited|spent|paid|sent|received|withdrawn|transferred)\b""", RegexOption.IGNORE_CASE)
    private val notPayment = Regex("""\b(otp|failed|declined|requested|offer|coupon)\b""", RegexOption.IGNORE_CASE)

    private fun prefs(): SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    override fun onListenerConnected() {
        prefs().edit().putBoolean(CONNECTED, true).apply()
    }

    override fun onListenerDisconnected() {
        prefs().edit().putBoolean(CONNECTED, false).apply()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (sbn.packageName !in smsApps && sbn.packageName != Telephony.Sms.getDefaultSmsPackage(this)) return
        if (sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val extras = sbn.notification.extras
        val sender = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (!money.containsMatchIn(text)) return
        val prefs = prefs()
        val queue = JSONArray(prefs.getString(QUEUE, null) ?: "[]")
        if (queue.length() >= MAX_QUEUED) return
        queue.put(JSONObject().put("sender", sender).put("text", text).put("at", sbn.postTime))
        prefs.edit().putString(QUEUE, queue.toString()).apply()
        if (moved.containsMatchIn(text) && !notPayment.containsMatchIn(text)) alert()
    }

    /** Tells the user a payment message is waiting; tapping it opens the app, where Home shows the capture banner. */
    private fun alert() {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "Payment capture", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val open = PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val icon = resources.getIdentifier("ic_stat_gharcha", "drawable", packageName)
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        manager.notify(ALERT_ID, builder
            .setSmallIcon(if (icon != 0) icon else applicationInfo.icon)
            .setContentTitle(prefs().getString(ALERT_TITLE, null) ?: "Payment spotted")
            .setContentText(prefs().getString(ALERT_BODY, null) ?: "Tap to add it to Gharcha")
            .setContentIntent(open)
            .setAutoCancel(true)
            .build())
    }

    private companion object {
        const val QUEUE = "flutter.capture_queue"
        const val CONNECTED = "flutter.capture_connected"
        const val MAX_QUEUED = 200
        const val CHANNEL = "capture"
        const val ALERT_ID = 930001
        const val ALERT_TITLE = "flutter.capture_alert_title"
        const val ALERT_BODY = "flutter.capture_alert_body"
    }
}
