package com.startale.startale_mobile

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Fábrica de PlatformView para instanciar [ArCorePlatformView] en Flutter.
 */
class ArCorePlatformViewFactory(
    private val activity: Activity,
    private val messenger: BinaryMessenger,
    private val channel: MethodChannel,
    private val onViewCreated: (ArCorePlatformView) -> Unit,
    private val onViewDisposed: ((ArCorePlatformView) -> Unit)? = null
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String?, Any?>
        val view = ArCorePlatformView(
            context,
            activity,
            viewId,
            creationParams,
            messenger,
            channel,
            onDisposed = { onViewDisposed?.invoke(it) }
        )
        onViewCreated(view)
        return view
    }
}
