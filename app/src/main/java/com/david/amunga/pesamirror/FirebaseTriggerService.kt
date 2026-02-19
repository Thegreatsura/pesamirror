package com.david.amunga.pesamirror

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat

/**
 * Short-lived foreground service that executes a single USSD trigger received
 * from PesaMirrorMessagingService via an Intent extra.
 *
 * A foreground service is required because background activity starts are
 * blocked on Android 10+. This service starts, dials *334#, and then stops
 * itself after a brief delay (enough for the phone app to take over).
 */
class FirebaseTriggerService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        val body = intent?.getStringExtra(EXTRA_BODY)?.trim()
        if (!body.isNullOrBlank()) {
            triggerUssdFromBody(body)
        } else {
            Log.w(TAG, "onStartCommand called with no body extra")
        }

        // Stop self after a short window — the USSD dial is synchronous so
        // the phone app is already in the foreground by the time we stop.
        Handler(Looper.getMainLooper()).postDelayed({ stopSelf() }, 3_000)
        return START_NOT_STICKY
    }

    private fun triggerUssdFromBody(body: String) {
        val prefs = SecurePrefs.get(this)
        val pin = prefs.getString(MainActivity.KEY_USSD_PIN, null)?.trim()
        if (pin.isNullOrBlank()) {
            Log.w(TAG, "No PIN set, cannot trigger USSD from FCM push")
            return
        }

        val parts = body.split("|").map { it.trim() }
        when {
            parts[0].equals("SM", ignoreCase = true) && parts.size >= 2 -> {
                val phone: String; val amount: String
                if (parts.size >= 3) { phone = parts[1]; amount = parts[2] }
                else { phone = ""; amount = parts[1] }
                if (amount.isNotBlank())
                    startUssd(prefs, pin, MainActivity.MODE_SEND_MONEY, amount, phone = phone)
            }
            parts.size >= 3 && parts[0].equals("PLB", ignoreCase = true) -> {
                val phone = parts.getOrNull(1).orEmpty()
                val amount = parts.getOrNull(2).orEmpty()
                if (phone.isNotBlank() && amount.isNotBlank())
                    startUssd(prefs, pin, MainActivity.MODE_POCHI, amount, phone = phone)
            }
            parts.size >= 3 && parts[0].equals("BG", ignoreCase = true) -> {
                val till = parts.getOrNull(1).orEmpty()
                val amount = parts.getOrNull(2).orEmpty()
                if (till.isNotBlank() && amount.isNotBlank())
                    startUssd(prefs, pin, MainActivity.MODE_TILL, amount, till = till)
            }
            parts.size >= 4 && parts[0].equals("PB", ignoreCase = true) -> {
                val business = parts.getOrNull(1).orEmpty()
                val amount = parts.getOrNull(2).orEmpty()
                val account = parts.getOrNull(3).orEmpty()
                if (business.isNotBlank() && amount.isNotBlank() && account.isNotBlank())
                    startUssd(prefs, pin, MainActivity.MODE_PAYBILL, amount, business = business, account = account)
            }
            parts.size >= 4 && parts[0].equals("WA", ignoreCase = true) -> {
                val agent = parts.getOrNull(1).orEmpty()
                val amount = parts.getOrNull(2).orEmpty()
                val store = parts.getOrNull(3).orEmpty()
                if (agent.isNotBlank() && amount.isNotBlank() && store.isNotBlank())
                    startUssd(prefs, pin, MainActivity.MODE_WITHDRAW, amount, agent = agent, store = store)
            }
            else -> Log.w(TAG, "Unrecognised FCM push body: $body")
        }
    }

    private fun startUssd(
        prefs: android.content.SharedPreferences,
        pin: String,
        mode: String,
        amount: String,
        phone: String = "",
        till: String = "",
        business: String = "",
        account: String = "",
        agent: String = "",
        store: String = ""
    ) {
        prefs.edit()
            .putBoolean(MainActivity.KEY_USSD_PENDING, true)
            .putString(MainActivity.KEY_USSD_STATE, "")
            .putString(MainActivity.KEY_USSD_MODE, mode)
            .putString(MainActivity.KEY_USSD_AMOUNT, amount)
            .putString(MainActivity.KEY_USSD_PIN, pin)
            .putString(MainActivity.KEY_USSD_PHONE, phone)
            .putString(MainActivity.KEY_USSD_TILL, till)
            .putString(MainActivity.KEY_USSD_BUSINESS, business)
            .putString(MainActivity.KEY_USSD_ACCOUNT, account)
            .putString(MainActivity.KEY_USSD_AGENT, agent)
            .putString(MainActivity.KEY_USSD_STORE, store)
            .apply()

        val uri = Uri.parse("tel:" + Uri.encode("*334#"))
        val callIntent = Intent(Intent.ACTION_CALL).setData(uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(callIntent)
            Toast.makeText(this, "Starting…", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            prefs.edit().putBoolean(MainActivity.KEY_USSD_PENDING, false).apply()
            Log.e(TAG, "Failed to start USSD from FCM trigger", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.push_trigger_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
        }
    }

    private fun buildNotification() =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.push_trigger_notification_title))
            .setContentText(getString(R.string.push_trigger_notification_text))
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(
                PendingIntent.getActivity(
                    this, 0, Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            .setOngoing(true)
            .setColor(getColor(R.color.primary_green))
            .setColorized(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

    companion object {
        private const val TAG = "FirebaseTriggerService"
        private const val CHANNEL_ID = "pesamirror_push_trigger"
        const val NOTIFICATION_ID = 9002
        const val EXTRA_BODY = "extra_body"
    }
}
