package com.example.pin

import android.content.Context
import android.content.Intent
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

class PinWearableListenerService : WearableListenerService() {

    companion object {
        var onAuthResponseCallback: ((String) -> Unit)? = null
        var lastPendingWatchNodeId: String? = null
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            "/pin/auth_request" -> {
                // Received on companion phone from watch
                val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val cachedUser = prefs.getString("flutter.firebase_cached_user", null)

                if (!cachedUser.isNullOrEmpty()) {
                    // Phone already has active login session -> reply immediately to watch
                    Wearable.getMessageClient(applicationContext).sendMessage(
                        messageEvent.sourceNodeId,
                        "/pin/auth_response",
                        cachedUser.toByteArray(Charsets.UTF_8)
                    )
                } else {
                    // Phone is not logged in -> launch Pin on phone to log in
                    lastPendingWatchNodeId = messageEvent.sourceNodeId
                    val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra("target_watch_node_id", messageEvent.sourceNodeId)
                    }
                    applicationContext.startActivity(launchIntent)
                }
            }
            "/pin/auth_response" -> {
                // Received on watch from phone
                val userData = String(messageEvent.data, Charsets.UTF_8)
                if (userData.isNotEmpty()) {
                    // Cache in FlutterSharedPreferences so it's persisted immediately
                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putString("flutter.firebase_cached_user", userData).apply()

                    // Dispatch to active Flutter engine
                    onAuthResponseCallback?.invoke(userData)
                }
            }
            else -> super.onMessageReceived(messageEvent)
        }
    }
}
