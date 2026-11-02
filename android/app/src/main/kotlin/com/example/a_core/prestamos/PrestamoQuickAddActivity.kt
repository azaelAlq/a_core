package com.example.a_core.prestamos

import android.app.Activity
import android.app.DatePickerDialog
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import com.example.a_core.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Formulario flotante de nuevo préstamo que se abre desde el widget.
 *
 * Encola el préstamo en las SharedPreferences "HomeWidgetPreferences"
 * (clave [KEY_PENDING]); la app Flutter lo sube a Firestore al abrirse.
 * Los campos coinciden con la hoja "Nuevo préstamo" de Finanzas.
 */
class PrestamoQuickAddActivity : Activity() {

    private var fechaVencimiento: Long? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_prestamo_quick_add)

        val btnVence = findViewById<Button>(R.id.pa_vence)
        val btnVenceLimpiar = findViewById<Button>(R.id.pa_vence_limpiar)
        val deudor = findViewById<EditText>(R.id.pa_deudor)
        val monto = findViewById<EditText>(R.id.pa_monto)
        val contacto = findViewById<EditText>(R.id.pa_contacto)
        val concepto = findViewById<EditText>(R.id.pa_concepto)

        btnVence.setOnClickListener { mostrarPicker(btnVence) }
        btnVenceLimpiar.setOnClickListener {
            fechaVencimiento = null
            btnVence.text = getString(R.string.prestamos_qa_vence_hint)
        }

        findViewById<Button>(R.id.pa_guardar).setOnClickListener {
            val d = deudor.text.toString().trim()
            val m = monto.text.toString().toDoubleOrNull()
            if (d.isEmpty() || m == null || m <= 0) {
                Toast.makeText(this, getString(R.string.prestamos_qa_error), Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            guardarPendiente(
                deudor = d,
                monto = m,
                contacto = contacto.text.toString().trim(),
                concepto = concepto.text.toString().trim(),
            )
            Toast.makeText(this, getString(R.string.prestamos_qa_guardado), Toast.LENGTH_SHORT).show()
            PrestamosWidgetProvider.actualizarTodos(this)
            finish()
        }
    }

    private fun mostrarPicker(btnVence: Button) {
        val cal = Calendar.getInstance()
        fechaVencimiento?.let { cal.timeInMillis = it }
        DatePickerDialog(
            this,
            { _, year, month, day ->
                val elegida = Calendar.getInstance().apply {
                    set(Calendar.YEAR, year)
                    set(Calendar.MONTH, month)
                    set(Calendar.DAY_OF_MONTH, day)
                }
                fechaVencimiento = elegida.timeInMillis
                btnVence.text = "$day/${month + 1}/$year"
            },
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH),
            cal.get(Calendar.DAY_OF_MONTH),
        ).show()
    }

    private fun guardarPendiente(
        deudor: String,
        monto: Double,
        contacto: String,
        concepto: String,
    ) {
        val prefs = getSharedPreferences(PrestamosWidgetProvider.PREFS, MODE_PRIVATE)
        val raw = prefs.getString(KEY_PENDING, null)
        val arr = try {
            if (raw != null) JSONArray(raw) else JSONArray()
        } catch (_: Exception) {
            JSONArray()
        }
        val entry = JSONObject()
            .put("deudor", deudor)
            .put("monto", monto)
            .put("fecha", System.currentTimeMillis())
        if (contacto.isNotEmpty()) entry.put("contacto", contacto)
        if (concepto.isNotEmpty()) entry.put("concepto", concepto)
        fechaVencimiento?.let { entry.put("fechaVencimiento", it) }
        arr.put(entry)
        prefs.edit().putString(KEY_PENDING, arr.toString()).apply()
        actualizarResumenOptimista(prefs, monto)
    }

    /**
     * Suma el préstamo al resumen del widget para que el cambio se vea de
     * inmediato. La app recalcula los totales reales al abrirse.
     */
    private fun actualizarResumenOptimista(prefs: android.content.SharedPreferences, monto: Double) {
        var porCobrar = 0.0
        var activos = 0
        prefs.getString(PrestamosWidgetProvider.KEY_RESUMEN, null)?.let { raw ->
            try {
                val j = JSONObject(raw)
                porCobrar = j.optDouble("porCobrar", 0.0)
                activos = j.optInt("activos", 0)
            } catch (_: Exception) {
            }
        }
        prefs.edit()
            .putString(
                PrestamosWidgetProvider.KEY_RESUMEN,
                JSONObject()
                    .put("porCobrar", porCobrar + monto)
                    .put("activos", activos + 1)
                    .toString(),
            )
            .apply()
    }

    companion object {
        const val KEY_PENDING = "prestamos_pending"
    }
}
