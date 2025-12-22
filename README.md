# Streamie 📡

Streamie is a native iOS application focused on real-time video streaming.  
The project is structured with a TCA architecture and appears to provide camera preview, stream configuration, and RTMP-based streaming capabilities.

## Demo 🎥

https://github.com/user-attachments/assets/3872249a-c029-49bf-9f18-db8cd0f332f0

---

## Description

Streamie is an iOS app built with **Swift** and **SwiftUI** that enables users to configure and start live video streams.  
It includes camera preview, stream status handling, configuration screens, and secure storage for sensitive data such as stream keys.

The architecture emphasizes modularity by separating app features, streaming logic, and shared infrastructure.

---

## Tech Stack 🛠️

| Category            | Technology / Tool |
|---------------------|-------------------|
| Platform            | iOS |
| Language            | Swift |
| UI Framework        | SwiftUI |
| Architecture        | Feature-based / MVVM-like (assumed) |
| Streaming Protocol  | RTMP (assumed from `RTMPStreamClient`) |
| Secure Storage      | Keychain |
| Persistence         | UserDefaults |
| Tooling             | Xcode |

---

## Features ✨

- 📷 Camera preview for live streaming
- 📡 RTMP streaming client
- ⚙️ Stream configuration and settings
- 🔐 Secure storage using Keychain
- 📊 Stream status and error handling
- 🧩 Modular, feature-oriented project structure

---

## Installation 🚀

1. Clone the repository:
   ```bash
   git clone https://github.com/jewelboi14/Streamie.git
   ```
2. Open the project in Xcode:
   ```bash
   open Streamie.xcodeproj
   ```
3. Select a valid iOS device or simulator.
4. Build and run the project.

> iOS version requirement is **not specified** and should be verified in Xcode project settings.

---

## Usage ▶️

1. Launch the app.
2. Configure streaming settings (e.g. stream URL / key).
3. Preview the camera feed.
4. Start the live stream.
5. Monitor stream status and errors.

> Exact UI flow is inferred from `StreamFeature`, `StreamView`, and configuration-related files.

---

## Project Structure 🗂️

```
Streamie
├── Features
│   ├── App              # App-level state and root view
│   ├── Configuration    # Stream configuration screens
│   └── Stream           # Streaming UI and logic
├── Stream               # Core streaming domain (RTMP, status, errors)
├── Keychain             # Secure credential storage
├── UserDefaults         # Lightweight persistence
├── Shared               # Shared constants and keys
└── Assets               # App icons and color assets
```

---

## Environment / Configuration ⚙️

The app likely requires:
- RTMP server URL
- Stream key or credentials

These values appear to be:
- Stored securely via **Keychain**
- Persisted via **UserDefaults** for non-sensitive data

> No `.env` or explicit configuration files were found.

---

## Roadmap 🧭

- [ ] Improve error handling and recovery
- [ ] Add stream quality presets
- [ ] Support additional streaming protocols
- [ ] Add analytics / stream metrics
- [ ] UI polish and accessibility improvements

---

## Contributing 🤝

Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a pull request

Please follow Swift and SwiftUI best practices.

---

## License 📄

License information is **not specified**.  
Consider adding a `LICENSE` file to clarify usage and distribution terms.
