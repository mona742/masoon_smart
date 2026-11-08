# 🚗 Masoon (مَصُون) – Smart Vehicle Maintenance Ecosystem

> "Transforming car maintenance from a reactive expense into a proactive investment."

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

---

## 📌 About the Project (نبذة عن المشروع)
**Masoon (مَصُون)** is a comprehensive cross-platform (iOS & Android) B2B & B2C ecosystem that bridges the gap between auto repair workshops and car owners. By leveraging real-time data, background location tracking, and automated proactive notifications, Masoon ensures optimal vehicle health while maximizing customer retention for workshops.

---

## ✨ Core Features (المميزات الأساسية)

### 🏢 Workshop Portal (بوابة الورش):
* **Inventory & Offers Management:** Upload and manage spare parts and maintenance services with custom "Featured" tags.
* **Smart Booking Dashboard:** Filtered incoming appointments with a tabbed interface (Pending / Archive) and instant alerts[cite: 2].
* **Customer Client Lookup:** Quick search and car profile management using vehicle plate numbers or VIN.

### 👤 Client Portal (بوابة العميل):
* **Live Background GPS Tracking:** Continuously syncs vehicle mileage with Cloud Firestore, bypassing strict OS background execution limits.
* **Smart Oil & Maintenance Meter:** Real-time visual progress bars indicating component lifespan (tires, AC filters, brake fluid, engine oil).
* **Dynamic Smart Store:** Automatically filters spare parts based on the user's specific vehicle make and model.
* **Digital Car Value Report ("The Golden Ticket"):** Generates a verified digital maintenance history report, API-ready for integration with official platforms (e.g., Mojaz).
* **Proactive FCM Notifications:** Automated alerts triggered when maintenance thresholds are reached (e.g., oil consumption at 90%)[cite: 2].

---

## 🛠️ Tech Stack & Architecture (التقنيات المستخدمة)
* **Frontend:** Flutter (Dart) - Clean UI/UX designed with Google Fonts and Material 3.
* **Backend & Database:** Firebase Cloud Firestore & Firebase Auth.
* **Background Processing:** `flutter_background_service` for continuous location and mileage synchronization.
* **Notifications:** Firebase Cloud Messaging (FCM) & Local Notifications.
* **State Management & Local Storage:** Provider & SharedPreferences.

---

## 🚀 Getting Started (خطوات التشغيل)

### Prerequisites (المتطلبات الأساسية)
* Flutter SDK installed (compatible with latest stable version).
* Dart SDK.
* Firebase project configured with Firestore and FCM.

### Installation Steps (خطوات التثبيت)
1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/masoon-smart.git](https://github.com/your-username/masoon-smart.git)

Navigate to project directory:
cd masoon-smart

Install dependencies:
flutter pub get

Run the app:
flutter run

👩‍💻 Author (المطورة)
Developed with 💙 by Mona (Software Engineer & Mobile App Developer).
