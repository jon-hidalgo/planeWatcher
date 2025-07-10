import SwiftUI
import Foundation
import CoreLocation

@main
struct PlaneWatcherMenuBarApp: App {
    @StateObject private var planeFetcher = PlaneFetcher()

    var body: some Scene {
        MenuBarExtra("✈️ Planes", systemImage: "airplane") {
            PlaneMenuView(planeFetcher: planeFetcher)
        }
        .menuBarExtraStyle(.window)
    }
}

struct PlaneMenuView: View {
    @ObservedObject var planeFetcher: PlaneFetcher
    @State private var isRefreshing = false
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            controlsSection
            Divider()
            planesSection
        }
        .padding()
        .frame(width: 350, height: 450)
        .onAppear {
            planeFetcher.startTimers()
        }
        .onReceive(planeFetcher.$isLoading) { loading in
            isRefreshing = loading
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Nearby Planes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    planeFetcher.manualRefresh()
                }) {
                    Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .disabled(planeFetcher.isLoading)
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("Next update in \(planeFetcher.secondsUntilNextPing)s")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(planeFetcher.currentLocationName) • 3km radius")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Settings") {
                    showSettings = true
                }
                .font(.caption)
                .buttonStyle(BorderlessButtonStyle())
                .popover(isPresented: $showSettings, arrowEdge: .trailing) {
                    SettingsPopoverView(settings: $planeFetcher.displaySettings)
                        .frame(width: 320, height: 400)
                        .padding()
                }
            }
            
            // Daily Statistics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Flights")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(planeFetcher.todaysFlightCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Divider()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Biggest Plane")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(planeFetcher.biggestPlaneToday ?? "None")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var planesSection: some View {
        ScrollView {
            if planeFetcher.isLoading {
                loadingView
            } else if planeFetcher.nearbyPlanes.isEmpty {
                emptyStateView
            } else {
                planesList
            }
        }
        .frame(maxHeight: 300)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading planes...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "airplane.departure")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("No planes nearby")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var planesList: some View {
        LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(planeFetcher.nearbyPlanes, id: \.id) { plane in
                PlaneRowView(plane: plane, planeFetcher: planeFetcher)
            }
        }
    }
}

struct PlaneRowView: View {
    let plane: Plane
    let planeFetcher: PlaneFetcher
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://globe.adsbexchange.com/?icao=\(plane.icao)") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "airplane")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(planeFetcher.getPlaneDescription(plane))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let route = plane.route {
                        Text(route)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.blue.opacity(0.1) : Color.clear)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isHovered = hovering
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Model
struct Plane: Identifiable, Codable {
    let id: String
    let callsign: String
    let altitude: Int
    let lat: Double
    let lon: Double
    let icao: String
    let route: String?
    let speed: Double?
    let distance: Double?
    let aircraftType: String?
    
    init(callsign: String, altitude: Int, lat: Double, lon: Double, icao: String, route: String?, speed: Double?, distance: Double?, aircraftType: String? = nil) {
        self.id = icao
        self.callsign = callsign
        self.altitude = altitude
        self.lat = lat
        self.lon = lon
        self.icao = icao
        self.route = route
        self.speed = speed
        self.distance = distance
        self.aircraftType = aircraftType
    }
}

struct DisplaySettings: Codable {
    var showCallsign = true
    var showRoute = true
    var showAltitude = true
    var showSpeed = true
    var showDistance = true
    var showAircraftType = true
    var openSkyUsername = ""
    var openSkyPassword = ""
    var clientId = ""
    var clientSecret = ""
    var useBasicAuth = false
    var useBearerToken = false
}

// MARK: - OpenSky Aircraft Metadata Models
struct AircraftMetadata: Codable {
    let registration: String?
    let manufacturerName: String?
    let manufacturerIcao: String?
    let model: String?
    let typecode: String?
    let aircraftOperator: String?
    let operatorCallsign: String?
    let operatorIcao: String?
    let country: String?
    let icao24: String?
    let built: String?
}

// MARK: - OpenSky API Response Models
struct OpenSkyResponse: Codable {
    let states: [[OpenSkyStateValue]]?
}

