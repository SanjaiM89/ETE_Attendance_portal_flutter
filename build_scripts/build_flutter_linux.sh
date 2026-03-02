#!/bin/bash
echo "Building FrontEnd..."
cd /home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/FrontEnd
flutter build linux --release > build_linux_frontend.log 2>&1
echo "FrontEnd exit code: \$?"

echo "Building admin_frontend..."
cd /home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/admin_frontend
flutter build linux --release > build_linux_admin.log 2>&1
echo "admin_frontend exit code: \$?"
