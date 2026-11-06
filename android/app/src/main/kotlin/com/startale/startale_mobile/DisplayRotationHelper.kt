package com.startale.startale_mobile

import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.view.Display
import android.view.Surface
import android.view.WindowManager
import com.google.ar.core.Session

/**
 * Asistente oficial para gestionar la rotación del Display y sincronizar la geometría
 * de la vista con la sesión de Google ARCore conforme a la especificación de referencia.
 */
class DisplayRotationHelper(private val context: Context) : DisplayManager.DisplayListener {
    private var viewportChanged = false
    private var viewportWidth = 0
    private var viewportHeight = 0
    private val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    val rotation: Int
        get() {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.display?.rotation ?: windowManager.defaultDisplay.rotation
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.rotation
            }
        }

    fun onResume() {
        displayManager.registerDisplayListener(this, null)
    }

    fun onPause() {
        displayManager.unregisterDisplayListener(this)
    }

    fun onSurfaceChanged(width: Int, height: Int) {
        viewportWidth = width
        viewportHeight = height
        viewportChanged = true
    }

    fun updateSessionIfNeeded(session: Session) {
        if (viewportChanged) {
            val displayRotation = rotation
            session.setDisplayGeometry(displayRotation, viewportWidth, viewportHeight)
            viewportChanged = false
        }
    }

    override fun onDisplayAdded(displayId: Int) {}
    override fun onDisplayRemoved(displayId: Int) {}
    override fun onDisplayChanged(displayId: Int) {
        viewportChanged = true
    }
}

