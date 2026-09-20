package com.example.pin

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.google.mlkit.genai.prompt.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.generateContentRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Handles On-Device Gemini Nano AI inference and capability checks via Android AICore
 * and Google ML Kit GenAI Prompt API for supported devices (Pixel 9+, Samsung flagships).
 */
class OnDeviceAiHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.example.pin/on_device_ai"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkCapability" -> checkCapability(result)
            "downloadModel" -> downloadModel(result)
            "generatePrompt" -> {
                val prompt = call.argument<String>("prompt") ?: ""
                generatePrompt(prompt, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkCapability(result: MethodChannel.Result) {
        val manufacturer = Build.MANUFACTURER ?: "Unknown"
        val model = Build.MODEL ?: "Unknown"
        val sdkInt = Build.VERSION.SDK_INT

        val isKnownGoogle = manufacturer.contains("Google", ignoreCase = true) &&
                (model.contains("Pixel 9", ignoreCase = true) || model.contains("Pixel 8 Pro", ignoreCase = true))

        val isKnownSamsung = manufacturer.contains("samsung", ignoreCase = true) &&
                (model.contains("SM-S92", ignoreCase = true) || // Galaxy S24 series
                 model.contains("SM-S93", ignoreCase = true) || // Galaxy S25 series
                 model.contains("SM-F95", ignoreCase = true) || // Galaxy Z Fold 6
                 model.contains("SM-F74", ignoreCase = true) || // Galaxy Z Flip 6
                 model.contains("Galaxy S24", ignoreCase = true) ||
                 model.contains("Galaxy S25", ignoreCase = true))

        val isKnownFlagship = isKnownGoogle || isKnownSamsung

        var isAiCoreInstalled = false
        try {
            context.packageManager.getPackageInfo("com.google.android.aicore", 0)
            isAiCoreInstalled = true
        } catch (_: PackageManager.NameNotFoundException) {
            isAiCoreInstalled = false
        }

        if (sdkInt < 26) {
            result.success(
                mapOf(
                    "isSupported" to false,
                    "status" to "unavailable",
                    "modelName" to "Gemini Nano",
                    "deviceModel" to model,
                    "manufacturer" to manufacturer,
                    "isKnownFlagship" to isKnownFlagship,
                    "isAiCoreInstalled" to isAiCoreInstalled,
                    "message" to "Requires Android 8.0 (API 26) or newer."
                )
            )
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val client = Generation.getClient()
                val featureStatus = client.checkStatus()

                val statusString = when (featureStatus) {
                    FeatureStatus.AVAILABLE -> "available"
                    FeatureStatus.DOWNLOADABLE -> "downloadable"
                    FeatureStatus.DOWNLOADING -> "downloading"
                    else -> "unavailable"
                }

                val isSupported = featureStatus == FeatureStatus.AVAILABLE ||
                        featureStatus == FeatureStatus.DOWNLOADABLE ||
                        featureStatus == FeatureStatus.DOWNLOADING

                val message = when (featureStatus) {
                    FeatureStatus.AVAILABLE -> "Gemini Nano is available and hardware accelerated."
                    FeatureStatus.DOWNLOADABLE -> "Gemini Nano is supported on this device and ready to download."
                    FeatureStatus.DOWNLOADING -> "Gemini Nano model download is currently in progress."
                    else -> if (isKnownFlagship) {
                        "Gemini Nano is supported by device hardware but AICore model is currently unavailable."
                    } else {
                        "Device does not support on-device Gemini Nano."
                    }
                }

                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "isSupported" to isSupported,
                            "status" to statusString,
                            "modelName" to "Gemini Nano",
                            "deviceModel" to model,
                            "manufacturer" to manufacturer,
                            "isKnownFlagship" to isKnownFlagship,
                            "isAiCoreInstalled" to isAiCoreInstalled,
                            "message" to message
                        )
                    )
                }
            } catch (t: Throwable) {
                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "isSupported" to false,
                            "status" to "unavailable",
                            "modelName" to "Gemini Nano",
                            "deviceModel" to model,
                            "manufacturer" to manufacturer,
                            "isKnownFlagship" to isKnownFlagship,
                            "isAiCoreInstalled" to isAiCoreInstalled,
                            "message" to (t.message ?: "AICore check failed.")
                        )
                    )
                }
            }
        }
    }

    private fun downloadModel(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val client = Generation.getClient()
                client.download()
                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (t: Throwable) {
                withContext(Dispatchers.Main) {
                    result.error("DOWNLOAD_ERROR", t.message ?: "Failed to initiate Gemini Nano download.", null)
                }
            }
        }
    }

    private fun generatePrompt(prompt: String, result: MethodChannel.Result) {
        if (prompt.trim().isEmpty()) {
            result.error("INVALID_PROMPT", "Prompt cannot be empty.", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val client = Generation.getClient()
                val response = client.generateContent(
                    generateContentRequest {
                        text(prompt)
                    }
                )
                val responseText = response.text ?: ""
                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "success" to true,
                            "text" to responseText,
                            "model" to "Gemini Nano"
                        )
                    )
                }
            } catch (t: Throwable) {
                withContext(Dispatchers.Main) {
                    result.error(
                        "INFERENCE_ERROR",
                        t.message ?: "On-device Gemini Nano inference failed.",
                        null
                    )
                }
            }
        }
    }
}
