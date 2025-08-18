package dev.gab.tcc.tcc_3

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.Log
import io.flutter.plugin.common.EventChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        private const val TAG = "NotificationListener"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "Notification Listener Conectado")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let {
            val packageName = it.packageName
            val title = it.notification.extras?.getString("android.title")
            val text = it.notification.extras?.getCharSequence("android.text")?.toString()
            val postTime = it.postTime

            Log.i(TAG, "Notificação Postada: Pacote=$packageName, Título=$title, Texto=$text")

            if (eventSink == null) {
                Log.w(TAG, "eventSink é nulo. Não é possível enviar dados para o Flutter.")
                return
            }

            val data = HashMap<String, Any?>()
            data["packageName"] = packageName
            data["title"] = title
            data["text"] = text
            data["timestamp"] = postTime

            try {
                eventSink?.success(data)
                Log.i(TAG, "Dados da notificação enviados para o Flutter: $data")
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao enviar dados para o Flutter: ${e.message}")
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        sbn?.let {
            Log.i(TAG, "Notificação Removida: Pacote=${it.packageName}")
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.i(TAG, "Notification Listener Desconectado")
        try {
            eventSink?.success(mapOf("status" to "disconnected_service_side"))
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao enviar status de desconexão para o Flutter: ${e.message}")
        }
    }
}
