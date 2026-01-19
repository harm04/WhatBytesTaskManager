# Task Management App (Flutter)

A simple and clean task management mobile application built using Flutter.  
The app allows users to create, manage, and track tasks efficiently with authentication, prioritization, and filtering features.

This project is developed as part of the **Flutter Developer Intern Assignment** for **WhatBytes**.

---

## Features

### User Authentication
- User registration and login using Firebase Authentication
- Proper error handling for invalid credentials
- Persistent login handled automatically by Firebase Authentication

### Task Management
- Create, edit, delete, and view tasks
- Mark tasks as completed or incomplete
- Each task includes:
  - Title
  - Description
  - Due Date
  - Priority (Low, Medium, High)

### Filtering and Sorting
- Filter tasks by:
  - Priority (Low, Medium, High)
  - Status (Completed / Incomplete)
- Tasks are sorted by due date (earliest to latest)

### User Interface
- Clean and responsive UI following Material Design principles
- Task grouping based on due dates (Today, Tomorrow, This Week)
- Color-coded priority indicators
- Loading and empty state handling

---

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- flutter_riverpod (State Management)
- Clean Architecture

---

## Project Architecture

The project follows Clean Architecture with proper separation of concerns:

