package org.sailings.app

object Config {
    /**
     * Where the Rails app lives.
     *
     * - Emulator against a local server: "http://10.0.2.2:3000". The emulator's
     *   own "localhost" is the emulated device, not your Mac — 10.0.2.2 is the
     *   special alias for the host loopback.
     * - Physical device against a local server: your Mac's LAN IP, e.g.
     *   "http://192.168.1.42:3000", with the server started as
     *   `bin/rails server -b 0.0.0.0`. Both local cases rely on the cleartext
     *   exception in res/xml/network_security_config.xml, since Android blocks
     *   plain HTTP otherwise.
     * - Production: the HTTPS host, which needs no exception at all.
     */
    const val BASE_URL = "https://staging.firstsoftware.cc"

    const val API_ROOT = "$BASE_URL/api/v1"
}
