import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _monthlyBudget;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget');
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _setMonthlyBudget() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Monthly Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter amount (৳)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('monthly_budget', value);
                setState(() => _monthlyBudget = value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Budget updated successfully!")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_notificationsEnabled;
    await prefs.setBool('notifications_enabled', newValue);
    setState(() => _notificationsEnabled = newValue);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(newValue ? "Notifications enabled" : "Notifications disabled"),
    ));
  }

  Future<void> _changePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldController, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password changed successfully! (Demo only)")),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _setOrUpdatePin() async {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set or Update PIN"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(labelText: "Enter 4-digit PIN"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 4 && int.tryParse(pin) != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_pin', pin);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PIN saved successfully!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid 4-digit PIN")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('user_pin')) {
      await prefs.remove('user_pin');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN removed successfully.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No PIN is set.")),
      );
    }
  }

  Future<void> _confirmReset() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Reset"),
        content: const Text("Delete all your transactions? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.resetAllTransactionsForUser();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All transaction data deleted.")),
              );
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        backgroundColor: const Color(0xFFFDF7F0),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSettingTile(
            icon: Icons.attach_money,
            title: "Set Monthly Budget",
            color: Colors.green,
            onTap: _setMonthlyBudget,
          ),
          _buildSettingTile(
            icon: _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
            title: _notificationsEnabled ? "Disable Notifications" : "Enable Notifications",
            color: Colors.orange,
            onTap: _toggleNotifications,
          ),
          _buildSettingTile(
            icon: Icons.lock,
            title: "Change Password",
            color: Colors.blue,
            onTap: _changePassword,
          ),
          _buildSettingTile(
            icon: Icons.pin,
            title: "Set/Update PIN",
            color: Colors.purple,
            onTap: _setOrUpdatePin,
          ),
          _buildSettingTile(
            icon: Icons.no_encryption_gmailerrorred,
            title: "Remove PIN",
            color: Colors.grey,
            onTap: _removePin,
          ),
          _buildSettingTile(
            icon: Icons.delete_forever,
            title: "Reset All Data",
            color: Colors.red,
            onTap: _confirmReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        leading: Icon(icon, color: color, size: 26.sp),
        title: Text(title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }
}
