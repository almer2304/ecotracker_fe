🌱 EcoTracker - Mobile App (Flutter)

**EcoTracker** adalah aplikasi mobile untuk mengelola permintaan pengambilan sampah daur ulang. Aplikasi ini memiliki dua role utama: **User** (meminta pickup) dan **Collector** (mengambil & memproses sampah).

---

## 📱 Features

### 👤 User Features
- ✅ Register & Login dengan JWT authentication
- ✅ Request waste pickup dengan foto (camera/gallery)
- ✅ GPS location tracking untuk pickup address
- ✅ View pickup history dengan status tracking (Pending → Taken → Completed)
- ✅ Earn points dari waste collection
- ✅ View point transaction history
- ✅ Browse & claim vouchers dengan points
- ✅ Profile management

### 🚛 Collector Features
- ✅ Login sebagai collector
- ✅ View available pickups (sorted by distance)
- ✅ Real-time distance calculation dengan GPS
- ✅ Take pickup tasks
- ✅ View assigned tasks (My Tasks)
- ✅ Complete tasks dengan input waste details (category + weight)
- ✅ Auto-calculate points per waste item
- ✅ Google Maps integration untuk navigation
- ✅ Profile dengan collector badge

### 🎯 General Features
- ✅ Role-based navigation (auto-redirect based on role)
- ✅ Secure token storage dengan `flutter_secure_storage`
- ✅ Pull-to-refresh lists
- ✅ Infinite scroll untuk large datasets
- ✅ Empty state handling (friendly messages, no errors shown to user)
- ✅ Error logging to console only (user-friendly UI)
- ✅ Consistent distance calculation (GPS caching 5 minutes)

---

## 🛠️ Tech Stack

**Framework:** Flutter 3.24.5 | Dart 3.11.0

**State Management:** Provider ^6.1.1

**Networking:** Dio ^5.4.0, flutter_secure_storage ^9.0.0

**Location & Maps:** geolocator ^10.1.0, google_maps_flutter ^2.5.0, permission_handler ^11.1.0

**Media:** image_picker ^1.0.7

**Others:** intl ^0.18.1, url_launcher ^6.2.4

---

## 📂 Project Structure
```
lib/
├── main.dart                                    # Entry point, role-based navigation
├── core/
│   ├── constants/
│   │   ├── api_constants.dart                   # API endpoints
│   │   └── app_colors.dart                      # Color palette
│   └── network/
│       └── api_client.dart                      # HTTP client dengan JWT
└── features/
    ├── auth/
    │   ├── models/
    │   │   ├── user_model.dart                  # User data model
    │   │   └── auth_response.dart               # Login/Register response
    │   ├── providers/
    │   │   └── auth_provider.dart               # Auth state management
    │   └── screens/
    │       ├── login_screen.dart                # Login UI
    │       └── register_screen.dart             # Register UI
    ├── home/
    │   └── screens/
    │       └── home_screen.dart                 # User Dashboard (Green theme)
    ├── pickup/
    │   ├── models/
    │   │   └── pickup_model.dart                # Pickup data model
    │   ├── providers/
    │   │   └── pickup_provider.dart             # Pickup state management
    │   └── screens/
    │       ├── create_pickup_screen.dart        # Create pickup UI
    │       └── my_pickups_screen.dart           # Pickup history UI
    └── collector/
        ├── models/
        │   └── pickup_with_distance_model.dart  # Pickup + distance
        ├── providers/
        │   └── collector_provider.dart          # Collector state (GPS cache, pagination)
        └── screens/
            ├── collector_dashboard_screen.dart  # Collector Dashboard (Blue theme)
            ├── pending_pickups_screen.dart      # Available pickups
            ├── my_tasks_screen.dart             # Assigned tasks
            ├── pickup_detail_screen.dart        # Detail + Google Maps
            └── complete_task_screen.dart        # Complete task UI
```

---

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK 3.24.5+**
```bash
   flutter --version
```

2. **Android Studio** atau **VS Code** dengan Flutter extension

3. **Physical Device** atau **Emulator** (Android/iOS)

4. **Backend API** harus running di `http://localhost:8080`

---

### Installation