enum OpenSkyStateValue: Codable {
    case string(String)
    case double(Double)
    case int(Int)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            self = .null
        }
    }
    
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    var doubleValue: Double? {
        if case .double(let value) = self { return value }
        if case .int(let value) = self { return Double(value) }
        return nil
    }
}

// MARK: - Settings Popover View
struct SettingsPopoverView: View {
    @Binding var settings: DisplaySettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Display Settings Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Options")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Show callsign", isOn: $settings.showCallsign)
                Toggle("Show aircraft type", isOn: $settings.showAircraftType)
                Toggle("Show route", isOn: $settings.showRoute)
                Toggle("Show altitude", isOn: $settings.showAltitude)
                Toggle("Show speed", isOn: $settings.showSpeed)
                Toggle("Show distance", isOn: $settings.showDistance)
            }
            .font(.system(size: 12))
            
            Divider()
            
            // Authentication Section
            VStack(alignment: .leading, spacing: 8) {
                Text("OpenSky Authentication")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Avoid rate limits with OpenSky credentials")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 6) {
                    Toggle("Basic Auth (Username/Password)", isOn: $settings.useBasicAuth)
                        .font(.caption)
                    
                    if settings.useBasicAuth {
                        VStack(spacing: 4) {
                            TextField("OpenSky Username", text: $settings.openSkyUsername)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                            
                            SecureField("OpenSky Password", text: $settings.openSkyPassword)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                        }
                    }
                    
                    Toggle("Bearer Token (OAuth2)", isOn: $settings.useBearerToken)
                        .font(.caption)
                    
                    if settings.useBearerToken {
                        VStack(spacing: 4) {
                            TextField("Client ID", text: $settings.clientId)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                            
                            SecureField("Client Secret", text: $settings.clientSecret)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                        }
                    }
                }
                
                if !settings.useBasicAuth && !settings.useBearerToken {
                    Text("Anonymous: ~400 requests/day")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Authenticated: ~10,000 requests/day")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Fetcher
class PlaneFetcher: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var nearbyPlanes: [Plane] = []
    @Published var secondsUntilNextPing: Int = 60
    @Published var displaySettings = DisplaySettings() {
        didSet {
            saveSettings()
        }
    }
    @Published var isLoading: Bool = false
    @Published var todaysFlightCount: Int = 0
    @Published var biggestPlaneToday: String? = nil
    @Published var currentLocationName: String = "Getting location..."

    private let selectedRadius: Double = 3.0
    private var myLat: Double = 40.417
    private var myLon: Double = -3.704
    private var timer: Timer?
    private var countdownTimer: Timer?
    private let locationManager = CLLocationManager()
    private var accessToken: String?
    private var tokenExpiry: Date?
    private var seenICAOsToday: Set<String> = []
    private var lastResetDate: String = ""
    private var aircraftCache: [String: AircraftMetadata] = [:]

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        loadSettings()
        loadDailyStats()
        currentLocationName = "Madrid"
        requestUserLocation()
        startTimers()
    }

    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(displaySettings) {
            UserDefaults.standard.set(encoded, forKey: "displaySettings")
        }
    }

    func loadSettings() {
        if let saved = UserDefaults.standard.data(forKey: "displaySettings"),
           let decoded = try? JSONDecoder().decode(DisplaySettings.self, from: saved) {
            self.displaySettings = decoded
        }
    }
    
    func loadDailyStats() {
        let today = getCurrentDateString()
        lastResetDate = UserDefaults.standard.string(forKey: "lastResetDate") ?? ""
        
        if lastResetDate != today {
            seenICAOsToday = []
            todaysFlightCount = 0
            biggestPlaneToday = nil
            lastResetDate = today
            UserDefaults.standard.set(today, forKey: "lastResetDate")
        } else {
            todaysFlightCount = UserDefaults.standard.integer(forKey: "todaysFlightCount")
            biggestPlaneToday = UserDefaults.standard.string(forKey: "biggestPlaneToday")
            if let seenData = UserDefaults.standard.data(forKey: "seenICAOsToday"),
               let seenSet = try? JSONDecoder().decode(Set<String>.self, from: seenData) {
                seenICAOsToday = seenSet
            }
        }
    }
    
    func saveDailyStats() {
        UserDefaults.standard.set(todaysFlightCount, forKey: "todaysFlightCount")
        UserDefaults.standard.set(biggestPlaneToday, forKey: "biggestPlaneToday")
        if let seenData = try? JSONEncoder().encode(seenICAOsToday) {
            UserDefaults.standard.set(seenData, forKey: "seenICAOsToday")
        }
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func formatLocationName(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Try different location components in order of preference
        if let locality = placemark.locality {
            components.append(locality)
        } else if let subLocality = placemark.subLocality {
            components.append(subLocality)
        } else if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        // Add country if we have a local name
        if !components.isEmpty, let country = placemark.country {
            components.append(country)
        } else if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }

    func requestUserLocation() {
        let status = locationManager.authorizationStatus
        print("📍 Location authorization status: \(status.rawValue)")
        
        if status == .notDetermined {
            print("📍 Requesting location permission...")
            currentLocationName = "Requesting permission..."
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedAlways {
            print("📍 Permission granted, getting location...")
            currentLocationName = "Getting location..."
            locationManager.requestLocation()
        } else {
            print("📍 Location permission denied or restricted")
            currentLocationName = "Madrid (Location disabled)"
            fetchPlanes()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        print("📍 Got coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        myLat = location.coordinate.latitude
        myLon = location.coordinate.longitude
        
        // Reverse geocode to get place name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let locationName = self?.formatLocationName(placemark) ?? "Unknown Location"
                    print("📍 Location name: \(locationName)")
                    self?.currentLocationName = locationName
                } else {
                    print("📍 Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                    self?.currentLocationName = "Unknown Location"
                }
            }
        }
        
        fetchPlanes()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        currentLocationName = "Madrid (Location failed)"
        fetchPlanes()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 Authorization changed to: \(status.rawValue)")
        requestUserLocation()
    }

    func startTimers() {
        timer?.invalidate()
        countdownTimer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchPlanes()
            DispatchQueue.main.async {
                self?.secondsUntilNextPing = 60
            }
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.secondsUntilNextPing > 0 {
                    self.secondsUntilNextPing -= 1
                }
            }
        }
    }

    func manualRefresh() {
        fetchPlanes()
        secondsUntilNextPing = 60
    }
    
    private func updateDailyStats(with planes: [Plane]) {
        for plane in planes {
            if !seenICAOsToday.contains(plane.icao) {
                seenICAOsToday.insert(plane.icao)
                todaysFlightCount += 1
                
                if let aircraftType = getAircraftTypeForDisplay(icao: plane.icao),
                   let newBiggest = determineBiggestPlane(current: biggestPlaneToday, candidate: aircraftType) {
                    biggestPlaneToday = newBiggest
                }
            }
        }
        saveDailyStats()
    }
    
    private func determineBiggestPlane(current: String?, candidate: String) -> String? {
        let candidateUpper = candidate.uppercased()
        
        let bigPlaneTypes = [
            "A380": 10, "A388": 10,
            "B747": 9, "B748": 9, "B74F": 9,
            "A350": 8, "A359": 8, "A35K": 8,
            "B777": 7, "B77W": 7, "B77L": 7, "B789": 7,
            "A340": 6, "A343": 6, "A346": 6,
            "A330": 6, "A332": 6, "A333": 6,
            "B787": 5, "B788": 5,
            "B767": 4, "B763": 4, "B764": 4,
            "A321": 3, "B757": 3,
            "A320": 2, "B737": 1
        ]
        
        let candidateType = bigPlaneTypes.keys.first { candidateUpper.contains($0) }
        let currentType = bigPlaneTypes.keys.first { (current ?? "").uppercased().contains($0) }
        
        if let candidatePlane = candidateType {
            if let currentPlane = currentType {
                let candidatePriority = bigPlaneTypes[candidatePlane] ?? 0
                let currentPriority = bigPlaneTypes[currentPlane] ?? 0
                return candidatePriority > currentPriority ? candidate : current
            } else {
                return candidate
            }
        } else if let currentPlane = currentType {
            return current
        }
        
        return current ?? candidate
    }

    private func boundingBox(centerLat: Double, centerLon: Double, radiusKm: Double) -> (lamin: Double, lomin: Double, lamax: Double, lomax: Double) {
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(centerLat * .pi / 180))
        return (
            lamin: centerLat - latDelta,
            lomin: centerLon - lonDelta,
            lamax: centerLat + latDelta,
            lomax: centerLon + lonDelta
        )
    }

    func fetchPlanes() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        if displaySettings.useBearerToken {
            ensureValidToken { token in
                self.makeRequest(token: token)
            }
        } else {
            makeRequest(token: nil)
        }
    }
    
    private func ensureValidToken(completion: @escaping (String?) -> Void) {
        if let token = accessToken,
           let expiry = tokenExpiry,
           expiry > Date() {
            completion(token)
            return
        }
        
        getToken(completion: completion)
    }
    
    private func getToken(completion: @escaping (String?) -> Void) {
        guard !displaySettings.clientId.isEmpty,
              !displaySettings.clientSecret.isEmpty else {
            completion(nil)
            return
        }
        
        guard let url = URL(string: "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=client_credentials" +
                  "&client_id=\(displaySettings.clientId)" +
                  "&client_secret=\(displaySettings.clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String,
                  let expires = json["expires_in"] as? Double else {
                completion(nil)
                return
            }
            
            self.accessToken = token
            self.tokenExpiry = Date().addingTimeInterval(expires - 60)
            completion(token)
        }.resume()
    }

    private func makeRequest(token: String?) {
        let boundingBoxResult = boundingBox(centerLat: myLat, centerLon: myLon, radiusKm: selectedRadius)
        let urlString = "https://opensky-network.org/api/states/all" +
                       "?lamin=\(boundingBoxResult.lamin)&lomin=\(boundingBoxResult.lomin)" +
                       "&lamax=\(boundingBoxResult.lamax)&lomax=\(boundingBoxResult.lomax)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        let loadTime = DispatchTime.now() + 0.5
        
        var request = URLRequest(url: url)
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if displaySettings.useBasicAuth && !displaySettings.openSkyUsername.isEmpty && !displaySettings.openSkyPassword.isEmpty {
            let credentials = "\(displaySettings.openSkyUsername):\(displaySettings.openSkyPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.asyncAfter(deadline: loadTime) {
                    self.isLoading = false
                }
                return
            }
            
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 429 {
                    let retryAfter = http.value(forHTTPHeaderField: "x-rate-limit-retry-after-seconds") ?? "unknown"
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let retrySeconds = Int(retryAfter) {
                            self.secondsUntilNextPing = min(retrySeconds, 86400)
                        } else {
                            self.secondsUntilNextPing = 900
                        }
                    }
                    return
                }
            }
            
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                DispatchQueue.main.asyncAfter(deadline: loadTime) {
                    self.isLoading = false
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.asyncAfter(deadline: loadTime) {
                    self.isLoading = false
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(OpenSkyResponse.self, from: data)
                
                guard let states = response.states else {
                    DispatchQueue.main.asyncAfter(deadline: loadTime) {
                        self.isLoading = false
                    }
                    return
                }
                
                let filtered = states.compactMap { state -> Plane? in
                    guard state.count > 9 else { return nil }
                    
                    guard let icao = state[0].stringValue,
                          let lon = state[5].doubleValue,
                          let lat = state[6].doubleValue else { return nil }
                    
                    guard !lon.isNaN && !lat.isNaN else { return nil }
                    
                    let callsignRaw = state[1].stringValue?.trimmingCharacters(in: .whitespaces) ?? ""
                    let altitude = state[7].doubleValue ?? 0
                    let velocity = state[9].doubleValue ?? 0
                    
                    let distance = self.haversine(lat1: self.myLat, lon1: self.myLon, lat2: lat, lon2: lon)
                    
                    if distance <= self.selectedRadius {
                        let route = self.getRouteForCallsign(callsignRaw)
                        
                        let plane = Plane(
                            callsign: callsignRaw.isEmpty ? "Unknown" : callsignRaw,
                            altitude: Int(altitude),
                            lat: lat,
                            lon: lon,
                            icao: icao,
                            route: route,
                            speed: velocity > 0 ? velocity : nil,
                            distance: distance,
                            aircraftType: nil
                        )
                        
                        self.fetchAircraftMetadata(icao: icao)
                        
                        return plane
                    }
                    return nil
                }
                
                DispatchQueue.main.asyncAfter(deadline: loadTime) {
                    self.nearbyPlanes = filtered.sorted { $0.distance ?? 0 < $1.distance ?? 0 }
                    self.updateDailyStats(with: filtered)
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.asyncAfter(deadline: loadTime) {
                    self.isLoading = false
                }
            }
        }
        task.resume()
    }

    private func fetchAircraftMetadata(icao: String) {
        if aircraftCache[icao] != nil {
            return
        }
        
        guard let url = URL(string: "https://opensky-network.org/api/metadata/aircraft/icao/\(icao)") else {
            return
        }
        
        var request = URLRequest(url: url)
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if displaySettings.useBasicAuth && !displaySettings.openSkyUsername.isEmpty && !displaySettings.openSkyPassword.isEmpty {
            let credentials = "\(displaySettings.openSkyUsername):\(displaySettings.openSkyPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let data = data else {
                return
            }
            
            do {
                let metadata = try JSONDecoder().decode(AircraftMetadata.self, from: data)
                
                DispatchQueue.main.async {
                    self.aircraftCache[icao] = metadata
                    self.objectWillChange.send()
                }
                
            } catch {
                // Silent fail for metadata
            }
        }.resume()
    }

    func getPlaneDescription(_ plane: Plane) -> String {
        var parts: [String] = []

        if displaySettings.showCallsign {
            parts.append(plane.callsign)
        }
        if displaySettings.showAircraftType {
            if let aircraftType = getAircraftTypeForDisplay(icao: plane.icao) {
                parts.append("[\(aircraftType)]")
            }
        }
        if displaySettings.showAltitude {
            let altitudeFt = Int(Double(plane.altitude) * 3.28084)
            parts.append("\(altitudeFt)ft")
        }
        if displaySettings.showSpeed, let speed = plane.speed {
            let speedKmh = Int(speed * 3.6)
            parts.append("\(speedKmh)km/h")
        }
        if displaySettings.showDistance, let dist = plane.distance {
            parts.append("\(String(format: "%.1f", dist))km")
        }

        return parts.joined(separator: " • ")
    }
    
    private func getAircraftTypeForDisplay(icao: String) -> String? {
        guard let metadata = aircraftCache[icao] else {
            return nil
        }
        
        var parts: [String] = []
        
        if let built = metadata.built, !built.isEmpty {
            parts.append(built)
        }
        
        if let manufacturer = metadata.manufacturerName, !manufacturer.isEmpty {
            parts.append(manufacturer.uppercased())
        }
        
        if let model = metadata.model, !model.isEmpty {
            parts.append(model.uppercased())
        }
        
        if let aircraftOperator = metadata.aircraftOperator, !aircraftOperator.isEmpty {
            parts.append(aircraftOperator.uppercased())
        }
        
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        
        if let typecode = metadata.typecode, !typecode.isEmpty {
            return typecode
        }
        
        return nil
    }

    private func getRouteForCallsign(_ callsign: String) -> String? {
        let trimmed = callsign.trimmingCharacters(in: .whitespaces)
        
        if trimmed.count >= 4 {
            let airlineCode = String(trimmed.prefix(2))
            let flightNumber = String(trimmed.suffix(trimmed.count - 2))
            
            let airlineNames = [
                "AA": "American",
                "UA": "United",
                "DL": "Delta",
                "IB": "Iberia",
                "AF": "Air France",
                "LH": "Lufthansa",
                "BA": "British Airways",
                "KL": "KLM",
                "VY": "Vueling",
                "UX": "Air Europa",
                "FR": "Ryanair",
                "EK": "Emirates",
                "QR": "Qatar Airways",
                "TK": "Turkish Airlines"
            ]
            
            if let airline = airlineNames[airlineCode] {
                return "\(airline) \(flightNumber)"
            }
        }
        
        return nil
    }

    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
    
    deinit {
        timer?.invalidate()
        countdownTimer?.invalidate()
    }
}
