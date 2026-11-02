package com.example.a_core.gastos

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
 * Widget de inicio que muestra el resumen semanal de ingresos y gastos.
 *
 * Los datos los escribe la app Flutter (vía el paquete home_widget) en las
 * SharedPreferences "HomeWidgetPreferences", clave [KEY_RESUMEN].
 */
class GastosWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) actualizar(context, appWidgetManager, id)
    }

    companion object {
        const val PREFS = "HomeWidgetPreferences"
        const val KEY_RESUMEN = "gastos_resumen"

        fun actualizar(context: Context, awm: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

            var ingresos = 0.0
            var gastos = 0.0
            prefs.getString(KEY_RESUMEN, null)?.let { raw ->
                try {
                    val j = JSONObject(raw)
                    ingresos = j.optDouble("ingresos", 0.0)
                    gastos = j.optDouble("gastos", 0.0)
                } catch (_: Exception) {
                }
            }
            val balance = ingresos - gastos

            val views = RemoteViews(context.packageName, R.layout.gastos_widget)
            views.setTextViewText(R.id.gw_ingresos, formato(ingresos))
            views.setTextViewText(R.id.gw_gastos, formato(gastos))
            views.setTextViewText(R.id.gw_balance, formato(balance))
            views.setTextColor(
                R.id.gw_balance,
                if (balance >= 0) 0xFF2E9E6B.toInt() else 0xFFE05252.toInt(),
            )

            val agregar = Intent(context, GastosQuickAddActivity::class.java)
            val agregarPi = PendingIntent.getActivity(
                context,
                1,
                agregar,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.gw_add, agregarPi)

            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { abrir ->
                val abrirPi = PendingIntent.getActivity(
                    context,
                    2,
                    abrir,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.gw_body, abrirPi)
            }

            awm.updateAppWidget(widgetId, views)
        }

        fun actualizarTodos(context: Context) {
            val awm = AppWidgetManager.getInstance(context)
            val ids = awm.getAppWidgetIds(
                ComponentName(context, GastosWidgetProvider::class.java)
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
