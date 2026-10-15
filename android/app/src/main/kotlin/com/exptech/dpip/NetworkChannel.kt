package com.exptech.dpip

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Streams which network the device's traffic currently leaves through, once
 * on listen and again each time that changes, so the realtime feeds can
 * replace connections bound to a network that is gone.
 *
 * Each event is an identity string: `none` with no default network, otherwise
 * `<transport>:<network handle>`. The handle is what makes it an identity —
 * it changes whenever the network does, Wi-Fi to a different Wi-Fi included,
 * which a transport type alone would miss. The Dart side only compares them.
 *
 * One system callback, so a channel rather than a connectivity package. The
 * default-network callback reports the network apps actually use (a validated
 * Wi-Fi beats cellular), not every interface that happens to be up, and it is
 * delivered on the main looper, where the event sink must be called.
 */
class NetworkChannel(context: Context) : EventChannel.StreamHandler {

    companion object {
        const val NAME = "com.exptech.dpip/network"
    }

    private val connectivity =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private var callback: ConnectivityManager.NetworkCallback? = null

    /**
     * The transport first seen for each network handle. A network's transport
     * never changes, but reading its capabilities from inside a callback can
     * race and come back null — and "other:7" then "wifi:7" would read as a
     * change of network, tearing down a healthy connection for nothing.
     * Remembering the first answer keeps one handle one identity.
     */
    private val transports = HashMap<Long, String>()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                sink?.success(identity(network))
            }

            // Whatever is the default *now*, not a hard "none": if the loss of
            // the old network is reported after its replacement came up, the
            // last word must still be the network actually in use. The lost
            // one itself can linger as "active" for a moment; that is none.
            override fun onLost(network: Network) {
                val active = connectivity.activeNetwork
                sink?.success(identity(if (active == network) null else active))
            }
        }
        try {
            events?.success(identity(connectivity.activeNetwork))
            connectivity.registerDefaultNetworkCallback(callback, main)
            this.callback = callback
        } catch (error: RuntimeException) {
            // SecurityException without ACCESS_NETWORK_STATE, or the per-app
            // callback quota. The feeds still fall back on their own silence
            // limit, so this is a degraded path, not a failure to start.
            events?.error("UNAVAILABLE", error.message, null)
        }
    }

    override fun onCancel(arguments: Any?) {
        callback?.let {
            try {
                connectivity.unregisterNetworkCallback(it)
            } catch (_: IllegalArgumentException) {
                // Never registered — nothing to undo.
            }
        }
        callback = null
        sink = null
    }

    private fun identity(network: Network?): String {
        if (network == null) return "none"
        val handle = network.networkHandle
        // A handle is never reused while the process lives; a long session
        // only ever needs the last few.
        if (transports.size > 16) transports.clear()
        val transport = transports.getOrPut(handle) {
            val caps = connectivity.getNetworkCapabilities(network)
            when {
                caps == null -> "other"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                else -> "other"
            }
        }
        return "$transport:$handle"
    }
}
