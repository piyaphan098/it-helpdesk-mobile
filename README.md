<div align="center">

<img src="https://raw.githubusercontent.com/piyaphan098/it-helpdesk-mobile/main/assets/icon/app_icon.png" width="100" height="100" alt="IT Support Helpdesk" />

# 🛠️ IT Support Helpdesk

**แอพแจ้งซ่อม IT แบบ On-Demand สำหรับองค์กร**

ผู้ใช้แจ้งปัญหา → ช่างรับงาน → ติดตาม Real-time → ปิดงาน & รีวิว

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-blue?style=flat-square)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

</div>

---

## 📱 ภาพรวม

IT Support Helpdesk คือแอพมือถือที่ช่วยให้การแจ้งซ่อม IT ในองค์กรเป็นเรื่องง่าย โดยเชื่อมระหว่าง **ผู้ใช้** ที่มีปัญหา กับ **ช่างเทคนิค** ที่พร้อมแก้ไข ผ่านระบบ Ticket ที่ติดตามสถานะได้แบบ Real-time

---

## ✨ ฟีเจอร์หลัก

### 👤 ฝั่งผู้ใช้ (Employee)
| ฟีเจอร์ | รายละเอียด |
|--------|-----------|
| 🎫 สร้าง Ticket | แจ้งปัญหาพร้อมรูปภาพ, ประเภท, ระดับความเร่งด่วน และตำแหน่ง GPS |
| 📍 ระบุตำแหน่ง | แนบแผนที่จุดที่เกิดปัญหาด้วย OpenStreetMap |
| 📊 ติดตามสถานะ | ดูความคืบหน้า Ticket แบบ Real-time |
| 💬 แชทกับช่าง | สื่อสารกับช่างเทคนิคในแต่ละ Ticket |
| 📞 โทรแบบซ่อนเบอร์ | โทรหาช่างโดยไม่เปิดเผยเบอร์ส่วนตัว |
| ⭐ รีวิวการบริการ | ให้คะแนนช่างหลังปิดงาน |
| 🔔 การแจ้งเตือน | รับ notification ทุกการเปลี่ยนแปลงสถานะ |

### 🔧 ฝั่งช่างเทคนิค (Technician)
| ฟีเจอร์ | รายละเอียด |
|--------|-----------|
| 📋 Dashboard | ภาพรวมงานทั้งหมด สถิติ และงานที่รอรับ |
| ✅ รับ & จัดการงาน | รับ Ticket และอัปเดตสถานะการซ่อม |
| 🗺️ ติดตามตำแหน่ง | แผนที่ Real-time tracking ระหว่างเดินทาง |
| 👔 โปรไฟล์สาธารณะ | หน้าโปรไฟล์ที่ผู้ใช้ดูข้อมูลและรีวิวได้ |
| 📝 จัดการโพสต์ | ประกาศข่าวสารหรือบริการ |

---

## 🏗️ สถาปัตยกรรม

```
lib/
├── core/
│   ├── constants/          # App constants, routes, Supabase config
│   ├── errors/             # Error handling & exceptions
│   └── router/             # GoRouter configuration
├── features/
│   ├── auth/               # Login, Register, Forgot Password
│   ├── dashboard/          # หน้า Dashboard ผู้ใช้
│   ├── tickets/            # สร้าง, ดู, จัดการ Ticket
│   ├── technician/         # ระบบช่างเทคนิคทั้งหมด
│   ├── notifications/      # ระบบแจ้งเตือน
│   ├── profile/            # จัดการโปรไฟล์
│   └── shell/              # Main navigation shell
├── models/                 # Ticket, UserProfile, UserRole
├── repositories/           # Auth, Ticket repositories
├── services/               # Supabase service
├── theme/                  # App theme, colors, typography
└── widgets/                # Shared widgets
```

**Pattern:** Feature-based Architecture + Repository Pattern + Riverpod

---

## 🧱 Tech Stack

| ส่วน | เทคโนโลยี |
|------|-----------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Backend | Supabase (Auth + PostgreSQL + Realtime + Storage) |
| State Management | Flutter Riverpod |
| Navigation | GoRouter |
| Maps | flutter_map + OpenStreetMap |
| Image Cache | cached_network_image |

---

## 🚀 วิธีติดตั้งและรัน

### ความต้องการ
- Flutter SDK 3.x ขึ้นไป
- Dart SDK 3.x ขึ้นไป
- บัญชี Supabase

### 1. Clone โปรเจกต์
```bash
git clone https://github.com/piyaphan098/it-helpdesk-mobile.git
cd it-helpdesk-mobile
```

### 2. ติดตั้ง dependencies
```bash
flutter pub get
```

### 3. ตั้งค่า Supabase

แก้ไข `lib/core/constants/supabase_constants.dart`:
```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. ตั้งค่า Google Maps (สำหรับ Tracking)

ดูรายละเอียดใน [SETUP_GOOGLE_MAPS.md](SETUP_GOOGLE_MAPS.md)

### 5. รันแอพ
```bash
flutter run
```

---

## 🗄️ Database Schema

ดู schema หลักได้ที่ [supabase/README.md](supabase/README.md)

ตาราง:
- `profiles` — ข้อมูลผู้ใช้และช่างเทคนิค
- `tickets` — Ticket การแจ้งซ่อม
- `ticket_reviews` — รีวิวและคะแนนช่าง
- `ticket_comments` — ข้อความแชทในแต่ละ Ticket

---

## 📊 สถานะ Ticket

```
open → in_progress → resolved → closed
                              ↘ cancelled
```

| สถานะ | ความหมาย |
|------|---------|
| 🟢 Open | รอช่างรับงาน |
| 🟠 In Progress | ช่างกำลังดำเนินการ |
| 🟡 Resolved | ช่างแจ้งว่าเสร็จแล้ว รอผู้ใช้ยืนยัน |
| ⚫ Closed | ปิดงานเรียบร้อย |
| 🔴 Cancelled | ยกเลิก Ticket |

---

## 👥 บทบาทผู้ใช้

| Role | สิทธิ์ |
|------|-------|
| `employee` | สร้าง/ติดตาม Ticket, รีวิวช่าง |
| `technician` | รับงาน, อัปเดตสถานะ, ดู Dashboard ช่าง |

---

## 📄 License

MIT License — ดูรายละเอียดใน [LICENSE](LICENSE)

---

<div align="center">

Made with ❤️ using Flutter & Supabase

</div>
