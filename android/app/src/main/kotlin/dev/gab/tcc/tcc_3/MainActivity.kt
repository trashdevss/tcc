package dev.gab.tcc.tcc_3

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log

class MainActivity : FlutterActivity() {

    private val EVENT_CHANNEL_NAME = "jove_notification_event_channel"
    private val METHOD_CHANNEL_NAME = "dev.gab.tcc/notifications_utils"
    private val TAG = "MainActivity_TCC"

    // Nome completo da classe do serviço NotificationListenerService
    private val NOTIFICATION_LISTENER_SERVICE_CLASS_NAME = "dev.gab.tcc.tcc_3.NotificationListener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.i(TAG, "Configurando Flutter Engine, EventChannel e MethodChannel.")

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.i(TAG, "EventChannel: Flutter está ouvindo o canal $EVENT_CHANNEL_NAME.")
                    NotificationListener.eventSink = events // <- ligação feita aqui
                }

                override fun onCancel(arguments: Any?) {
                    Log.i(TAG, "EventChannel: Flutter parou de ouvir o canal $EVENT_CHANNEL_NAME.")
                    NotificationListener.eventSink = null // <- limpeza feita aqui
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationServiceEnabled" -> {
                        val isEnabled = isNotificationServiceEnabled(applicationContext)
                        Log.i(TAG, "Verificação do serviço de notificação: $isEnabled")
                        result.success(isEnabled)
                    }
                    "requestNotificationPermissionScreen" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.error(
                                    "NO_ACTIVITY_FOUND",
                                    "Não há uma Activity para abrir as configurações de notificações.",
                                    null
                                )
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao abrir configurações: ${e.message}", e)
                            result.error("ERROR_OPENING_SETTINGS", "Erro ao abrir configurações.", e.localizedMessage)
                        }
                    }
                    else -> {
                        Log.w(TAG, "Método '${call.method}' não implementado.")
                        result.notImplemented()
                    }
                }
            }
    }

    private fun isNotificationServiceEnabled(context: Context): Boolean {
        val componentName = ComponentName.unflattenFromString(
            "${context.packageName}/$NOTIFICATION_LISTENER_SERVICE_CLASS_NAME"
        )

        val enabledListeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        )

        if (!TextUtils.isEmpty(enabledListeners)) {
            val names = enabledListeners.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn == componentName) {
                    return true
                }
            }
        }
        return false
    }
}
