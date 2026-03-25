# 🎓 School Management System (SMS) - Frontend

A beautiful and responsive **School Management Application** built with **Flutter**. This application serves as the primary interface for administrators and staff to manage students, fees, attendance, and payroll.

---

## 🚀 Key Features

### 💎 Premium Golden UI
- **Modern Aesthetic:** A high-end, gold-themed user interface designed for 2024.
- **Micro-Animations:** Fluid transitions and hover effects for a premium feel.
- **Glassmorphism:** Elegant frosted-glass components throughout the dashboard.

### 👤 Student Management
- **Smart Search:** Quick search by name or ID.
- **Class Filtering:** View students by grade and section (e.g., IX-B).
- **Registration:** Detailed onboarding for new students.

### 💰 Comprehensive Fees Module
- **Dual Fee Tracking:** Separate management for Registration and Monthly/Installment fees.
- **Van Fees:** Dedicated tracking for students using school transportation.
- **Automated Receipts:** Instant PDF generation for all fee payments.
- **Payment History:** Full chronological log of all student financial transactions.

### 📝 Attendance System
- **Real-time Marking:** Mark daily presence/absence with a simple toggle.
- **WhatsApp Integration:** Automated absence alerts sent to parents via Twilio/Meta API.
- **Attendance History:** Searchable logs for past attendance records.
- **Monthly Reports:** Summary views for monthly attendance percentages.

### 👨‍🏫 Staff & Payroll
- **Staff Profiles:** Centralized database of all teaching and non-teaching staff.
- **Salary Logs:** Track monthly salary payouts and bonus structures.
- **Staff Exports:** One-click Excel/PDF exports for government or bank records.

### 📢 Communications & Logs
- **Message Logs:** Real-time monitoring of WhatsApp notification delivery status.
- **Audit Trail:** History of when messages were sent and who received them.

### 🔐 Multi-Role Access
- **Admin Workspace:** Full control over school settings, financials, and staff.
- **Staff Workspace:** Restricted access focused on attendance and student records.
- **Secure Sessions:** JWT-based authentication with persistent login.

---

## 🛠️ Tech Stack (Frontend)

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Navigation:** [Go Router](https://pub.dev/packages/go_router)
- **Styling:** Custom "Premium Golden" aesthetic with [Google Fonts](https://pub.dev/packages/google_fonts)
- **Networking:** [http](https://pub.dev/packages/http)
- **PDF & Assets:** Integrated support for document viewing and sharing.

---

## 📂 Folder Structure

- `lib/main.dart`: App entry point.
- `lib/screens/`: UI pages organized by role (Admin vs. Shared).
- `lib/providers/`: Universal state management logic.
- `lib/services/`: API client and networking service.
- `lib/models/`: Frontend data models for JSON parsing.
- `lib/widgets/`: Reusable UI components and design tokens.
- `assets/`: Images and fonts used in the application.

---

## ⚙️ Installation & Setup

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Frontend Setup
1. Clone the repository and navigate to the project directory:
   ```bash
   cd School_Management_Frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Create a configuration file if needed (e.g., for API base URL) in `lib/services/api/`:
   - Ensure the `baseUrl` points to your running backend instance.

4. Run the application:
   ```bash
   flutter run
   ```

---

## 📖 Usage
1. **Login:** Use your credentials to log in via the dashboard.
2. **Dashboard:** Access various modules like Students, Fees, and Staff from the main navigation.
3. **Mark Attendance:** Select a class and mark students present or absent.
4. **Export Data:** Use the export buttons in the Staff or Attendance sections to generate PDF/Excel files.

---

## 🧪 Testing
Run Flutter widget and unit tests:
```bash
flutter test
```

---

## 🤝 Contributing
1. Fork the project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

---

*Built by Bharath Aadhya Intelligent Solutions.*
