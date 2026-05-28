# วิธีตั้งค่า Google Maps API

## 1. ขอ API Key

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. สร้าง Project ใหม่ หรือเลือก Project ที่มีอยู่
3. ไปที่ **APIs & Services > Library**
4. เปิดใช้งาน **Maps SDK for Android** และ **Maps SDK for iOS**
5. ไปที่ **APIs & Services > Credentials**
6. กด **Create Credentials > API Key**
7. Copy API Key ที่ได้

---

## 2. ตั้งค่า Android

แก้ไขไฟล์ `android/app/src/main/AndroidManifest.xml`
เพิ่มภายใน `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

และเพิ่ม permissions ก่อน `<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 3. ตั้งค่า iOS

แก้ไขไฟล์ `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

แก้ไขไฟล์ `ios/Runner/Info.plist` เพิ่ม:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>แอปต้องการตำแหน่งเพื่อระบุจุดที่เกิดปัญหา IT</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>แอปต้องการตำแหน่งเพื่อระบุจุดที่เกิดปัญหา IT</string>
```

---

## 4. ตั้งค่า Android minSdkVersion

แก้ไขไฟล์ `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21   // ต้องเป็น 21 ขึ้นไปสำหรับ google_maps_flutter
    }
}
```

---

## 5. รัน migration ใน Supabase

รันไฟล์ `supabase/migrations/002_add_location_to_tickets.sql`
ใน Supabase Dashboard > SQL Editor

---

## 6. ติดตั้ง packages

```bash
flutter pub get
```
