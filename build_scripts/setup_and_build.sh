#!/bin/bash
set -e

echo "Setting up FrontEnd..."
cd /home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/FrontEnd
flutter config --enable-linux-desktop
flutter create --platforms=linux .
echo "Building FrontEnd Linux..."
flutter build linux --release > build_linux_frontend.log 2>&1
echo "FrontEnd built."

echo "Setting up admin_frontend..."
cd /home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/admin_frontend
flutter config --enable-linux-desktop
flutter create --platforms=linux .
echo "Building admin_frontend Linux..."
flutter build linux --release > build_linux_admin.log 2>&1
echo "admin_frontend built."
