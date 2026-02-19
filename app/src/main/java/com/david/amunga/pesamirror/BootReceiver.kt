package com.david.amunga.pesamirror

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = SecurePrefs.get(context)

        // Restart the SMS trigger foreground service if it was enabled.
        if (prefs.getBoolean(MainActivity.KEY_SMS_TRIGGER_ENABLED, false)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(Intent(context, SmsTriggerService::class.java))
            } else {
                context.startService(Intent(context, SmsTriggerService::class.java))
            }
        }

        // Remote Push (FCM) does not need a boot-time service start.
        // PesaMirrorMessagingService is woken by the Firebase system whenever
        // an FCM data message arrives, even after a reboot.
    }
}
