require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const readline = require("readline-sync");
const Admin = require("./models/Admin");

async function createAdmin() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ MongoDB Connected\n");

    const name = readline.question("Enter Admin Name: ");
    const email = readline.questionEMail("Enter Admin Email: ");
    const password = readline.question("Enter Admin Password: ", {
      hideEchoBack: true
    });

    const existingAdmin = await Admin.findOne({ email });

    if (existingAdmin) {
      console.log("\n⚠ Admin with this email already exists.");
      process.exit();
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await Admin.create({
      name,
      email,
      password: hashedPassword,
      mfaEnabled: false
    });

    console.log("\n🎉 Admin created successfully!");
    process.exit();

  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

createAdmin();