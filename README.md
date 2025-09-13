# 📚 Student Management App

A **Flutter-based Student Management System** with **role-based access control (RBAC)**, designed for schools and colleges.  
It provides a centralized platform to manage **students, staff, fees, and library records** with real-time backend support using **Supabase**.

---

## 🚀 Features

### 👨‍🎓 Student  
- View personal profile and academic details  
- Check **library borrow history**  
- Track **fees status**  

### 👩‍🏫 Staff  
- Create and manage student records  
- Update their own details  
- Limited access compared to Admin  

### 🛠️ Admin  
- Full control over the system  
- Manage **students, staff, library, and fees**  
- Create/update/delete users and records  

---

## 🗄️ Tech Stack
- **Frontend**: Flutter (Dart)  
- **Backend**: Supabase (Postgres + Auth + Storage)  
- **State Management**: Provider  
- **Authentication**: Supabase Auth (Email/Password, RBAC)  

---

## 📂 Modules
- **Authentication**: Login, Reset Password, Session Management  
- **Student Management**: CRUD for students  
- **Library Management**: Book borrowing/return, availability tracking  
- **Fees Management**: Payment history, pending fees  
- **Staff Management**: Staff accounts and permissions  

---

## 🛠️ Setup Instructions
1. Clone the repo  
   ```bash
   git clone https://github.com/your-username/student_management.git
   cd student_management
