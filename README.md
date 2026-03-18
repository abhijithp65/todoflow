# 📝 TodoFlow App

A modern, clean, and scalable Todo application built using **Flutter**, powered by **Riverpod** for state management and structured with **Clean Architecture** principles.

---

## 📱 App Screens

### 🔐 Login Screen

![Login](./screenshots/login.png)

### 🆕 Create Account Screen

![Signup](./screenshots/signup.png)

### 📋 Home / Todo Dashboard

![Home](./screenshots/home.png)

---

## 🚀 Features

* 🔐 Email & Password Authentication
* 🔑 Google Sign-In support
* 🆕 User Registration (Create Account)
* 📋 View all tasks in a clean dashboard
* ➕ Create new tasks
* ✅ Mark tasks as completed
* 📊 Task summary (Total / Active / Done)
* 🔄 Filter tasks (All / Active / Completed)
* 🎯 Progress indicator (completion %)
* 🌙 Beautiful dark UI

---

## 🏗️ Architecture

This project follows **Clean Architecture** with proper separation of concerns:

```
lib/
 ├── core/            # Common utilities, themes, constants
 ├── data/            # Data sources, models, repositories (implementation)
 ├── domain/          # Entities, repository contracts, use cases
 ├── presentation/    # UI, widgets, screens, providers
```

### 🔁 State Management

* Uses **Riverpod** for reactive and scalable state handling
* Ensures testability and separation between UI and business logic

---

## 🎨 UI Highlights

* Minimal and modern dark theme
* Rounded input fields and cards
* Clean task cards with status indicators
* Floating action button for quick task creation
* Smooth and intuitive UX

---

## 🧪 Tech Stack

* **Flutter**
* **Dart**
* **Riverpod**
* **Clean Architecture**

---

## 📦 Getting Started

```bash
# Clone the repo
git clone https://github.com/your-username/todoflow.git

# Navigate into project
cd todoflow

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📌 Future Improvements

* 🔔 Notifications & reminders
* ☁️ Backend integration (Firebase / REST API)
* 🗂️ Categories & tags
* ✏️ Edit task screen
* 📅 Due date picker improvements

---

## 🤝 Contributing

Contributions are welcome! Feel free to fork this repo and submit a PR.

---

## 📄 License

This project is licensed under the MIT License.