**1. Clone repository**
```bash
git clone 
cd ecotracker_user
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Update API URL**

Edit `lib/core/constants/api_constants.dart`:
```dart
class ApiConstants {
  // GANTI dengan IP komputer kamu atau ngrok URL
  static const String baseUrl = 'http://192.168.1.100:8080';
  // atau gunakan ngrok:
  // static const String baseUrl = 'https://abcd1234.ngrok-free.app';
  
  static const String apiV1 = '$baseUrl/api/v1';
  
  // Auth
  static const String register = '$apiV1/auth/register';
  static const String login = '$apiV1/auth/login';
  static const String profile = '$apiV1/auth/profile';
  
  // Pickups
  static const String pickups = '$apiV1/pickups';
  static const String myPickups = '$apiV1/pickups/my';
  
  // Collector
  static const String collectorPendingPickups = '$apiV1/collector/pickups/pending';
  static const String collectorMyTasks = '$apiV1/collector/pickups/my-tasks';
  static String collectorTakeTask(String id) => '$apiV1/collector/pickups/$id/take';
  static String collectorCompleteTask(String id) => '$apiV1/collector/pickups/$id/complete';
  
  // Vouchers
  static const String vouchers = '$apiV1/vouchers';
  static const String myVouchers = '$apiV1/vouchers/my';
  static String claimVoucher(String id) => '$apiV1/vouchers/$id/claim';
}
```

**4. Run app**
```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d 

# atau langsung run
flutter run
```

---

### Setup Ngrok (untuk Physical Device Testing)

Jika testing di HP fisik (bukan localhost):
```bash
# 1. Install ngrok dari https://ngrok.com/download

# 2. Start ngrok
ngrok http 8080

# 3. Copy HTTPS URL yang muncul
# Example: https://abcd-1234-5678.ngrok-free.app

# 4. Update api_constants.dart dengan URL tersebut
static const String baseUrl = 'https://abcd-1234-5678.ngrok-free.app';
```

---

## 📱 User Guide

### As User (Request Pickup)

**1. Register & Login**
- Open app → Tap "Register"
- Fill: Name, Email, Password, Phone
- Role akan auto-set sebagai "user"
- Login → Auto redirect ke **User Dashboard** (Green theme)

**2. Request Pickup**
- Tap **"Request Pickup"** button
- Fill form:
  - **Address:** Type atau tap GPS icon untuk auto-fill
  - **Photo:** Tap camera icon → Choose camera/gallery
  - **Notes:** (Optional) Special instructions
- Tap **"Submit"**
- Pickup created dengan status "Pending"

**3. Track Pickup Status**
- Tap **"My Pickups"** tab
- See status progression:
  - **Pending** (Orange) - Waiting for collector
  - **Taken** (Blue) - Collector on the way
  - **Completed** (Green) - Waste collected, points awarded
- Pull down to refresh

**4. View Points & History**
- Home screen menampilkan **Total Points**
- Tap **"Point History"** untuk detail transactions
- Points earned saat pickup completed

**5. Claim Vouchers**
- Tap **"Rewards"** tab
- Browse available vouchers (Starbucks, GrabFood, dll)
- Check points requirement
- Tap voucher → **"Claim"**
- Voucher code appears in **"My Vouchers"**
- Show code to merchant untuk redeem

---

### As Collector (Process Waste)

**1. Login**
- Admin harus create collector account via API
- Login dengan collector email & password
- Auto redirect ke **Collector Dashboard** (Blue theme)

**2. View Available Pickups**
- Tab **"Available"** (default tab)
- Allow location permission untuk distance calculation
- Pickups sorted by distance (nearest first)
- See:
  - Distance badge (e.g., "1.2 km")
  - Photo preview
  - Address & notes
  - Created time

**3. Take Task**
- Tap pickup card → **View Details**
- See:
  - **Google Map** dengan marker
  - Full photo
  - Complete address
  - Distance from your location
- Tap **"Open in Google Maps"** untuk navigation
- Tap **"Take This Task"** → Confirm
- Task moved to **"My Tasks"** tab

**4. Complete Task**
- Tab **"My Tasks"**
- Find pickup dengan status "TAKEN"
- Tap **"Complete Task"**
- Add waste items:
  - Tap **"Add Item"**
  - Select **Category** (Plastic, Paper, Metal, Glass, Organic)
  - Input **Weight** (kg) - e.g., 5.5
  - See **Points Preview** (auto-calculated)
  - Repeat untuk multiple items
- Review **Total Weight & Points**
- Tap **"Complete Task"** → Confirm
- Points awarded to user automatically

**5. View Task History**
- Completed tasks remain in "My Tasks" dengan status "COMPLETED"
- Pull down to refresh

---

## 🎨 App Themes

| Role | Theme Color | Icon | Feel |
|------|------------|------|------|
| **User** | Green `#4CAF50` | 🌱 Recycling | Eco-friendly, nature |
| **Collector** | Blue `#1976D2` | 🚛 Truck | Professional, logistics |

