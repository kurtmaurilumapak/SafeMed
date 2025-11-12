#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Set Flutter installation directory (using a cacheable location)
FLUTTER_HOME="$HOME/.flutter"

# Install Flutter if not already installed
if [ ! -d "$FLUTTER_HOME" ] || [ ! -f "$FLUTTER_HOME/bin/flutter" ]; then
  echo "📦 Installing Flutter..."
  
  # Download Flutter SDK (shallow clone for faster download)
  if [ ! -d "$FLUTTER_HOME" ]; then
    echo "⬇️  Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_HOME
  fi
fi

# Add Flutter to PATH
export PATH="$FLUTTER_HOME/bin:$PATH"

# Verify Flutter is accessible
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter installation failed"
  exit 1
fi

# Enable Flutter web (idempotent, safe to run multiple times)
flutter config --enable-web --no-analytics

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️  Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build completed successfully!"

