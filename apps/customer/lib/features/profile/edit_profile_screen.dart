import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameCtrl = TextEditingController(text: MockData.demoUser.name);
  late final _emailCtrl = TextEditingController(text: MockData.demoUser.email);
  late final _phoneCtrl = TextEditingController(text: MockData.demoUser.phone);
  String _gender = 'Male';
  DateTime? _dob;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'))); }, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(radius: 48, backgroundColor: AppTheme.primaryRed, child: Text(_nameCtrl.text[0], style: const TextStyle(color: Colors.white, fontSize: 36))),
                Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 16, backgroundColor: AppTheme.primaryRed, child: IconButton(icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white), onPressed: () {}))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), enabled: false),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date of Birth'),
            subtitle: Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime(1995), firstDate: DateTime(1950), lastDate: DateTime.now());
              if (d != null) setState(() => _dob = d);
            },
          ),
        ],
      ),
    );
  }
}
