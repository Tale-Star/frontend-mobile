package com.startale.startale_mobile

import android.app.Activity
import android.content.Context
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.view.View
import com.google.ar.core.Anchor
import com.google.ar.core.Camera
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.HitResult
import com.google.ar.core.InstantPlacementPoint
import com.google.ar.core.Plane
import com.google.ar.core.Session
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * PlatformView nativo de Android que aloja una GLSurfaceView con sesión real de ARCore.
 * Renderiza el feed de cámara mediante [BackgroundRenderer] con Display Geometry sincronizado
 * a través de [DisplayRotationHelper], rastrea superficies planas horizontales e implementa
 * hit-testing continuo en tiempo real con soporte completo para Instant Placement y anclaje 3D.
 */
class ArCorePlatformView(
    private val context: Context,
    private val activity: Activity,
    private val id: Int,
    creationParams: Map<String?, Any?>?,
    private val messenger: BinaryMessenger,
    private val channel: MethodChannel,
    private val onDisposed: ((ArCorePlatformView) -> Unit)? = null
) : PlatformView, GLSurfaceView.Renderer {

    private val glSurfaceView: GLSurfaceView = GLSurfaceView(context)
    private val backgroundRenderer = BackgroundRenderer()
    private val displayRotationHelper = DisplayRotationHelper(activity)
    private var session: Session? = null
    private var isSessionConfigured = false
    private var currentAnchor: Anchor? = null
    private var lastPlanesEmitTime = 0L
    private var eventsSentCount = 0L

    var viewportWidth: Int = 1080
        private set
    var viewportHeight: Int = 2400
        private set

    private var latestHitResult: HitResult? = null
    private var latestFrame: Frame? = null

    private val viewMatrix = FloatArray(16)
    private val projMatrix = FloatArray(16)
    private val vpMatrix = FloatArray(16)

    init {
        glSurfaceView.preserveEGLContextOnPause = true
        glSurfaceView.setEGLContextClientVersion(2)
        glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0)
        glSurfaceView.setRenderer(this)
        glSurfaceView.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
    }

    override fun getView(): View {
        return glSurfaceView
    }

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0.1f, 0.1f, 0.1f, 1.0f)
        backgroundRenderer.createOnGlThread()

        try {
            if (session == null) {
                session = Session(activity)
                val arConfig = Config(session)

                // 1. Detección completa de planos horizontales y verticales para enriquecer el mapa SLAM
                arConfig.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL

                // 2. Enfoque automático continuo para nitidez en superficies cercanas (mesas, suelos)
                try {
                    arConfig.focusMode = Config.FocusMode.AUTO
                } catch (e: Exception) {
                    // Fallback transparente si el hardware no soporta FocusMode.AUTO
                }

                // 3. Estimación de iluminación y modo de actualización inmediata
                arConfig.lightEstimationMode = Config.LightEstimationMode.AMBIENT_INTENSITY
                arConfig.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE

                // 4. Habilitación de Instant Placement como acelerador de colocación inmediata
                try {
                    arConfig.instantPlacementMode = Config.InstantPlacementMode.LOCAL_Y_UP
                } catch (e: Exception) {
                    // Fallback transparente si no está soportado en la versión de Play Services
                }

                session?.configure(arConfig)
            }
            session?.setCameraTextureName(backgroundRenderer.textureId)
            displayRotationHelper.onResume()
            session?.resume()
            isSessionConfigured = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        viewportWidth = width
        viewportHeight = height
        displayRotationHelper.onSurfaceChanged(width, height)
        GLES20.glViewport(0, 0, width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        val currentSession = session ?: return
        if (!isSessionConfigured) return

        // Sincroniza la rotación y dimensiones del viewport con ARCore antes de actualizar el frame
        displayRotationHelper.updateSessionIfNeeded(currentSession)

        try {
            val frame: Frame = currentSession.update()
            latestFrame = frame
            val camera: Camera = frame.camera
            val frameTimestamp = frame.timestamp

            // Dibuja el feed de cámara real en orientación vertical corregida
            backgroundRenderer.draw(frame)

            val trackingState = camera.trackingState
            val trackingFailureReason = if (trackingState != TrackingState.TRACKING) {
                try {
                    camera.trackingFailureReason.name
                } catch (e: Exception) {
                    "UNKNOWN"
                }
            } else {
                "NONE"
            }

            // 1. Consulta y auditoría exhaustiva de planos rastreados por ARCore
            val allPlanes = currentSession.getAllTrackables(Plane::class.java)
            var subsumedCount = 0
            var nonHorizontalCount = 0
            var pausedCount = 0
            val validPlanes = mutableListOf<Plane>()

            for (plane in allPlanes) {
                if (plane.subsumedBy != null) {
                    subsumedCount++
                    continue
                }
                if (plane.type != Plane.Type.HORIZONTAL_UPWARD_FACING) {
                    nonHorizontalCount++
                    continue
                }
                if (plane.trackingState != TrackingState.TRACKING) {
                    pausedCount++
                    continue
                }
                validPlanes.add(plane)
            }

            val planeDiscardReason = when {
                allPlanes.isEmpty() -> "ARCore aún buscando superficies en el entorno"
                validPlanes.isNotEmpty() -> "Ninguno ($validPlanes.size planos horizontales válidos)"
                nonHorizontalCount > 0 && pausedCount == 0 -> "$nonHorizontalCount planos detectados son verticales (apunta al suelo/mesa)"
                pausedCount > 0 -> "$pausedCount planos pausados temporalmente por movimiento"
                subsumedCount > 0 -> "$subsumedCount planos fusionados/subsumidos"
                else -> "Planos no cumplen criterios de orientación horizontal superior"
            }

            // 2. Hit-testing en tiempo real en el centro de la pantalla (retícula)
            val centerX = viewportWidth / 2.0f
            val centerY = viewportHeight / 2.0f

            // A. Intentar raycast estándar contra planos detectados
            val standardHits = try {
                frame.hitTest(centerX, centerY)
            } catch (e: Exception) {
                emptyList<HitResult>()
            }

            var bestHit: HitResult? = null
            var hitType = "NONE"
            var hitDistance = 0.0

            // Prioridad 1: Plano horizontal confirmado con la pose dentro del polígono delimitador
            for (hit in standardHits) {
                val trackable = hit.trackable
                if (trackable is Plane &&
                    trackable.type == Plane.Type.HORIZONTAL_UPWARD_FACING &&
                    trackable.trackingState == TrackingState.TRACKING &&
                    trackable.isPoseInPolygon(hit.hitPose)
                ) {
                    bestHit = hit
                    hitType = "CONFIRMED_PLANE"
                    hitDistance = hit.distance.toDouble()
                    break
                }
            }

            // Prioridad 2: Plano horizontal dentro de los límites de extensión
            if (bestHit == null) {
                for (hit in standardHits) {
                    val trackable = hit.trackable
                    if (trackable is Plane &&
                        trackable.type == Plane.Type.HORIZONTAL_UPWARD_FACING &&
                        trackable.trackingState == TrackingState.TRACKING &&
                        trackable.isPoseInExtents(hit.hitPose)
                    ) {
                        bestHit = hit
                        hitType = "PLANE_EXTENT"
                        hitDistance = hit.distance.toDouble()
                        break
                    }
                }
            }

            // Prioridad 3: HitTest con Instant Placement contra profundidad estimada / nube de puntos
            if (bestHit == null) {
                try {
                    val instantHits = frame.hitTestInstantPlacement(centerX, centerY, 1.5f)
                    for (hit in instantHits) {
                        val trackable = hit.trackable
                        if (trackable is InstantPlacementPoint &&
                            trackable.trackingState == TrackingState.TRACKING
                        ) {
                            bestHit = hit
                            hitType = "INSTANT_PLACEMENT"
                            hitDistance = hit.distance.toDouble()
                            break
                        }
                    }
                } catch (e: Throwable) {
                    // Instant placement no disponible en este hardware o versión
                }
            }

            latestHitResult = bestHit

            // 3. Cálculo de proyección espacial del Anchor colocado hacia coordenadas de pantalla Flutter
            var anchorScreenX = 0.0
            var anchorScreenY = 0.0
            var anchorNormX = 0.5
            var anchorNormY = 0.5
            var anchorDistance = 0.0
            var anchorYaw = 0.0
            var anchorPitch = 0.0
            var isAnchorTracking = false
            var isAnchorInView = false

            val anchor = currentAnchor
            if (anchor != null && anchor.trackingState == TrackingState.TRACKING) {
                isAnchorTracking = true
                camera.getViewMatrix(viewMatrix, 0)
                camera.getProjectionMatrix(projMatrix, 0, 0.1f, 100.0f)
                Matrix.multiplyMM(vpMatrix, 0, projMatrix, 0, viewMatrix, 0)

                val anchorPose = anchor.pose
                val worldPos = floatArrayOf(anchorPose.tx(), anchorPose.ty(), anchorPose.tz(), 1.0f)
                val clipPos = FloatArray(4)
                Matrix.multiplyMV(clipPos, 0, vpMatrix, 0, worldPos, 0)

                if (clipPos[3] > 0.05f) { // Delante del plano near
                    val ndcX = clipPos[0] / clipPos[3]
                    val ndcY = clipPos[1] / clipPos[3]
                    anchorNormX = (ndcX + 1.0) * 0.5
                    anchorNormY = (1.0 - ndcY) * 0.5
                    anchorScreenX = anchorNormX * viewportWidth
                    anchorScreenY = anchorNormY * viewportHeight
                    anchorDistance = clipPos[3].toDouble()
                    isAnchorInView = (ndcX in -1.2f..1.2f) && (ndcY in -1.2f..1.2f)
                }

                // Cálculo de perspectiva angular cámara <-> anclaje en el espacio físico
                try {
                    val cameraPose = camera.pose
                    val relPose = cameraPose.inverse().compose(anchorPose)
                    val relX = relPose.tx().toDouble()
                    val relY = relPose.ty().toDouble()
                    val relZ = relPose.tz().toDouble()
                    anchorYaw = Math.atan2(relX, -relZ)
                    anchorPitch = Math.atan2(relY, -relZ)
                } catch (e: Exception) {
                    anchorYaw = 0.0
                    anchorPitch = 0.0
                }
            }

            // 4. Emisión throttled a Flutter (~120ms) de telemetría completa de diagnóstico y planos
            val now = System.currentTimeMillis()
            if (now - lastPlanesEmitTime > 120) {
                lastPlanesEmitTime = now
                eventsSentCount++

                val planesData = validPlanes.map { plane ->
                    val pose = plane.centerPose
                    mapOf(
                        "id" to plane.hashCode().toString(),
                        "type" to "horizontalUpward",
                        "extentX" to plane.extentX.toDouble(),
                        "extentZ" to plane.extentZ.toDouble(),
                        "centerPoseX" to pose.tx().toDouble(),
                        "centerPoseY" to pose.ty().toDouble(),
                        "centerPoseZ" to pose.tz().toDouble()
                    )
                }

                val statusData = mapOf(
                    "sessionState" to "ACTIVE",
                    "cameraTrackingState" to trackingState.name,
                    "trackingFailureReason" to trackingFailureReason,
                    "frameTimestampNs" to frameTimestamp,
                    "eventsSentCount" to eventsSentCount,
                    "knownPlanesCount" to allPlanes.size,
                    "validPlanesCount" to validPlanes.size,
                    "nonHorizontalPlanesCount" to nonHorizontalCount,
                    "pausedPlanesCount" to pausedCount,
                    "subsumedPlanesCount" to subsumedCount,
                    "planeDiscardReason" to planeDiscardReason,
                    "hasValidPlacementPoint" to (bestHit != null),
                    "hasHitAtReticle" to (bestHit != null),
                    "placementPointType" to hitType,
                    "hitDistanceMeters" to hitDistance,
                    "anchorScreenX" to anchorScreenX,
                    "anchorScreenY" to anchorScreenY,
                    "anchorNormX" to anchorNormX,
                    "anchorNormY" to anchorNormY,
                    "anchorDistance" to anchorDistance,
                    "anchorYaw" to anchorYaw,
                    "anchorPitch" to anchorPitch,
                    "isAnchorTracking" to isAnchorTracking,
                    "isAnchorInView" to isAnchorInView,
                    "viewportWidth" to viewportWidth.toDouble(),
                    "viewportHeight" to viewportHeight.toDouble()
                )

                activity.runOnUiThread {
                    channel.invokeMethod("onPlanesUpdated", planesData)
                    channel.invokeMethod("onArStatusUpdated", statusData)
                }
            }
        } catch (e: Exception) {
            // Tolerar frames transitorios durante inicialización o rotación
        }
    }

    /**
     * Ancla virtualmente el cuento utilizando la pose exacta validada bajo la retícula central.
     */
    fun placeStoryAnchor(planeId: String?): Boolean {
        val currentSession = session ?: return false
        val frame = latestFrame ?: return false
        try {
            // Prioridad 1: Utilizar la pose exacta validada por la retícula central (HitResult)
            val hit = latestHitResult
            if (hit != null) {
                currentAnchor?.detach()
                currentAnchor = hit.createAnchor()
                return true
            }

            // Prioridad 2: Si el usuario presionó el botón y la retícula no tenía un hit en ese frame exacto,
            // realizar un raycast en el centro en este instante
            val centerX = viewportWidth / 2.0f
            val centerY = viewportHeight / 2.0f
            val fallbackHits = try {
                frame.hitTest(centerX, centerY)
            } catch (e: Exception) {
                emptyList<HitResult>()
            }

            for (fallbackHit in fallbackHits) {
                val trackable = fallbackHit.trackable
                if (trackable is Plane && trackable.type == Plane.Type.HORIZONTAL_UPWARD_FACING) {
                    currentAnchor?.detach()
                    currentAnchor = fallbackHit.createAnchor()
                    return true
                }
            }

            // Prioridad 3: Intentar hit instantáneo en el centro
            try {
                val instantHits = frame.hitTestInstantPlacement(centerX, centerY, 1.5f)
                if (instantHits.isNotEmpty()) {
                    currentAnchor?.detach()
                    currentAnchor = instantHits[0].createAnchor()
                    return true
                }
            } catch (e: Throwable) {
                // Ignore
            }

            // Prioridad 4: Plano horizontal detectado
            val planes = currentSession.getAllTrackables(Plane::class.java)
            val validPlanes = planes.filter {
                it.trackingState == TrackingState.TRACKING &&
                it.subsumedBy == null &&
                it.type == Plane.Type.HORIZONTAL_UPWARD_FACING
            }

            val targetPlane = if (!planeId.isNullOrEmpty()) {
                validPlanes.find { it.hashCode().toString() == planeId } ?: validPlanes.firstOrNull()
            } else {
                validPlanes.firstOrNull()
            }

            if (targetPlane != null) {
                currentAnchor?.detach()
                currentAnchor = targetPlane.createAnchor(targetPlane.centerPose)
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    /**
     * Ancla virtualmente el cuento en las coordenadas de pantalla tocadas por el usuario (Tap-to-place).
     * [normX] y [normY] son coordenadas normalizadas (0.0 a 1.0) respecto a la vista.
     */
    fun placeStoryAtScreenCoordinates(normX: Float, normY: Float): Boolean {
        val frame = latestFrame ?: return false
        try {
            // Conversión segura de coordenadas normalizadas a píxeles nativos del viewport
            val screenX = if (normX in 0.0f..1.0f) normX * viewportWidth else normX
            val screenY = if (normY in 0.0f..1.0f) normY * viewportHeight else normY

            // 1. Raycast estándar contra planos detectados
            val standardHits = try {
                frame.hitTest(screenX, screenY)
            } catch (e: Exception) {
                emptyList<HitResult>()
            }

            for (hit in standardHits) {
                val trackable = hit.trackable
                if (trackable is Plane &&
                    trackable.type == Plane.Type.HORIZONTAL_UPWARD_FACING &&
                    trackable.trackingState == TrackingState.TRACKING
                ) {
                    currentAnchor?.detach()
                    currentAnchor = hit.createAnchor()
                    return true
                }
            }

            // 2. Instant placement en las coordenadas tocadas
            try {
                val instantHits = frame.hitTestInstantPlacement(screenX, screenY, 1.5f)
                for (hit in instantHits) {
                    val trackable = hit.trackable
                    if (trackable is InstantPlacementPoint &&
                        trackable.trackingState == TrackingState.TRACKING
                    ) {
                        currentAnchor?.detach()
                        currentAnchor = hit.createAnchor()
                        return true
                    }
                }
            } catch (e: Throwable) {
                // Instant placement no disponible
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    fun resumeSession() {
        try {
            displayRotationHelper.onResume()
            session?.resume()
            glSurfaceView.onResume()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun pauseSession() {
        try {
            displayRotationHelper.onPause()
            glSurfaceView.onPause()
            session?.pause()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun dispose() {
        try {
            displayRotationHelper.onPause()
            currentAnchor?.detach()
            currentAnchor = null
            latestHitResult = null
            latestFrame = null
            glSurfaceView.onPause()
            session?.pause()
            session?.close()
            session = null
            isSessionConfigured = false
            onDisposed?.invoke(this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
