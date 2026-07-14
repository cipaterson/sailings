import Foundation

enum Config {
    /// Where the Rails app lives.
    ///
    /// - Simulator against a local server: "http://localhost:3000"
    /// - Physical device against a local server: your Mac's LAN IP, e.g.
    ///   "http://192.168.1.42:3000", with the server started as
    ///   `bin/rails server -b 0.0.0.0`. Both cases rely on the
    ///   NSAllowsLocalNetworking exception in Sailings-Info.plist, since App
    ///   Transport Security blocks plain HTTP otherwise.
    /// - Production: the HTTPS host, which needs no ATS exception at all.
    static let baseURL = "http://localhost:3000"

    static let apiRoot = baseURL + "/api/v1"
}
