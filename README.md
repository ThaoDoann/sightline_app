# sightline_app

A cross-platform AI application for image captioning with camera and gallery support.

## Features

- 📸 **Take Photos**: Use your device camera to capture images
- 🖼️ **Gallery Upload**: Select images from your photo gallery
- 🤖 **AI Captioning**: Generate intelligent descriptions of your images
- 🔊 **Text-to-Speech**: Listen to generated captions
- 📱 **Cross-Platform**: Works on Android, iOS, and Desktop
- 📚 **History**: View and manage your previous captions

## Prerequisites

Before running the app, make sure you have:

1. **Flutter SDK** (version 3.8.0 or higher)
2. **Dart SDK** (comes with Flutter)
3. **Android Studio** (for Android development)
4. **Python 3.8+** (for backend API)
5. **Git**

## Setup Instructions

### 1. Backend API Setup

First, set up the backend API that provides the image captioning service:

```bash
# Navigate to the API directory
cd sightline_api

# Install Python dependencies
pip install -r requirements.txt

# Start the backend server
python main.py
```

### 2. Flutter App Setup

```bash
# Navigate to the Flutter app directory
cd sightline_app

# Get Flutter dependencies
flutter pub get
```
**Create the .env file with the appropriate API_URL for your platform:**
echo "API_URL=http://localhost:8000" > .env

#### For Web Browsers (Chrome, Edge, Safari):
```bash
echo "API_URL=http://localhost:8000" > .env
```

#### For Android Emulator:
```bash
echo "API_URL=http://YOUR_IP_ADDRESS:8000" > .env
```
Replace `YOUR_IP_ADDRESS` with your actual IP address


### 3. Running the App
#### For Web:

```bash
# Run on browsers
flutter run -d chrome
flutter run -d edge
```

#### For Android:
**Step 1: Set up Android Emulator**
```bash
# List available emulators
flutter emulators

# If no emulators are available, create one:
# 1. Open Android Studio
# 2. Go to Tools → AVD Manager
# 3. Click "Create Virtual Device"
# 4. Choose a device (e.g., Pixel 4)
# 5. Choose a system image (e.g., API 34)
# 6. Click "Finish"
```
**Step 2: Start the emulator**
```bash
# List available emulators
flutter emulators

# Start an emulator (replace EMULATOR_NAME with your emulator name)
flutter emulators --launch EMULATOR_NAME

# Wait for emulator to fully boot (you'll see the Android home screen)
# Then check available devices
flutter devices
```

**Step 3: Run the app**
```bash
# Run on the emulator (replace DEVICE_ID with your emulator ID)
flutter run -d DEVICE_ID

# Example: flutter run -d emulator-5554
```**Step 3: Run the app**
```bash
# Run on the emulator (replace DEVICE_ID with your emulator ID)
flutter run -d DEVICE_ID

# Example: 
flutter run -d emulator-5554
```

#### For iOS:

**Prerequisites:**
- macOS computer required
- Xcode installed
- iOS Simulator or physical iOS device

**Run iOS Simulator**
```bash
# Open iOS Simulator
open -a Simulator

# Check available devices
flutter devices

# Run the app
flutter run -d ios
```

#### For Desktop:
```bash
# Enable desktop support (if not already enabled)
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
flutter config --enable-macos-desktop

# Run on your platform
flutter run -d windows  # For Windows
flutter run -d linux    # For Linux
flutter run -d macos    # For macOS
```



## Troubleshooting

### Common Issues

1. **Camera Permission Denied**
   - Go to device settings and enable camera permission for the app
   - Restart the app after granting permission

2. **Backend Connection Error**
   - Make sure the backend API is running
   - Check if the `.env` file contains the correct API_URL

3. **Flutter Dependencies Issues**
   ```bash
   flutter clean
   flutter pub get
   ```


## Development

### Project Structure

```
sightline_app/
├── lib/
│   ├── screens/
│   │   ├── home_screen.dart      # Main app screen
│   │   └── camera_screen.dart    # Custom camera interface
│   ├── services/
│   │   └── caption_service.dart  # API communication
│   ├── models/
│   │   └── caption_entry.dart    # Data models
│   └── styles/
│       └── app_theme.dart        # App styling
├── android/                      # Android-specific files
├── ios/                         # iOS-specific files
└── pubspec.yaml                 # Dependencies
```


## API Endpoints

- `GET /`: Health check
- `POST /caption`: Generate caption from uploaded image