package com.startale.startale_mobile

import android.opengl.GLES11Ext
import android.opengl.GLES20
import com.google.ar.core.Coordinates2d
import com.google.ar.core.Frame
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * Renderizador OpenGL ES 2.0 para dibujar el feed de cámara de Google ARCore en pantalla.
 * Utiliza textura externa GL_TEXTURE_EXTERNAL_OES y transformación dinámica de coordenadas 2D
 * conforme a la implementación oficial de referencia de Google ARCore.
 */
class BackgroundRenderer {
    var textureId: Int = -1
        private set

    private var program: Int = 0
    private var positionAttrib: Int = 0
    private var texCoordAttrib: Int = 0
    private var textureUniform: Int = 0

    private val quadCoordsBuffer: FloatBuffer
    private val quadTexCoordsBuffer: FloatBuffer
    private var hasTransformedUvs: Boolean = false

    companion object {
        private const val COORDS_PER_VERTEX = 2
        private const val FLOAT_SIZE = 4

        private const val VERTEX_SHADER = """
            attribute vec4 a_Position;
            attribute vec2 a_TexCoord;
            varying vec2 v_TexCoord;
            void main() {
                gl_Position = a_Position;
                v_TexCoord = a_TexCoord;
            }
        """

        private const val FRAGMENT_SHADER = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            uniform samplerExternalOES u_Texture;
            varying vec2 v_TexCoord;
            void main() {
                gl_FragColor = texture2D(u_Texture, v_TexCoord);
            }
        """

        // Coordenadas normalizadas de dispositivo (NDC): 2 floats por vértice (x, y)
        // Vértices del quad en orden Triangle Strip (Google ARCore official spec):
        // 0: Abajo-izquierda, 1: Abajo-derecha, 2: Arriba-izquierda, 3: Arriba-derecha
        private val QUAD_COORDS = floatArrayOf(
            -1.0f, -1.0f,
            +1.0f, -1.0f,
            -1.0f, +1.0f,
            +1.0f, +1.0f
        )

        // Coordenadas UV iniciales de respaldo (0.0 a 1.0)
        private val QUAD_TEXCOORDS = floatArrayOf(
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f
        )
    }

    init {
        quadCoordsBuffer = ByteBuffer.allocateDirect(QUAD_COORDS.size * FLOAT_SIZE)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
        quadCoordsBuffer.put(QUAD_COORDS)
        quadCoordsBuffer.position(0)

        quadTexCoordsBuffer = ByteBuffer.allocateDirect(QUAD_TEXCOORDS.size * FLOAT_SIZE)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
        quadTexCoordsBuffer.put(QUAD_TEXCOORDS)
        quadTexCoordsBuffer.position(0)
    }

    fun createOnGlThread() {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)

        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, VERTEX_SHADER)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT_SHADER)

        program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)

        positionAttrib = GLES20.glGetAttribLocation(program, "a_Position")
        texCoordAttrib = GLES20.glGetAttribLocation(program, "a_TexCoord")
        textureUniform = GLES20.glGetUniformLocation(program, "u_Texture")
    }

    fun draw(frame: Frame) {
        if (textureId < 0 || program == 0) return

        // Transforma dinámicamente las coordenadas UV según la rotación de pantalla y relación de aspecto
        if (frame.hasDisplayGeometryChanged() || !hasTransformedUvs) {
            frame.transformCoordinates2d(
                Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES,
                quadCoordsBuffer,
                Coordinates2d.TEXTURE_NORMALIZED,
                quadTexCoordsBuffer
            )
            hasTransformedUvs = true
        }

        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)

        GLES20.glUseProgram(program)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniform1i(textureUniform, 0)

        quadCoordsBuffer.position(0)
        GLES20.glVertexAttribPointer(
            positionAttrib,
            COORDS_PER_VERTEX,
            GLES20.GL_FLOAT,
            false,
            0,
            quadCoordsBuffer
        )
        GLES20.glEnableVertexAttribArray(positionAttrib)

        quadTexCoordsBuffer.position(0)
        GLES20.glVertexAttribPointer(
            texCoordAttrib,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            quadTexCoordsBuffer
        )
        GLES20.glEnableVertexAttribArray(texCoordAttrib)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(positionAttrib)
        GLES20.glDisableVertexAttribArray(texCoordAttrib)

        GLES20.glDepthMask(true)
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
    }

    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)
        return shader
    }
}
