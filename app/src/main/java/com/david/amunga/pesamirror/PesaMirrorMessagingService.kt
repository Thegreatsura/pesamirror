package com.david.amunga.pesamirror

import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Receives Firebase Cloud Messaging data messages sent from the web app.
 * Stateless: FCM wakes this service even when the app is killed — no persistent
 * connection or foreground service required for message delivery.
 *
 * When a trigger arrives and the "Push Trigger" preference is enabled, this
 * service starts FirebaseTriggerService (a short-lived foreground service) to
 * dial the USSD code. A foreground service is needed because background
 * activity starts are blocked on Android 10+.
 */
class PesaMirrorMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        Log.d(TAG, "FCM token refreshed")
        SecurePrefs.get(this).edit().putString(MainActivity.KEY_FCM_TOKEN, token).apply()
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val prefs = SecurePrefs.get(this)
        if (!prefs.getBoolean(MainActivity.KEY_PUSH_TRIGGER_ENABLED, false)) {
            Log.d(TAG, "Push trigger disabled, ignoring FCM message")
            return
        }

        val body = remoteMessage.data["body"]?.trim()
        if (body.isNullOrBlank()) {
            Log.w(TAG, "FCM message has no 'body' data field")
            return
        }

        Log.d(TAG, "FCM trigger received: $body")

        val intent = Intent(this, FirebaseTriggerService::class.java)
            .putExtra(FirebaseTriggerService.EXTRA_BODY, body)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    companion object {
        private const val TAG = "PesaMirrorMsgSvc"
    }
}