---

## 🔐 Authentication Flow
```
App Start
  ↓
Check token in secure storage
  ↓
  ├─ Token EXISTS
  │   ↓
  │   Fetch user profile
  │   ↓
  │   Check role
  │   ├─ role = "user" → User Dashboard (Green)
  │   └─ role = "collector" → Collector Dashboard (Blue)
  │
  └─ Token NOT EXISTS
      ↓
      Login Screen
      ↓
      Login Success
      ↓
      Save JWT token
      ↓
      Navigate based on role
```

**Auto-Login:**
- Token disimpan di `flutter_secure_storage`
- Next app open → Auto-login tanpa re-enter credentials
- Logout → Token dihapus → Kembali ke Login screen

---

## 📊 Performance Optimizations

### 1. GPS Location Caching (5 minutes)
**Problem:** GPS coordinates berubah setiap request → Inconsistent distances

**Solution:**
- Cache GPS coordinates untuk 5 menit
- Reuse same location untuk consistency
- Auto-refresh on pull-to-refresh

**Result:** Distance konsisten (1.2 km tetap 1.2 km, bukan berubah jadi 1.5 km)

---

### 2. Pagination & Infinite Scroll (20 items/page)
**Problem:** Loading 1000+ pickups sekaligus → Slow & crash

**Solution:**
- Backend: `GET /pickups/pending?page=1&limit=20`
- Frontend: Load 20 items first, auto-load more saat scroll ke bottom
- Smooth infinite scroll

**Result:** App tetap smooth dengan 10,000+ pickups

---

### 3. Data Caching (2 minutes)
**Problem:** Redundant API calls saat screen refresh

**Solution:**
- Cache data untuk 2 menit
- Return cached data jika masih valid
- Force refresh dengan pull-to-refresh

**Result:** Faster load, less bandwidth

---

### 4. Image Compression
**Problem:** Large photos (5-10 MB) → Slow upload

**Solution:**
- Compress images before upload
- Max file size: ~1-2 MB

**Result:** Faster uploads, less storage

---

## 🐛 Troubleshooting

### Problem: Login returns 401 Unauthorized
**Possible Causes:**
- Backend tidak running
- Wrong email/password
- Ngrok URL expired
- Token invalid

**Solutions:**
```bash
# 1. Check backend running
cd ecotracker_backend
go run main.go
# Should see: "Server running on :8080"

# 2. Check ngrok (jika pakai)
ngrok http 8080
# Update URL di api_constants.dart

# 3. Try register new account
# Pastikan email belum ada di database

# 4. Check backend logs
# Look for: [LOGIN DEBUG] atau [LOGIN ERROR]
```

---

### Problem: GPS tidak akurat / tidak bisa get location
**Solutions:**
```bash
# 1. Allow location permission di HP settings
# Settings → Apps → EcoTracker → Permissions → Location → Allow

# 2. Enable GPS/Location services di HP
# Settings → Location → ON

# 3. Test di outdoor (better GPS signal)

# 4. Check logs
# Look for: [COLLECTOR] Location error
```

---

### Problem: Photo upload gagal (500 error)
**Possible Causes:**
- Supabase bucket not configured
- Wrong service_role key
- Network timeout

**Solutions:**
```bash
# 1. Check backend logs
# Look for: [PICKUP] Processing photo

# 2. Check Supabase bucket settings
# Bucket name: waste-photos
# Public: YES
# No nested folders

# 3. Check .env file (backend)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
STORAGE_BUCKET=waste-photos
```

