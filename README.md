# 📱 EcoTracker Flutter - Ready to Run!

## 🚀 Quick Start (3 Steps)

### Step 1: Extract & Open Project

```bash
# Extract ZIP
# Open in VS Code or Android Studio
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Update API URL

Edit `lib/core/constants/api_constants.dart`:

```dart
// Line 3 - GANTI dengan ngrok URL kamu!
static const String baseUrl = 'https://abc123.ngrok-free.app';
```

### Step 4: Run!

```bash
# Connect HP via USB atau run emulator
flutter run
```

---

## 📋 Features

✅ **Login/Register** - User authentication  
✅ **Home Dashboard** - Points & quick actions  
✅ **Create Pickup** - Photo + GPS location  
✅ **My Pickups** - View pickup history  
✅ **Profile** - Points & logout  

---

## 🔧 Setup Ngrok

```bash
# Start Go backend
cd ecotracker
go run main.go

# In new terminal
ngrok http 8080

# Copy URL: https://abc123.ngrok-free.app
# Paste di api_constants.dart
```

---

## 📱 Testing on Physical Device

### Android

1. Enable Developer Options (tap Build Number 7x)
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

### Wireless ADB (Android 11+)

```bash
adb pair <IP>:<PORT>
adb connect <IP>:5555
flutter run
```

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart   ← UPDATE ngrok URL here!
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   └── network/
│       └── api_client.dart
└── features/
    ├── auth/
    │   ├── models/user_model.dart
    │   ├── providers/auth_provider.dart
    │   └── screens/
    │       ├── login_screen.dart
    │       └── register_screen.dart
    ├── home/
    │   └── screens/home_screen.dart
    └── pickup/
        ├── models/pickup_model.dart
        ├── providers/pickup_provider.dart
        └── screens/
            ├── create_pickup_screen.dart
            └── my_pickups_screen.dart
```

---

## 🧪 Test Credentials

Create account via Register atau gunakan:

```
Email: test@example.com
Password: password123
```

(Setelah register di app)

---

## ⚡ Quick Fixes

### "Cleartext HTTP not permitted"

Already fixed! AndroidManifest.xml sudah include `usesCleartextTraffic="true"`

### Location permission denied

App will request permission automatically. Allow di HP.

### Image picker not working

Permissions already added in AndroidManifest.xml

---

## 📸 Screenshots Flow

1. **Login** → Enter email/password
2. **Home** → See points & "Request Pickup" button  
3. **Create Pickup** → Get location → Add address → Take photo → Submit  
4. **My Pickups** → See list with status badges  
5. **Profile** → View points & API connection info  

---

## 🐛 Debug Tips

### Check API Connection

Profile page shows current `baseUrl` - pastikan sama dengan ngrok URL!

### View API Logs

Terminal akan show semua HTTP requests (thanks to pretty_dio_logger)

### Clear App Data

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📦 Dependencies

All dependencies sudah include di `pubspec.yaml`:

- provider (state management)
- dio (HTTP client)
- geolocator (GPS)
- image_picker (camera/gallery)
- permission_handler (permissions)
- intl (date formatting)
- flutter_secure_storage (token storage)
- google_maps_flutter (maps - optional)

---

## ✨ What's Next?

Fitur tambahan yang bisa dikembangkan:

- [ ] Google Maps integration untuk lihat lokasi
- [ ] Real-time status updates
- [ ] Push notifications
- [ ] Reward redemption screen
- [ ] Chat dengan collector
- [ ] Rating & review system

---

## 🆘 Troubleshooting

### App crashes on startup

```bash
flutter clean
flutter pub get
flutter run --verbose
```

### Can't connect to API

1. Check ngrok masih running
2. Check `baseUrl` di api_constants.dart
3. Check backend Go server running
4. Try restart app

### GPS not working

1. Allow location permission
2. Test outdoor (GPS signal)
3. Check Settings → Location → ON

---

**Ready to go! 🚀**

Kalau ada error, check terminal logs atau screenshot error-nya.
