package com.example.a_core.prestamos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.a_core.R
import org.json.JSONObject
import java.text.DecimalFormat

/**
 * Widget de inicio que muestra el total por cobrar de préstamos activos.
 *
 * Los datos los escribe la app Flutter (vía el paquete home_widget) en las
 * SharedPreferences "HomeWidgetPreferences", clave [KEY_RESUMEN].
 */
class PrestamosWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) actualizar(context, appWidgetManager, id)
    }

    companion object {
        const val PREFS = "HomeWidgetPreferences"
        const val KEY_RESUMEN = "prestamos_resumen"

        fun actualizar(context: Context, awm: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

            var porCobrar = 0.0
            var activos = 0
            prefs.getString(KEY_RESUMEN, null)?.let { raw ->
                try {
                    val j = JSONObject(raw)
                    porCobrar = j.optDouble("porCobrar", 0.0)
                    activos = j.optInt("activos", 0)
                } catch (_: Exception) {
                }
            }

            val views = RemoteViews(context.packageName, R.layout.prestamos_widget)
            views.setTextViewText(R.id.pw_total, formato(porCobrar))
            views.setTextViewText(
                R.id.pw_activos,
                context.resources.getQuantityString(R.plurals.prestamos_widget_activos, activos, activos),
            )

            val agregar = Intent(context, PrestamoQuickAddActivity::class.java)
            val agregarPi = PendingIntent.getActivity(
                context,
                3,
                agregar,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.pw_add, agregarPi)

            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { abrir ->
                val abrirPi = PendingIntent.getActivity(
                    context,
                    4,
                    abrir,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.pw_body, abrirPi)
            }

            awm.updateAppWidget(widgetId, views)
        }

        fun actualizarTodos(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val ids = awm.getAppWidgetIds(
                ComponentName(context, PrestamosWidgetProvider::class.java)
            )
            for (id in ids) actualizar(context, awm, id)
        }

        private fun formato(valor: Double): String {
            val abs = kotlin.math.abs(valor)
            val numero = DecimalFormat("#,##0.00").format(abs)
            return (if (valor < 0) "-" else "") + "$" + numero
        }
    }
}
