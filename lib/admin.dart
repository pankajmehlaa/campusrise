import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class AdminScreen extends StatefulWidget {
  final String apiBase;
  const AdminScreen({super.key, required this.apiBase});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String? _token;
  String? _role;
  String? _campusScope;
  String? _userId;
  String? _userName;
  String? _userPhone;
  bool _busy = false;
  String? _error;
  String _activeSection = '';

  String _campusQuery = '';
  String _hallQuery = '';
  String _userQuery = '';

  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  List<dynamic> _campuses = [];
  List<dynamic> _halls = [];
  List<dynamic> _menuItems = [];
  List<dynamic> _users = [];
  Map<String, dynamic>? _contact;

  String? _selectedCampusId;
  String? _selectedHallId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('authToken');
      _role = prefs.getString('authRole');
      _campusScope = prefs.getString('authCampus');
    });
    if (_token != null) {
      await _refreshData();
    }
  }

  Future<void> _saveAuth(String token, String role, String? campusId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('authRole', role);
    await prefs.setString('authCampus', campusId ?? '');
    setState(() {
      _token = token;
      _role = role;
      _campusScope = campusId?.isEmpty == true ? null : campusId;
    });
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('authRole');
    await prefs.remove('authCampus');
    setState(() {
      _token = null;
      _role = null;
      _campusScope = null;
      _userId = null;
      _userName = null;
      _userPhone = null;
      _campuses = [];
      _halls = [];
      _menuItems = [];
      _users = [];
      _contact = null;
    });
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('${widget.apiBase}/auth/login');
        final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
        final phone = '+91$digits';
        final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': phone, 'password': _passCtrl.text}))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        throw Exception('Login failed (${resp.statusCode})');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token == null || user == null) throw Exception('Invalid login response');
      final role = (user['role'] as String?) ?? 'viewer';
      final campusId = user['campusId']?.toString();
      _userId = user['_id']?.toString();
      _userName = user['name']?.toString();
      _userPhone = user['phone']?.toString();
      await _saveAuth(token, role, campusId);
      await _refreshData();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadCampuses(),
      _loadContact(),
      if (_role == 'admin') _loadUsers(),
    ]);
    if (_selectedCampusId == null && _campuses.isNotEmpty) {
      setState(() => _selectedCampusId = _campusScope ?? _campuses.first['_id'].toString());
    }
    if (_selectedCampusId != null) {
      await _loadHalls(_selectedCampusId!);
    }
    if (_selectedHallId != null) {
      await _loadMenu(_selectedHallId!, _selectedDate);
    }
  }

  Future<void> _updateProfileInfo() async {
    if (_userId == null) return;
    final nameCtrl = TextEditingController(text: _userName ?? '');
    final phoneCtrl = TextEditingController(text: (_userPhone ?? '').replaceAll('+91', ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (10 digits)'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final phone = '+91${phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}';
    await http.put(Uri.parse('${widget.apiBase}/users/$_userId'),
        headers: _authHeaders,
        body: jsonEncode({'name': nameCtrl.text.trim(), 'phone': phone}));
    _userName = nameCtrl.text.trim();
    _userPhone = phone;
    setState(() {});
  }

  Future<void> _updateProfilePassword() async {
    if (_userId == null) return;
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'New password'), obscureText: true),
            TextField(controller: confirmCtrl, decoration: const InputDecoration(labelText: 'Confirm password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok != true) return;
    if (passCtrl.text.trim() != confirmCtrl.text.trim() || passCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must match and be 6+ chars')));
      return;
    }
    await http.put(Uri.parse('${widget.apiBase}/users/$_userId'),
        headers: _authHeaders,
        body: jsonEncode({'password': passCtrl.text.trim()}));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
  }

  Future<void> _loadCampuses() async {
    final uri = Uri.parse('${widget.apiBase}/campuses');
    final resp = await http.get(uri, headers: _authHeaders);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      setState(() {
        _campuses = data;
        if (_campusScope != null) {
          _campuses = data.where((c) => c['_id'] == _campusScope).toList();
        }
      });
    }
  }

  Future<void> _loadHalls(String campusId) async {
    final uri = Uri.parse('${widget.apiBase}/halls?campusId=$campusId');
    final resp = await http.get(uri, headers: _authHeaders);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      setState(() {
        _halls = data;
        _selectedHallId = data.isNotEmpty ? data.first['_id'].toString() : null;
      });
    }
  }

  Future<void> _loadMenu(String hallId, DateTime date) async {
    final ds = date.toIso8601String().split('T').first;
    final uri = Uri.parse('${widget.apiBase}/menu?hallId=$hallId&date=$ds');
    final resp = await http.get(uri, headers: _authHeaders);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      setState(() => _menuItems = data);
    }
  }

  Future<void> _loadUsers() async {
    final uri = Uri.parse('${widget.apiBase}/users');
    final resp = await http.get(uri, headers: _authHeaders);
    if (resp.statusCode == 200) {
      setState(() => _users = jsonDecode(resp.body) as List<dynamic>);
    }
  }

  Future<void> _loadContact() async {
    final uri = Uri.parse('${widget.apiBase}/contact');
    final resp = await http.get(uri, headers: _authHeaders);
    if (resp.statusCode == 200) {
      setState(() => _contact = jsonDecode(resp.body) as Map<String, dynamic>);
    }
  }

  Future<void> _createCampus() async {
    final name = await _promptText('Campus name');
    if (name == null || name.isEmpty) return;
    final uri = Uri.parse('${widget.apiBase}/campuses');
    await http.post(uri, headers: _authHeaders, body: jsonEncode({'name': name}));
    await _loadCampuses();
  }

  Future<void> _createHall() async {
    if (_selectedCampusId == null) return;
    final name = await _promptText('Hall name');
    if (name == null || name.isEmpty) return;
    final uri = Uri.parse('${widget.apiBase}/halls');
    final resp = await http.post(uri, headers: _authHeaders, body: jsonEncode({'name': name, 'campusId': _selectedCampusId}));
    if (resp.statusCode == 201) {
      final created = jsonDecode(resp.body) as Map<String, dynamic>;
      final hallId = created['_id']?.toString();
      await _loadHalls(_selectedCampusId!);
      if (hallId != null) {
        await _seedDefaultMealsForHall(hallId);
        _selectedHallId = hallId;
        await _loadMenu(hallId, _selectedDate);
      }
    }
  }

  Future<void> _seedDefaultMealsForHall(String hallId) async {
    final date = DateTime.now();
    final ds = date.toIso8601String().split('T').first;
    const defaults = [
      {'mealType': 'breakfast', 'title': 'Breakfast', 'subtitle': 'Add items', 'timeRange': '7:30 - 9:30 AM'},
      {'mealType': 'lunch', 'title': 'Lunch', 'subtitle': 'Add items', 'timeRange': '12:30 - 2:30 PM'},
      {'mealType': 'snacks', 'title': 'Snacks', 'subtitle': 'Add items', 'timeRange': '5:00 - 6:30 PM'},
      {'mealType': 'dinner', 'title': 'Dinner', 'subtitle': 'Add items', 'timeRange': '7:30 - 9:30 PM'},
    ];
    for (final m in defaults) {
      await http.post(Uri.parse('${widget.apiBase}/menu'),
          headers: _authHeaders,
          body: jsonEncode({
            'hallId': hallId,
            'date': ds,
            'mealType': m['mealType'],
            'title': m['title'],
            'subtitle': m['subtitle'],
            'timeRange': m['timeRange'],
          }));
    }
  }

  Future<void> _createOrEditMenuItem({Map<String, dynamic>? existing}) async {
    if (_selectedHallId == null && existing == null) return;
    final hallId = existing?['hallId']?.toString() ?? _selectedHallId!;
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final subtitleCtrl = TextEditingController(text: existing?['subtitle']?.toString() ?? '');
    final timeCtrl = TextEditingController(text: existing?['timeRange']?.toString() ?? '');
    String mealType = existing?['mealType']?.toString() ?? 'breakfast';
    final picked = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Add menu' : 'Edit menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time range')),
              DropdownButton<String>(
                value: mealType,
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'snacks', child: Text('Snacks')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                ],
                onChanged: (v) => mealType = v ?? mealType,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      },
    );
    if (picked != true) return;
    final ds = _selectedDate.toIso8601String().split('T').first;
    if (existing == null) {
      await http.post(Uri.parse('${widget.apiBase}/menu'),
          headers: _authHeaders,
          body: jsonEncode({
            'hallId': hallId,
            'date': ds,
            'mealType': mealType,
            'title': titleCtrl.text.trim(),
            'subtitle': subtitleCtrl.text.trim(),
            'timeRange': timeCtrl.text.trim(),
          }));
    } else {
      await http.put(Uri.parse('${widget.apiBase}/menu/${existing['_id']}'),
          headers: _authHeaders,
          body: jsonEncode({
            'mealType': mealType,
            'title': titleCtrl.text.trim(),
            'subtitle': subtitleCtrl.text.trim(),
            'timeRange': timeCtrl.text.trim(),
          }));
    }
    await _loadMenu(hallId, _selectedDate);
  }

  Future<void> _deleteMenuItem(String id) async {
    final uri = Uri.parse('${widget.apiBase}/menu/$id');
    await http.delete(uri, headers: _authHeaders);
    if (_selectedHallId != null) {
      await _loadMenu(_selectedHallId!, _selectedDate);
    }
  }

  Future<void> _deleteCampus(String id) async {
    final uri = Uri.parse('${widget.apiBase}/campuses/$id');
    await http.delete(uri, headers: _authHeaders);
    await _loadCampuses();
  }

  Future<void> _deleteHall(String id) async {
    final uri = Uri.parse('${widget.apiBase}/halls/$id');
    await http.delete(uri, headers: _authHeaders);
    if (_selectedCampusId != null) await _loadHalls(_selectedCampusId!);
  }

  Future<void> _updateContact() async {
    final emailCtrl = TextEditingController(text: _contact?['email']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _contact?['phone']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: _contact?['address']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Support email')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Support phone')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final uri = Uri.parse('${widget.apiBase}/contact');
    await http.put(uri,
        headers: _authHeaders,
        body: jsonEncode({'email': emailCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'address': addressCtrl.text.trim()}));
    await _loadContact();
  }

  Future<void> _createUser() async {
    if (_role != 'admin') return;
    final name = await _promptText('Name');
    if (name == null || name.isEmpty) return;
    final phoneInput = await _promptText('Phone (10 digits, India)');
    if (phoneInput == null || phoneInput.isEmpty) return;
    final phone = '+91${phoneInput.replaceAll(RegExp(r'\D'), '')}';
    final password = await _promptText('Password (min 6)');
    if (password == null || password.length < 6) return;
    final role = await _promptChoice('Role', ['admin', 'manager', 'viewer']);
    if (role == null) return;
    String? campusId;
    if (role == 'manager') {
      campusId = await _promptChoice('Assign campus', _campuses.map((e) => e['_id'].toString()).toList(),
          labels: _campuses.map((e) => e['name'].toString()).toList());
    }
    final uri = Uri.parse('${widget.apiBase}/users');
    await http.post(uri,
      headers: _authHeaders,
      body: jsonEncode({'name': name, 'phone': phone, 'password': password, 'role': role, 'campusId': campusId}));
    await _loadUsers();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    if (_role != 'admin') return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete ${user['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(Uri.parse('${widget.apiBase}/users/${user['_id']}'), headers: _authHeaders);
      await _loadUsers();
    }
  }

  Future<void> _editCampus(Map<String, dynamic> campus) async {
    if (_role != 'admin') return;
    final ctrl = TextEditingController(text: campus['name']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit campus'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Campus name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    await http.put(Uri.parse('${widget.apiBase}/campuses/${campus['_id']}'), headers: _authHeaders, body: jsonEncode({'name': ctrl.text.trim()}));
    await _loadCampuses();
  }

  Future<void> _editHall(Map<String, dynamic> hall) async {
    final ctrl = TextEditingController(text: hall['name']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit hall'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Hall name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    await http.put(Uri.parse('${widget.apiBase}/halls/${hall['_id']}'), headers: _authHeaders, body: jsonEncode({'name': ctrl.text.trim(), 'campusId': hall['campusId']}));
    if (_selectedCampusId != null) await _loadHalls(_selectedCampusId!);
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    if (_role != 'admin') return;
    final nameCtrl = TextEditingController(text: user['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user['phone']?.toString().replaceAll('+91', '') ?? '');
    final pwdCtrl = TextEditingController();
    String role = user['role']?.toString() ?? 'viewer';
    String? campusId = user['campusId']?.toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit user'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (10 digits)', prefixText: '+91 '), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            TextField(controller: pwdCtrl, decoration: const InputDecoration(labelText: 'New password (optional)'), obscureText: true),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: (v) => role = v ?? role,
            ),
            if (role == 'manager')
              DropdownButton<String>(
                value: campusId,
                hint: const Text('Assign campus'),
                items: _campuses
                    .map((c) => DropdownMenuItem<String>(value: c['_id'].toString(), child: Text(c['name'].toString())))
                    .toList(),
                onChanged: (v) => campusId = v,
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final body = {
      'name': nameCtrl.text.trim(),
      'phone': '+91${phoneCtrl.text.replaceAll(RegExp(r'\\D'), '')}',
      'role': role,
      'campusId': campusId,
    };
    if (pwdCtrl.text.isNotEmpty) body['password'] = pwdCtrl.text;
    await http.put(Uri.parse('${widget.apiBase}/users/${user['_id']}'), headers: _authHeaders, body: jsonEncode(body));
    await _loadUsers();
  }

  Future<String?> _promptText(String label, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<String?> _promptChoice(String label, List<String> values, {List<String>? labels}) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(label),
        children: values.asMap().entries.map((entry) {
          final idx = entry.key;
          final v = entry.value;
          final text = labels != null && labels.length > idx ? labels[idx] : v;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, v),
            child: Text(text),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return _buildLogin();
    }
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Role: ${_role ?? '-'}', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(onPressed: _clearAuth, icon: const Icon(Icons.logout), label: const Text('Logout')),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionCards(),
          const SizedBox(height: 12),
          _buildContextPanel(),
          const SizedBox(height: 12),
          _buildActiveSection(),
        ],
      ),
    );
  }

  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Admin Login', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone', prefixText: '+91 '),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _login,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ]
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }

  Widget _buildPickers() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose college and mess to manage', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButton<String?>(
            isExpanded: true,
            value: _selectedCampusId,
            hint: const Text('Select college'),
            items: _campuses.map((c) => DropdownMenuItem(value: c['_id'].toString(), child: Text(c['name'].toString()))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedCampusId = v;
                _selectedHallId = null;
              });
              if (v != null) _loadHalls(v);
            },
          ),
          const SizedBox(height: 8),
          DropdownButton<String?>(
            isExpanded: true,
            value: _selectedHallId,
            hint: const Text('Select mess'),
            items: _halls.map((h) => DropdownMenuItem(value: h['_id'].toString(), child: Text(h['name'].toString()))).toList(),
            onChanged: (v) {
              setState(() => _selectedHallId = v);
              if (v != null) _loadMenu(v, _selectedDate);
            },
          ),
          const SizedBox(height: 4),
          Text('Tip: select college first, then mess. Managers see only their college.', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _buildContextPanel() {
    if (_activeSection == 'halls' || _activeSection == 'menu') {
      return _buildPickers();
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF374C8D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _activeSection.isEmpty
                    ? 'Select an area below to manage. Data panels will appear once you choose.'
                    : 'Use the cards to navigate between sections. Contextual pickers will show up when needed.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    final cards = <Map<String, dynamic>>[];
    final hasCampus = _selectedCampusId != null;
    final hasHall = _selectedHallId != null;
    if (_role == 'admin') {
      cards.addAll([
        {'id': 'users', 'title': 'Manage users', 'enabled': true},
        {'id': 'campuses', 'title': 'List colleges', 'enabled': true},
        {'id': 'halls', 'title': 'Manage messes', 'enabled': hasCampus, 'helper': hasCampus ? null : 'Select a college first'},
        {'id': 'menu', 'title': 'Manage menu items', 'enabled': hasHall, 'helper': hasHall ? null : 'Select a mess first'},
        {'id': 'contact', 'title': 'Contact info', 'enabled': true},
      ]);
    } else {
      cards.addAll([
        {'id': 'halls', 'title': 'Manage messes', 'enabled': hasCampus, 'helper': hasCampus ? null : 'Select a college first'},
        {'id': 'menu', 'title': 'Manage menu items', 'enabled': hasHall, 'helper': hasHall ? null : 'Select a mess first'},
        {'id': 'contact', 'title': 'Contact info', 'enabled': true},
      ]);
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) {
        final active = _activeSection == c['id'];
        final enabled = c['enabled'] as bool;
        return GestureDetector(
          onTap: enabled ? () => setState(() => _activeSection = c['id'].toString()) : null,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled ? (active ? const Color(0xFF374C8D) : Colors.white) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? const Color(0xFF374C8D) : Colors.grey.shade300),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['title'], style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
              if (c['helper'] != null) ...[
                const SizedBox(height: 6),
                Text(c['helper'].toString(), style: TextStyle(color: active ? Colors.white70 : Colors.black54, fontSize: 12)),
              ],
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeSection) {
      case 'campuses':
        return _buildSection('Colleges', _buildCampusesSection());
      case 'halls':
        return _buildSection('Messes', _buildHallsSection());
      case 'menu':
        return _buildSection('Menu Items', _buildMenuSection());
      case 'users':
        return _role == 'admin' ? _buildSection('Users', _buildUsersSection()) : const SizedBox.shrink();
      case 'contact':
        return _buildSection('Contact Info', _buildContactSection());
      case 'profile':
        return _buildSection('My Profile', _buildProfileSection());
      default:
        return _buildSection('Choose action', const Text('Pick a card above to manage.'));
    }
  }

  Widget _buildCampusesSection() {
    final filtered = _campuses.where((c) => c['name'].toString().toLowerCase().contains(_campusQuery.toLowerCase())).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search colleges'),
                onChanged: (v) => setState(() => _campusQuery = v),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: _role == 'admin' ? _createCampus : null, icon: const Icon(Icons.add), label: const Text('Add college')),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Actions')),
          ], rows: filtered.map((c) {
            return DataRow(cells: [
              DataCell(Text(c['name'].toString()), onTap: () {
                setState(() => _selectedCampusId = c['_id'].toString());
                _loadHalls(_selectedCampusId!);
              }),
              DataCell(Text(c['_id'].toString())),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCampus(c)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCampus(c['_id'].toString())),
              ])),
            ]);
          }).toList()),
        ),
      ],
    );
  }

  Widget _buildHallsSection() {
    if (_selectedCampusId == null) return const Text('Select a college first');
    final filtered = _halls.where((h) => h['name'].toString().toLowerCase().contains(_hallQuery.toLowerCase())).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search messes'),
                onChanged: (v) => setState(() => _hallQuery = v),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: _createHall, icon: const Icon(Icons.add), label: const Text('Add mess')),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Actions')),
          ], rows: filtered.map((h) {
            return DataRow(cells: [
              DataCell(Text(h['name'].toString()), onTap: () {
                setState(() => _selectedHallId = h['_id'].toString());
                _loadMenu(_selectedHallId!, _selectedDate);
              }),
              DataCell(Text(h['_id'].toString())),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editHall(h)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHall(h['_id'].toString())),
              ])),
            ]);
          }).toList()),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    if (_selectedHallId == null) return const Text('Select a hall');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(onPressed: () => _createOrEditMenuItem(), icon: const Icon(Icons.add), label: const Text('Add menu')),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _loadMenu(_selectedHallId!, _selectedDate);
                }
              },
              child: Text('Date: ${_selectedDate.toIso8601String().split('T').first}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._menuItems.map((m) => ListTile(
              title: Text('${m['mealType']}: ${m['title']}'),
              subtitle: Text(m['timeRange']?.toString() ?? ''),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _createOrEditMenuItem(existing: m)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMenuItem(m['_id'].toString())),
              ]),
            )),
      ],
    );
  }

  Widget _buildUsersSection() {
    final filtered = _users.where((u) {
      final q = _userQuery.toLowerCase();
      return u['name'].toString().toLowerCase().contains(q) || u['phone'].toString().toLowerCase().contains(q) || u['role'].toString().toLowerCase().contains(q);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search users'),
                onChanged: (v) => setState(() => _userQuery = v),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: _createUser, icon: const Icon(Icons.add), label: const Text('Add user')),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Campus')),
            DataColumn(label: Text('Actions')),
          ], rows: filtered.map((u) {
            return DataRow(cells: [
              DataCell(Text(u['name'].toString())),
              DataCell(Text(u['phone'].toString())),
              DataCell(Text(u['role'].toString())),
              DataCell(Text(u['campusId']?.toString() ?? '-')),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editUser(u)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(u)),
              ])),
            ]);
          }).toList()),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role: ${_role ?? '-'}'),
        Text('Name: ${_userName ?? '-'}'),
        Text('Phone: ${_userPhone ?? '-'}'),
        Text('Campus scope: ${_campusScope ?? 'All'}'),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(onPressed: _updateProfileInfo, icon: const Icon(Icons.person_outline), label: const Text('Update info')),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: _updateProfilePassword, icon: const Icon(Icons.lock_outline), label: const Text('Change password')),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    if (_contact == null) return const Text('Loading contact info...');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email: ${_contact!['email']}'),
        Text('Phone: ${_contact!['phone']}'),
        Text('Address: ${_contact!['address']}'),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: _updateContact, icon: const Icon(Icons.edit), label: const Text('Edit contact')),
      ],
    );
  }
}
