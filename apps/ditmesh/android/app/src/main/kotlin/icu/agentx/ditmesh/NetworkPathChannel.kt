package icu.agentx.ditmesh

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Reports the device's DEFAULT network path to Dart so the Tox session can be
 * re-bootstrapped after a Wi-Fi <-> cellular handover or an address change
 * (Dart side: lib/lifecycle/network_change_rebootstrapper.dart).
 *
 * Channel: `ditmesh/network_path` (EventChannel). Each event is
 * `{available: Boolean, identity: String?}`; `identity` combines the default
 * network's handle, its transports, its link addresses and whether Android has
 * validated Internet on it, so a new default network, a new address on the
 * same one and a captive-portal login (same network and addresses, validation
 * flips) all change it. Signal strength is deliberately NOT part of it:
 * `onCapabilitiesChanged` fires on every signal-strength step and such a burst
 * must stay one identity. Dart only compares identities for equality and
 * ignores the first snapshot.
 *
 * `available` means "a default network exists" (Android's notion), not
 * "validated Internet": behind a captive portal the path is available but
 * unvalidated. Dart still kicks on such a path (cheap, bounded) and kicks
 * again when validation arrives, because the identity changes then.
 *
 * Uses `registerDefaultNetworkCallback`, available since API 24, which is the
 * app's minSdk (`flutter.minSdkVersion` resolves to 24 on Flutter 3.41); there
 * is no older code path.
 */
class NetworkPathChannel(
    private val context: Context,
) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var generation = 0L
    private var channel: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var defaultNetwork: Network? = null
    private var capabilities: NetworkCapabilities? = null
    private var linkProperties: LinkProperties? = null
    private var lastSent: Pair<Boolean, String?>? = null

    fun register(binaryMessenger: BinaryMessenger) {
        dispose()
        channel = EventChannel(binaryMessenger, CHANNEL_NAME).also { it.setStreamHandler(this) }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink,
    ) {
        onCancel(null)
        val ticket = generation
        sink = events
        lastSent = null
        val cm = context.getSystemService(ConnectivityManager::class.java) ?: return
        val cb =
            object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) =
                    post(ticket) {
                        if (network != defaultNetwork) {
                            capabilities = null
                            linkProperties = null
                        }
                        defaultNetwork = network
                        emit()
                    }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) = post(ticket) {
                    if (network == defaultNetwork) {
                        capabilities = networkCapabilities
                        emit()
                    }
                }

                override fun onLinkPropertiesChanged(
                    network: Network,
                    lp: LinkProperties,
                ) = post(ticket) {
                    if (network == defaultNetwork) {
                        linkProperties = lp
                        emit()
                    }
                }

                override fun onLost(network: Network) =
                    post(ticket) {
                        if (network == defaultNetwork) {
                            defaultNetwork = null
                            capabilities = null
                            linkProperties = null
                            emit()
                        }
                    }
            }
        try {
            cm.registerDefaultNetworkCallback(cb)
            callback = cb
            // The callback delivers the current default network (if any)
            // right away; report "no network" when there is none so Dart gets
            // its first snapshot either way.
            if (cm.activeNetwork == null) post(ticket) { emit() }
        } catch (e: RuntimeException) {
            // SecurityException without ACCESS_NETWORK_STATE, or the per-app
            // callback limit: degrade to "no watcher" (resume refresh only).
            callback = null
        }
    }

    override fun onCancel(arguments: Any?) {
        generation++
        sink = null
        val cb = callback
        callback = null
        if (cb != null) {
            try {
                context.getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(cb)
            } catch (_: RuntimeException) {
            }
        }
        defaultNetwork = null
        capabilities = null
        linkProperties = null
        lastSent = null
    }

    /** Engine teardown need not deliver a Dart EventChannel cancel message. */
    fun dispose() {
        onCancel(null)
        channel?.setStreamHandler(null)
        channel = null
    }

    private fun post(ticket: Long, block: () -> Unit) {
        mainHandler.post {
            if (ticket == generation && sink != null) block()
        }
    }

    /**
     * `handle|transports|addresses|validation`. Only equality matters to Dart.
     * Nothing here reads the signal strength or any other capability that
     * changes without the path changing.
     */
    private fun identity(): String? {
        val network = defaultNetwork ?: return null
        val caps = capabilities
        val transports =
            caps?.let { c ->
                TRANSPORTS.filter { (id, _) -> c.hasTransport(id) }.joinToString("+") { it.second }
            } ?: "?"
        val addresses =
            linkProperties
                ?.linkAddresses
                ?.map { it.address.hostAddress ?: "" }
                ?.sorted()
                ?.joinToString(",") ?: ""
        // A captive portal keeps the network handle and addresses across the
        // login; the validation flip is the only observable change, and it is
        // the moment the earlier (portal-blocked) bootstrap needs repeating.
        val validation =
            if (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true) {
                "validated"
            } else {
                "unvalidated"
            }
        return "$network|$transports|$addresses|$validation"
    }

    private fun emit() {
        val events = sink ?: return
        val available = defaultNetwork != null
        // A new default network arrives as onAvailable, then its capabilities,
        // then its link properties. Report it once all three are known, so the
        // burst is ONE identity (otherwise the first snapshot after listening
        // would be followed by a spurious "change").
        if (available && (capabilities == null || linkProperties == null)) return
        val id = if (available) identity() else null
        val snapshot = Pair(available, id)
        if (snapshot == lastSent) return
        lastSent = snapshot
        events.success(mapOf("available" to available, "identity" to id))
    }

    companion object {
        const val CHANNEL_NAME = "ditmesh/network_path"

        private val TRANSPORTS =
            listOf(
                NetworkCapabilities.TRANSPORT_WIFI to "wifi",
                NetworkCapabilities.TRANSPORT_CELLULAR to "cellular",
                NetworkCapabilities.TRANSPORT_ETHERNET to "ethernet",
                NetworkCapabilities.TRANSPORT_VPN to "vpn",
                NetworkCapabilities.TRANSPORT_BLUETOOTH to "bluetooth",
            )
    }
}
