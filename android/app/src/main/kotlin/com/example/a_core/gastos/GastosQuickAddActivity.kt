package com.example.a_core.gastos

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import com.example.a_core.R
import org.json.JSONArray
import org.json.JSONObject

/**
 * Formulario flotante de registro rápido que se abre desde el widget.
 *
 * Captura nombre, cantidad y tipo, y encola el registro en las
 * SharedPreferences "HomeWidgetPreferences" (clave [KEY_PENDING]). La app
 * Flutter los sube a Firestore al abrirse, conservando la fecha capturada.
 */
class GastosQuickAddActivity : Activity() {

    private var tipo: String = TIPO_GASTO

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_gastos_quick_add)

        val btnGasto = findViewById<Button>(R.id.qa_gasto)
        val btnIngreso = findViewById<Button>(R.id.qa_ingreso)
        val nombre = findViewById<EditText>(R.id.qa_nombre)
        val cantidad = findViewById<EditText>(R.id.qa_cantidad)

        btnGasto.setOnClickListener {
            tipo = TIPO_GASTO
            pintarToggle(btnGasto, btnIngreso)
        }
        btnIngreso.setOnClickListener {
            tipo = TIPO_INGRESO
            pintarToggle(btnGasto, btnIngreso)
        }
        pintarToggle(btnGasto, btnIngreso)

        findViewById<Button>(R.id.qa_guardar).setOnClickListener {
            val n = nombre.text.toString().trim()
            val c = cantidad.text.toString().toDoubleOrNull()
            if (n.isEmpty() || c == null || c <= 0) {
                Toast.makeText(this, getString(R.string.gastos_qa_error), Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            guardarPendiente(n, c, tipo)
            Toast.makeText(this, getString(R.string.gastos_qa_guardado), Toast.LENGTH_SHORT).show()
            GastosWidgetProvider.actualizarTodos(this)
            finish()
        }
    }

    private fun pintarToggle(btnGasto: Button, btnIngreso: Button) {
        val res = resources
        when (tipo) {
            TIPO_GASTO -> {
                btnGasto.background = res.getDrawable(R.drawable.gastos_pill_gasto, null)
                btnGasto.setTextColor(0xFFFFFFFF.toInt())
                btnIngreso.background = res.getDrawable(R.drawable.gastos_pill_off, null)
                btnIngreso.setTextColor(0xFFB4B2A9.toInt())
            }
            else -> {
                btnIngreso.background = res.getDrawable(R.drawable.gastos_pill_ingreso, null)
                btnIngreso.setTextColor(0xFFFFFFFF.toInt())
                btnGasto.background = res.getDrawable(R.drawable.gastos_pill_off, null)
                btnGasto.setTextColor(0xFFB4B2A9.toInt())
            }
        }
    }

    private fun guardarPendiente(nombre: String, cantidad: Double, tipo: String) {
        val prefs = getSharedPreferences(GastosWidgetProvider.PREFS, MODE_PRIVATE)
        val raw = prefs.getString(KEY_PENDING, null)
        val arr = try {
            if (raw != null) JSONArray(raw) else JSONArray()
        } catch (_: Exception) {
            JSONArray()
        }
        arr.put(
            JSONObject()
                .put("nombre", nombre)
                .put("cantidad", cantidad)
                .put("tipo", tipo)
                .put("fecha", System.currentTimeMillis())
        )
        prefs.edit().putString(KEY_PENDING, arr.toString()).apply()
        actualizarResumenOptimista(prefs, cantidad, tipo)
    }

    /**
     * Suma el registro al resumen que muestra el widget para que el cambio
     * se vea de inmediato, sin esperar a que la app sincronice con Firestore.
     * La app recalcula los totales reales al abrirse y sobrescribe este valor.
     */
    private fun actualizarResumenOptimista(
        prefs: android.content.SharedPreferences,
        cantidad: Double,
        tipo: String,
    ) {
        var ingresos = 0.0
        var gastos = 0.0
        prefs.getString(GastosWidgetProvider.KEY_RESUMEN, null)?.let { raw ->
            try {
                val j = JSONObject(raw)
                ingresos = j.optDouble("ingresos", 0.0)
                gastos = j.optDouble("gastos", 0.0)
            } catch (_: Exception) {
            }
        }
        if (tipo == TIPO_INGRESO) ingresos += cantidad else gastos += cantidad
        prefs.edit()
            .putString(
                GastosWidgetProvider.KEY_RESUMEN,
                JSONObject()
                    .put("ingresos", ingresos)
                    .put("gastos", gastos)
                    .put("balance", ingresos - gastos)
                    .toString(),
            )
            .apply()
    }

    companion object {
        const val KEY_PENDING = "gastos_pending"
        const val TIPO_GASTO = "gasto"
        const val TIPO_INGRESO = "ingreso"
    }
}
