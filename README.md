# Sightline App

A cross-platform AI application for image captioning built with Flutter.

## Overview

Sightline is an AI-powered mobile and web application that generates descriptive captions for uploaded images using advanced machine learning models. The app features user authentication, caption history, accessibility options, and a responsive design that works across multiple platforms.

## Features

### AI Image Captioning
- Upload images and get AI-generated descriptions
- Supports JPG, JPEG, PNG formats
- Real-time caption generation using BLIP model
- Image preview with generated captions

### User Management
- User registration and secure login
- JWT token-based authentication
- Personal caption history
- User profile management

### Accessibility Features
- Text-to-speech (TTS) for generated captions
- Adjustable font sizes
- Volume control for audio feedback
- Multi-language TTS support
- Dark/Light theme support

### Cross-Platform Support
- Web application (Chrome, Firefox, Safari)
- Mobile apps (Android, iOS)
- Desktop apps (Windows, macOS, Linux)
- Responsive design for all screen sizes

## Getting Started

### Prerequisites

- **Flutter SDK**: ^3.8.0
- **Dart SDK**: Included with Flutter
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA
- **API Backend**: Sightline API running on localhost:8000

### Development Setup

1. **Clear Flutter tools cache**:
   ```bash
   flutter clean
   # Or remove the Build folder
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Command**:
    ```bash
    # Web browsers
    flutter run -d chrome
    flutter run -d edge  
    flutter run -d web-server

    # Mobile
    flutter run -d android
    flutter run -d ios

    # Desktop
    flutter run -d windows
    flutter run -d macos
    flutter run -d linux
    ```