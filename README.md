# PlaneWatcher

**PlaneWatcher** is a modern macOS menu bar app that shows you real-time information about planes flying near your current location. It uses the OpenSky Network API to fetch live aircraft data and presents it in a clean, compact, and customizable interface.

---

## Features

- **Menu Bar Integration:** Runs quietly in your menu bar with a dynamic airplane icon that turns green when planes are nearby.
- **Live Nearby Planes:** See a list of planes currently flying within a configurable radius of your location.
- **Flight Details:** Click on any plane to view detailed information, including callsign, aircraft type, altitude, speed, distance, and route.
- **Recent Flights:** View a history of the last 5 planes detected, with timestamps.
- **Location Awareness:** Uses your Mac’s location (with permission) to show relevant flights.
- **Authentication Support:** Enter your OpenSky credentials for higher API rate limits and faster updates (10s interval for authenticated users, 60s for anonymous).
- **Customizable Display:** Toggle which details to show (callsign, aircraft type, altitude, speed, distance, etc.) in the settings.
- **Settings Popover:** Easily adjust display and authentication options from the menu bar.
- **Automatic Window Management:** Optionally open a dedicated window for each detected plane.
- **macOS Native:** Built with SwiftUI for a seamless, native experience.

---

## Screenshots

*(Add your own screenshots here!)*

---

## Installation

### Requirements

- macOS 13.0 or later
- Xcode 14 or later (for building from source)
- [OpenSky Network account](https://opensky-network.org/) (optional, for higher rate limits)

### Build & Run

1. **Clone the repository:**
   ```sh
   git clone https://github.com/jon-hidalgo/PlaneWatcher.git
   cd PlaneWatcher
   ```

2. **Open in Xcode:**
   - Double-click `PlaneWatcher.xcodeproj` or run:
     ```sh
     open PlaneWatcher.xcodeproj
     ```

3. **Build and Run:**
   - Select the `PlaneWatcher` scheme and click the Run button in Xcode.

4. **Grant Location Permission:**
   - The app will request access to your location on first launch.

---

## Usage

- **Menu Bar Icon:**  
  - The airplane icon appears in your menu bar. It turns green when planes are nearby.
- **View Planes:**  
  - Click the icon to see a list of nearby planes and recent flights.
- **Plane Details:**  
  - Click a plane to open a detailed window, or click the external link to view it on Globe.adsbexchange.com.
- **Settings:**  
  - Click the “Settings” button to adjust display options or enter OpenSky credentials for higher API limits.

---

## Configuration

- **Radius:**  
  - The default search radius is 3km. You can change this in the code if needed.
- **Authentication:**  
  - Enter your OpenSky username/password or OAuth2 credentials in the settings for up to 10,000 requests/day and faster updates.

---

## Development

- **SwiftUI** and **Combine** for reactive UI and data flow.
- **CoreLocation** for location services.
- **UserDefaults** for persistent settings and flight history.
- **OpenSky Network API** for real-time aircraft data.

---

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [OpenSky Network](https://opensky-network.org/) for the aircraft data API.
- [Apple](https://developer.apple.com/) for SwiftUI and macOS development tools. 