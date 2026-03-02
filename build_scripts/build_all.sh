#!/bin/bash
set -e

echo "Building FrontEnd (Linux)..."
cd /home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/FrontEnd
flutter build linux --release

echo "Building FrontEnd (APK)..."
flutter build apk --release || echo "APK build failed (is Android SDK configured?)"

echo "Building admin_frontend (Linux)..."
cd /home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/admin_frontend
flutter build linux --release

echo "Building admin_frontend (APK)..."
flutter build apk --release || echo "APK build failed (is Android SDK configured?)"

echo "All builds finished."
