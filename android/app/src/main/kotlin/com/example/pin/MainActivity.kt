package com.example.pin

import android.content.Context
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pin/watch_auth"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register On-Device AI Channel (Gemini Nano via AICore)
        val onDeviceAiChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OnDeviceAiHandler.CHANNEL)
        onDeviceAiChannel.setMethodCallHandler(OnDeviceAiHandler(applicationContext))

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPhoneAuth" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val nodeClient = Wearable.getNodeClient(this@MainActivity)
                            val nodes = Tasks.await(nodeClient.connectedNodes)
                            if (nodes.isEmpty()) {
                                withContext(Dispatchers.Main) {
                                    result.success(mapOf("status" to "no_nodes", "message" to "No companion phone connected."))
                                }
                                return@launch
                            }

                            val messageClient = Wearable.getMessageClient(this@MainActivity)
                            for (node in nodes) {
                                Tasks.await(messageClient.sendMessage(node.id, "/pin/auth_request", ByteArray(0)))
                            }
                            withContext(Dispatchers.Main) {
                                result.success(mapOf("status" to "sent", "nodeCount" to nodes.size))
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ERROR", e.message, null)
                            }
                        }
                    }
                }
                "sendAuthToWatch" -> {
                    val userData = call.argument<String>("userData") ?: ""
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val nodeClient = Wearable.getNodeClient(this@MainActivity)
                            val nodes = Tasks.await(nodeClient.connectedNodes)
                            val messageClient = Wearable.getMessageClient(this@MainActivity)
                            for (node in nodes) {
                                Tasks.await(messageClient.sendMessage(node.id, "/pin/auth_response", userData.toByteArray(Charsets.UTF_8)))
                            }
                            withContext(Dispatchers.Main) {
                                result.success(mapOf("status" to "sent", "nodeCount" to nodes.size))
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ERROR", e.message, null)
                            }
                        }
                    }
                }
                "getCachedUser" -> {
                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val cachedUser = prefs.getString("flutter.firebase_cached_user", null)
                    result.success(cachedUser)
                }
                else -> result.notImplemented()
            }
        }

        // Forward auth response received from phone to Flutter engine
        PinWearableListenerService.onAuthResponseCallback = { userData ->
            runOnUiThread {
                methodChannel?.invokeMethod("onAuthReceived", userData)
            }
        }
    }

    override fun onDestroy() {
        PinWearableListenerService.onAuthResponseCallback = null
        super.onDestroy()
    }
}
