import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../pdf_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _name = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserInfo();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('profile_image');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? '';
      _email = prefs.getString('email') ?? '';
      _phone = prefs.getString('phone') ?? '';
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', savedImage.path);

      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  Future<void> _editUserInfo() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.w,
          right: 20.w,
          top: 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Edit Profile Info", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: "Name")),
              TextField(controller: emailController, decoration: const InputDecoration(hintText: "Email")),
              TextField(controller: phoneController, decoration: const InputDecoration(hintText: "Phone")),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString('name', nameController.text.trim());
                      await prefs.setString('email', emailController.text.trim());
                      await prefs.setString('phone', phoneController.text.trim());
                      Navigator.pop(context);
                      _loadUserInfo();
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetProfileInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('profile_image');

    setState(() {
      _name = '';
      _phone = '';
      _profileImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile info reset successfully")),
    );
  }

  Future<void> _exportAsPDFWithFilters() async {
    final categoryOptions = ['All', 'Income', 'Expense'];
    String selectedCategory = 'All';
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Export PDF with Filters", style: TextStyle(fontSize: 16.sp)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: categoryOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                          child: Text(
                            startDate != null
                                ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                                : "Start Date",
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                          child: Text(
                            endDate != null
                                ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                                : "End Date",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final file = await PDFHelper.generateTransactionPdf(
                      user: {
                        'name': _name,
                        'email': _email,
                        'phone': _phone,
                      },
                      categoryFilter: selectedCategory,
                      startDate: startDate,
                      endDate: endDate,
                    );
                    await Printing.sharePdf(
                      bytes: await file.readAsBytes(),
                      filename: file.path.split('/').last,
                    );
                  },
                  child: const Text("Generate PDF"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');

    if (savedPin != null) {
      final TextEditingController pinController = TextEditingController();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("PIN Required"),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: "Enter your 4-digit PIN"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text == savedPin) {
                  await prefs.remove('isLoggedIn');
                  await prefs.remove('email');
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/welcome');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Incorrect PIN")),
                  );
                }
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      );
    } else {
      await prefs.remove('isLoggedIn');
      await prefs.remove('email');
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: Text("Profile", style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage('assets/images/user.png') as ImageProvider,
                        ),
                        SizedBox(height: 8.h),
                        Text("Tap to change photo", style: TextStyle(color: Colors.blue, fontSize: 12.sp)),
                        SizedBox(height: 6.h),
                        Text(_name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        if (_email.isNotEmpty)
                          Text(_email, style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
                        if (_phone.isNotEmpty)
                          Text(_phone, style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                _buildProfileOption(Icons.edit, "Edit Info", _editUserInfo),
                _buildProfileOption(Icons.settings, "Settings", () => Navigator.pushNamed(context, '/settings')),
                _buildProfileOption(Icons.picture_as_pdf, "Export as PDF", _exportAsPDFWithFilters),
                _buildProfileOption(Icons.delete_forever, "Reset Profile Info", _resetProfileInfo, color: Colors.red),
                _buildProfileOption(Icons.logout, "Logout", _logout, color: Colors.redAccent),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 24.sp),
        title: Text(title, style: TextStyle(color: color, fontSize: 14.sp)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
      ),
    );
  }
}