---

### Problem: Collector tidak bisa complete task
**Possible Causes:**
- Weight input tidak valid (0 atau kosong)
- Category_id salah
- Backend error

**Solutions:**
```bash
# 1. Check weight input
# Must be > 0 (e.g., 5.5, not 0)

# 2. Check backend logs
[COMPLETE] Processing item 1: category_id=3, weight=5.50
[COMPLETE ERROR] ...

# 3. Check point_logs constraint
# Error: "transaction_type_check" → Fix backend
# Change 'earn' to 'earned' di pickup_repository.go
```

---

### Problem: App redirect ke wrong dashboard after login
**Possible Causes:**
- Token dari previous user masih ada
- Role tidak di-detect properly

**Solutions:**
```dart
// 1. Force logout & clear token
await authProvider.logout();

// 2. Close app completely (task manager)

// 3. Login lagi

// 4. Check logs
[AUTH CHECKER] Role: "collector"
[AUTH CHECKER] ✓ Navigating to COLLECTOR dashboard
```

---

### Problem: Distance tidak konsisten (berubah-ubah)
**Cause:** GPS coordinates berubah setiap request

**Solution:** Already fixed dengan GPS caching!
```dart
// collector_provider.dart sudah implement GPS caching
// Cache location untuk 5 minutes
// Force refresh: Pull-to-refresh
```

---

### Problem: Empty state shows error instead of friendly message
**Solution:** Check screen implementation
```dart
// Good ✅
if (pickups.isEmpty) {
  return EmptyStateWidget("No pickups yet");
}

// Bad ❌
if (error != null) {
  return Text(error); // Shows raw error to user
}

// Correct ✅
if (error != null) {
  print('[ERROR] $error'); // Log to console only
  return FriendlyErrorWidget();
}
```

---

## 🧪 Testing Credentials

### Test Accounts

**User Account:**
```
Email: test@test.id
Password: password123
Role: user
```

**Collector Account:**
```
Email: col1@test.com
Password: password123
Role: collector
```

**Admin Account (for API testing):**
```
Email: admin@ecotracker.com
Password: password123
Role: admin
```

### Create Collector Account (via API)

Collector account harus dibuat oleh admin:
```bash
# 1. Login sebagai admin (Postman/cURL)
POST http://localhost:8080/api/v1/auth/login
Body: {
  "email": "admin@ecotracker.com",
  "password": "password123"
}
# Response: { "token": "eyJhbGc..." }

# 2. Create collector dengan admin token
POST http://localhost:8080/api/v1/admin/collectors
Headers: Authorization: Bearer {admin_token}
Body: {
  "name": "Collector Test",
  "email": "collector@test.com",
  "password": "password123",
  "phone": "081234567890"
}

# 3. Login di Flutter app dengan collector credentials
```

---

## 📝 Development Tips

### Hot Reload & Hot Restart
```bash
# During development
# Press 'r' in terminal → Hot Reload (fast)
# Press 'R' in terminal → Hot Restart (full restart)
# Press 'q' in terminal → Quit
```

### Debug Logs
App heavily uses `print()` statements:
```dart
[AUTH] Checking auth status...
[COLLECTOR] Fetching page 1...
[PICKUP] Creating pickup...
```

Buka terminal untuk melihat logs detail.

### Clean Build (jika error aneh)
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔮 Future Enhancements

- [ ] Push notifications (new pickup, task assigned, voucher claimed)
- [ ] Chat between user & collector
- [ ] Rating & review system
- [ ] Leaderboards (top users, top collectors)
- [ ] Milestones & badges (achievements)
- [ ] Referral system
- [ ] Dark mode
- [ ] Multi-language support (EN/ID)
- [ ] Offline mode (cache data)
- [ ] Social sharing (share achievements)

---

## 📄 License

MIT License - Copyright (c) 2026 EcoTracker

---

## 👨‍💻 Support

**Issues?** Check troubleshooting section atau hubungi developer.

**Logs:** Always check terminal logs untuk detailed error messages.

**Backend:** Pastikan backend running sebelum test app.

---

**Built with 💚 for a cleaner Earth 🌍**