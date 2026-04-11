#!/bin/bash

# Flutter Web Deployment Script
# This script cleans, builds, and deploys the Flutter web application

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "🔨 Building Flutter web (release mode)..."
flutter build web --release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    echo "📦 Adding build files to git..."
    git add -f build/web/
    
    echo "💾 Committing changes..."
    git commit -m "Build: Update web build for deployment"
    
    echo "🚀 Pushing to origin main..."
    git push origin main
    
    echo "✨ Deployment complete!"
else
    echo "❌ Build failed! Deployment aborted."
    exit 1
fi
