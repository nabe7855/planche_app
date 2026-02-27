# AI Coding Instructions for Planche Training App

## Project Overview

This is a niche training app for learning the "Planche" safely and efficiently.
Key features: Safety monitoring, Pose estimation (MediaPipe), Local-first data management.

## Core Principles

### 1. Cost Efficiency (Firebase Optimization)

- **Local-First**: Use Hive/Isar for local storage. Cache data heavily.
- **Minimize Read/Write**: Aim for one read per session for user profiles. Use non-streaming `get()` unless real-time sync is strictly necessary.
- **Offline Capability**: The app must function fully offline for training. Sync to Firebase should be a background task or user-triggered.
- **No Infinite Loops**: Always double-check `StreamBuilder` and logic that could trigger repeated API calls.

### 2. Privacy & Legal (Safety First)

- **PII / Sensitive Data**: Health data (injuries, pain) must stay on-device by default. Explicit consent is required before syncing to the cloud.
- **Medical Disclaimer**: Every interaction involving pain or injury must include a clear disclaimer that this is not medical advice.
- **Red Flags**: If a "Red Flag" (sharp pain, numbness) is detected, the app must recommend stopping and consulting a doctor.

### 3. Premium Aesthetics (WOW Factor)

- **Inter/Outfit Fonts**: Avoid default system fonts.
- **Vibrant & Dark Mode**: Use a sleek, modern dark theme suitable for fitness (Dark Grey, Cyan/Electric Blue accents).
- **Micro-animations**: Use smooth transitions for timers and progress bars.
- **No Placeholders**: Use real-looking assets or generated images.

### 4. Communication

- **Language**: All communication with the USER must be in **Japanese**.
- **Comments**: Code comments should be in Japanese to help the USER understand the logic.

## Technical Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **AI**: MediaPipe via Flutter plugins
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Local DB**: Hive
- **UI**: fl_chart for progression visualization
