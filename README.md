# SafeMed – Counterfeit Medicine Detection App

SafeMed is an Android mobile application that helps users verify the authenticity of selected over-the-counter (OTC) medicines by analyzing packaging images using a YOLOv8-based object detection model running entirely on-device.

The app serves as a consumer-level preliminary verification tool for identifying potentially counterfeit medicines through visual packaging analysis, without requiring an internet connection for detection.

---

## Features

- Scan → Predict → Result workflow for fast end-to-end verification  
- Detection of authentic vs. counterfeit packaging for five OTC medicines:
  - Biogesic  
  - Alaxan FR  
  - Neozep Forte  
  - Bioflu  
  - Medicol  
- Inconclusive result when confidence is below 75% to prevent misleading outputs  
- Medicine mismatch detection (incorrect drug selected vs. scanned packaging)  
- Offline inference using TorchScript-exported YOLOv8s models (no internet required)  
- About / Learning Module with FDA-sourced information and developer details  

---

## Tech Stack

### Frontend / App Framework
- Flutter 3.29.2  
- Dart 3.7.2  

### Machine Learning
- PyTorch  
- YOLOv8s models exported to TorchScript / PyTorch Lite for mobile inference  

### Model Training
- Roboflow Train (cloud-based)
  - Dataset management
  - Annotation
  - Preprocessing
  - Data augmentation  

### IDE / Tooling
- Android Studio 2024.3.1  
- Visual Studio Code (Flutter/Dart)  
- Git & GitHub  

---

## System Requirements

### Android Device (Deployment & Use)
- OS: Android 10 or higher (Android 12 recommended)  
- RAM: Minimum 4 GB (6 GB recommended)  
- Storage: Minimum 16 GB free (64 GB recommended)  
- Camera: At least 8 MP rear camera (12 MP or higher recommended)  

### Development Environment
- OS: Windows 10 (or equivalent)  
- Flutter SDK 3.29.2  
- Dart 3.7.2  
- Android Studio and/or VS Code with Flutter & Dart plugins  
- Git 2.49.0 or later  

---

## Model Training (Optional Local Replication)

Training was performed using Roboflow Train. To replicate locally:

### Hardware
- GPU: NVIDIA GPU with ≥6 GB VRAM (8 GB+ recommended)  
- CPU: Intel i5 / Ryzen 5 or better  
- RAM: ≥16 GB (32 GB recommended)  
- Storage: ≥20 GB free  

### Software
- Python 3.8–3.10  
- PyTorch with Ultralytics YOLOv8  
- CUDA 11.7  
- cuDNN 8.4  

---

## Dataset and Models

- Total Images: 4,784 pharmaceutical packaging images  
  - 761 authentic + counterfeit images from FDA  
  - 3,391 authentic images from licensed pharmacies  
  - 632 counterfeit images from Roboflow public datasets  

### Model Design
- Five independent YOLOv8s models  
- Two classes per model: authentic, counterfeit  
- One model per medicine to handle packaging variation and class imbalance  

### Training Configuration
- Data split:
  - 70% training
  - 15% validation
  - 15% testing (handled by Roboflow)  
- Augmentation:
  - Resizing to 960×960
  - Rotations and flips
  - Brightness and contrast adjustment
  - Blur and noise augmentation  

Models are exported as TorchScript and embedded directly into the Flutter Android app for offline inference.

---

## Installation

### For End Users (APK)

1. Visit the official SafeMed website:  
   **https://websafemed.vercel.app/**

2. Download the latest SafeMed APK from the website.

3. Transfer the APK to your Android device if downloaded from another device.

4. Enable **“Install from unknown sources”** (if prompted by your device).

5. Tap the downloaded APK file and follow the on-screen instructions to install SafeMed.

### For Developers (Build from Source)

#### Clone the Repository
```bash
git clone https://github.com/kurtmaurilumapak/SafeMed.git
```
#### Go to the Project Directory
```bash
cd SafeMed
```
#### Install Dependencies
```bash
flutter pub get
```
#### Run the App
```bash
flutter run
```
#### Build Release APK
```bash
flutter build apk --release
```

## How to Use

### Launch the App
- A loading screen appears while models and resources initialize

### Select a Medicine
- Choose from:
  - Biogesic
  - Alaxan FR
  - Neozep Forte
  - Bioflu
  - Medicol

### Capture Packaging Images
- Capture or upload front and back images of the medicine packaging
- Ensure good lighting and full visibility of the packaging

### Run Detection
- The app displays:
  - **Result:** Authentic, Counterfeit, or Inconclusive
  - **Confidence score (%)**

### Interpret Results
- **Confidence ≥ 75%** → Authentic or Counterfeit
- **Confidence < 75%** → Inconclusive; further verification is advised

### Learn More
- Access the **About / Learning Module** for FDA-based information

---

## Evaluation and Performance

### Usability
- System Usability Scale (SUS) score of **82.4 (Grade A)**
- 20 participants:
  - Consumers
  - Sari-sari store owners
  - Pharmacists

### Detection Speed
- **10–20 seconds per scan** on a mid-range Android device
- Tested on **Infinix Zero 5G** (8 GB RAM, Android 12)

### Accuracy
- YOLOv8s models achieved **mAP between 0.957 and 0.995**

---

## Limitations

- Supports only five OTC medicines
- Performance depends heavily on image quality
- Visual packaging analysis only (no chemical testing)
- New counterfeit variants may reduce accuracy

---

## Legal and Ethical Notes

SafeMed is a consumer-level preliminary verification tool and does not replace laboratory testing, professional judgment, or regulatory enforcement.

The app is developed in alignment with:
- Philippine FDA guidelines
- Special Law on Counterfeit Drugs (**RA 8203**)
- Data Privacy Act of 2012 (**RA 10173**), where applicable

