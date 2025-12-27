import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

IconData _iconForMeal(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return Icons.wb_sunny_outlined;
    case 'lunch':
      return Icons.restaurant;
    case 'snacks':
      return Icons.local_cafe_outlined;
    case 'dinner':
      return Icons.nightlight_round;
    default:
      return Icons.restaurant_menu;
  }
}

Color _colorForMeal(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return const Color(0xFFf7b733);
    case 'lunch':
      return const Color(0xFF4CAF50);
    case 'snacks':
      return const Color(0xFF3FA7F2);
    case 'dinner':
      return const Color(0xFF9C27B0);
    default:
      return const Color(0xFF374C8D);
  }
}

class MealInfo {
  final String id;
  final String mealType;
  final String title;
  final String subtitle;
  final String time;
  final int likes;
  final double rating;
  final int ratingCount;
  final IconData icon;
  final Color iconColor;
  final bool highlighted;

  const MealInfo({
    required this.id,
    required this.mealType,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.likes,
    required this.rating,
    required this.ratingCount,
    required this.icon,
    required this.iconColor,
    required this.highlighted,
  });

  factory MealInfo.fromJson(Map<String, dynamic> json) {
    final mealType = (json['mealType'] as String? ?? '').toLowerCase();
    final timeRange = json['timeRange'] as String? ?? '';
    final icon = _iconForMeal(mealType);
    final color = _colorForMeal(mealType);
    final ratingVal = (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0;
    final ratingCountVal = (json['ratingCount'] is num) ? (json['ratingCount'] as num).toInt() : 0;
    final likesVal = (json['likes'] is num) ? (json['likes'] as num).toInt() : 0;
    return MealInfo(
      id: json['_id']?.toString() ?? '',
      mealType: mealType,
      title: json['title'] as String? ?? 'Meal',
      subtitle: json['subtitle'] as String? ?? '',
      time: timeRange,
      likes: likesVal,
      rating: ratingVal,
      ratingCount: ratingCountVal,
      icon: icon,
      iconColor: color,
      highlighted: mealType == 'dinner',
    );
  }

  MealInfo copyWith({
    int? likes,
    double? rating,
    int? ratingCount,
  }) {
    return MealInfo(
      id: id,
      mealType: mealType,
      title: title,
      subtitle: subtitle,
      time: time,
      likes: likes ?? this.likes,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      icon: icon,
      iconColor: iconColor,
      highlighted: highlighted,
    );
  }
}

class ContactInfo {
  final String email;
  final String phone;
  final String address;

  const ContactInfo({required this.email, required this.phone, required this.address});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E2A58), Color(0xFF30457A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: 0.85 + 0.15 * _scale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CampusRise',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Campus dining, simplified',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.3,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CampusOption {
  final String id;
  final String name;

  const CampusOption({required this.id, required this.name});

  factory CampusOption.fromJson(Map<String, dynamic> json) {
    return CampusOption(id: json['_id']?.toString() ?? '', name: json['name'] as String? ?? '');
  }
}

class HallOption {
  final String id;
  final String name;
  final String campusId;

  const HallOption({required this.id, required this.name, required this.campusId});

  factory HallOption.fromJson(Map<String, dynamic> json) {
    return HallOption(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      campusId: json['campusId']?.toString() ?? '',
    );
  }
}

class StaffUser {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String? campusId;

  const StaffUser({required this.id, required this.name, required this.phone, required this.role, this.campusId});

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      campusId: json['campusId']?.toString(),
    );
  }
}

class DateTab {
  final String label;
  final String date;
  final DateTime value;

  const DateTab({required this.label, required this.date, required this.value});
}

Future<String> _loadApiBaseFromConfig() async {
  final configUrl = dotenv.env['CONFIG_URL'];
  final fallback = dotenv.env['API_BASE']?.trim();

  if (configUrl != null && configUrl.isNotEmpty) {
    try {
      final uri = Uri.parse(configUrl);
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final fromConfig = (data['api_base'] as String?)?.trim();
        if (fromConfig != null && fromConfig.isNotEmpty) return fromConfig;
      }
    } catch (_) {
      // ignore and fallback
    }
  }

  return fallback ?? '';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF374C8D),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  final apiBase = await _loadApiBaseFromConfig();
  runApp(MyApp(apiBase: apiBase));
}

class MyApp extends StatelessWidget {
  final String apiBase;

  const MyApp({super.key, required this.apiBase});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusRise',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF374C8D),
          secondary: const Color(0xFFF8C23D),
        ),
        textTheme: baseTheme.textTheme,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF374C8D),
          foregroundColor: Colors.white,
        ),
      ),
      home: AppRoot(apiBase: apiBase),
    );
  }
}

class AppRoot extends StatefulWidget {
  final String apiBase;

  const AppRoot({super.key, required this.apiBase});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();
    return HomeScreen(apiBase: widget.apiBase);
  }
}

class HomeScreen extends StatefulWidget {
  final String apiBase;

  const HomeScreen({super.key, required this.apiBase});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final String _apiBase = widget.apiBase;

  int selectedDay = 0;
  int _tabIndex = 0;
  final ScrollController _dateScrollController = ScrollController();

  String? _authToken;
  String? _authRole;
  String? _authCampusId;
  String? _authUserId;
  String? _authName;
  String? _authPhone;
  bool _authBusy = false;

  int? _settingsTapCount;
  bool _settingsUnlocked = false;
  bool _settingsTapGuard = false;

  bool get _canEdit => _authRole == 'manager' || _authRole == 'admin';
  bool get _showStaffSettings => _authToken != null || _settingsUnlocked;
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  List<DateTab> dates = [];
  List<CampusOption> campuses = [];
  List<HallOption> halls = [];
  List<MealInfo> meals = [];
  Set<String> _likedMealIds = {};
  ContactInfo? contactInfo;
  List<StaffUser>? _users;
  bool _usersLoading = false;
  String? _usersError;

  String? selectedCampusId;
  String? selectedHallId;

  bool loading = true;
  bool menuLoading = false;
  bool contactLoading = true;
  String? errorMessage;

  bool get _isManager => (_authRole ?? '').toLowerCase() == 'manager';

  late Timer _clockTimer;
  late DateTime _nowIst;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buildDateTabs();

    _nowIst = _nowInIst();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _nowIst = _nowInIst();
      });
    });

    _loadAuthThenData();
    _loadLikes();
    _loadContact();
  }

  Future<void> _pickAnyDate() async {
    final initial = dates.isNotEmpty ? dates[selectedDay].value : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDay = 0;
        _buildDateTabs(picked);
      });
      final hallId = selectedHallId;
      if (hallId != null) {
        await _loadMenuForHall(hallId, picked);
      }
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<void> _copyMenuDialog() async {
    if (!_canEdit) return;
    if (selectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a mess first')));
      return;
    }

    DateTime fromDate = dates.isNotEmpty ? dates[selectedDay].value : DateTime.now();
    DateTime toDate = fromDate.add(const Duration(days: 7));
    final daysCtrl = TextEditingController(text: '7');

    String _fmtPlain(DateTime dt) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day} ${dt.year}';
    }

    List<String> rangeLabel(DateTime start, int days) {
      if (days <= 0) return [_fmtPlain(start), _fmtPlain(start)];
      final end = start.add(Duration(days: days - 1));
      return [_fmtPlain(start), _fmtPlain(end)];
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Copy menu to future'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.warning_amber_outlined, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Copying will overwrite menu items for the target dates (same meal types). Likes/ratings reset.',
                          style: TextStyle(color: Color(0xFF7A4F00)),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: daysCtrl,
                  decoration: const InputDecoration(labelText: 'Number of days to copy'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setStateDialog(() {}),
                ),
                const SizedBox(height: 12),
                Text('Source start date', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                TextButton.icon(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  onPressed: () async {
                    final picked = await _pickDate(ctx, fromDate);
                    if (picked != null) {
                      setStateDialog(() => fromDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_formatDate(fromDate)),
                ),
                const SizedBox(height: 8),
                Text('Target start date', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                TextButton.icon(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  onPressed: () async {
                    final picked = await _pickDate(ctx, toDate);
                    if (picked != null) {
                      setStateDialog(() => toDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_formatDate(toDate)),
                ),
                const SizedBox(height: 10),
                Builder(builder: (_) {
                  final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
                  if (days <= 0) return const SizedBox.shrink();
                  final src = rangeLabel(fromDate, days);
                  final dst = rangeLabel(toDate, days);
                  const redStyle = TextStyle(color: Colors.red, fontWeight: FontWeight.w700);
                  const normalStyle = TextStyle(color: Color(0xFF0A2E5C));
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: normalStyle,
                        children: [
                          const TextSpan(text: 'Menus from '),
                          TextSpan(text: src[0], style: redStyle),
                          const TextSpan(text: ' to '),
                          TextSpan(text: src[1], style: redStyle),
                          const TextSpan(text: ' will copy to '),
                          TextSpan(text: dst[0], style: redStyle),
                          const TextSpan(text: ' to '),
                          TextSpan(text: dst[1], style: redStyle),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Copy')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
    if (days <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter number of days to copy')));
      return;
    }

    try {
      await http.post(Uri.parse('$_apiBase/menu/copy'),
          headers: _authHeaders,
          body: jsonEncode({
            'hallId': selectedHallId,
            'fromDate': _formatApiDate(fromDate),
            'toDate': _formatApiDate(toDate),
            'days': days,
          }));
      _showSuccess('Menu copied');
      final hallId = selectedHallId;
      if (hallId != null) {
        await _loadMenuForHall(hallId, dates[selectedDay].value);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copy failed: $e')));
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _clockTimer.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuthThenData() async {
    await _loadSavedAuth();
    if (_authToken != null) {
      await _ensureAuthUserLoaded();
    }
    await _loadInitialData();
  }

  Future<void> _loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('staffToken');
      _authRole = prefs.getString('staffRole');
      final campus = prefs.getString('staffCampus');
      _authCampusId = campus?.isEmpty == true ? null : campus;
      _authUserId = prefs.getString('staffUserId');
      _authName = prefs.getString('staffName');
      _authPhone = prefs.getString('staffPhone');
    });
  }

  DateTime _nowInIst() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute:$second $ampm';
  }

  String _formatDate(DateTime time) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[time.weekday % 7];
    final monthName = months[time.month - 1];
    return '$dayName, $monthName ${time.day}';
  }

  void _buildDateTabs([DateTime? start]) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final base = (start ?? DateTime.now()).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final now = DateTime.now();
    final isTodayBase = base.year == now.year && base.month == now.month && base.day == now.day;
    dates = List.generate(7, (index) {
      final dt = base.add(Duration(days: index));
      final label = (index == 0 && isTodayBase) ? 'Today' : days[dt.weekday % 7];
      final dateLabel = '${months[dt.month - 1]} ${dt.day}';
      return DateTab(label: label, date: dateLabel, value: dt);
    });
  }

  String _formatApiDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _campusNameById(String? id) {
    if (id == null) return '-';
    final campus = campuses.firstWhere((c) => c.id == id, orElse: () => CampusOption(id: id, name: '-'));
    return campus.name.isEmpty ? '-' : campus.name;
  }

  void _showSuccess(String message, {BuildContext? ctx}) {
    final messenger = ScaffoldMessenger.maybeOf(ctx ?? context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _ensureAuthUserLoaded() async {
    await _refreshAuthUser();
  }

  Future<bool> _refreshAuthUser() async {
    if (_authToken == null) return false;
    try {
      for (final path in ['/auth/me', '/users/me']) {
        final resp = await http.get(Uri.parse('$_apiBase$path'), headers: _authHeaders);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final user = data['user'] as Map<String, dynamic>? ?? data;
          final userId = (user['_id'] ?? user['id'])?.toString();
          final name = user['name']?.toString();
          final phone = user['phone']?.toString();
          final prefs = await SharedPreferences.getInstance();
          if (userId != null) await prefs.setString('staffUserId', userId);
          if (name != null) await prefs.setString('staffName', name);
          if (phone != null) await prefs.setString('staffPhone', phone);
          setState(() {
            _authUserId = userId ?? _authUserId;
            _authName = name ?? _authName;
            _authPhone = phone ?? _authPhone;
          });
          return true;
        }
      }
    } catch (_) {
      // ignore network errors; caller will handle failure
    }
    return _authUserId != null;
  }

  Future<void> _editProfileInfo() async {
    if (_authToken == null) return;
    final okUser = await _refreshAuthUser();
    if (_authUserId == null || !okUser) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session invalid. Please log in again.')));
      return;
    }
    final nameCtrl = TextEditingController(text: _authName ?? '');
    final phoneCtrl = TextEditingController(text: (_authPhone ?? '').replaceAll('+91', ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (10 digits)', prefixText: '+91 '), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
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
    await http.put(Uri.parse('$_apiBase/users/${_authUserId}'), headers: _authHeaders, body: jsonEncode({'name': nameCtrl.text.trim(), 'phone': phone}));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffName', nameCtrl.text.trim());
    await prefs.setString('staffPhone', phone);
    setState(() {
      _authName = nameCtrl.text.trim();
      _authPhone = phone;
    });
    _showSuccess('Profile updated');
  }

  Future<void> _changeProfilePassword() async {
    if (_authToken == null) return;
    final okUser = await _refreshAuthUser();
    if (!okUser || _authUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session invalid. Please log in again.')));
      return;
    }
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;
    bool showPass = false;
    bool showConfirm = false;
    bool localBusy = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          Future<void> submit() async {
            final pass = passCtrl.text.trim();
            final confirm = confirmCtrl.text.trim();
            if (pass.length < 6) {
              setLocalState(() => errorText = 'Password must be at least 6 characters');
              return;
            }
            if (pass != confirm) {
              setLocalState(() => errorText = 'Passwords must match');
              return;
            }
            setLocalState(() {
              errorText = null;
              localBusy = true;
            });
            if (mounted) setState(() => _authBusy = true);
            try {
              await http.put(Uri.parse('$_apiBase/users/${_authUserId}'), headers: _authHeaders, body: jsonEncode({'password': pass}));
              if (mounted) _showSuccess('Password updated');
              Navigator.of(ctx, rootNavigator: true).pop(true);
            } catch (e) {
              setLocalState(() => errorText = 'Update failed: $e');
            } finally {
              setLocalState(() => localBusy = false);
              if (mounted) setState(() => _authBusy = false);
            }
          }

          return AlertDialog(
            title: const Text('Change password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: IconButton(
                      icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocalState(() => showPass = !showPass),
                    ),
                  ),
                  obscureText: !showPass,
                ),
                TextField(
                  controller: confirmCtrl,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocalState(() => showConfirm = !showConfirm),
                    ),
                  ),
                  obscureText: !showConfirm,
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: localBusy ? null : submit, child: localBusy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _staffLogin() async {
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? errorText;
    bool showPassword = false;
    bool localBusy = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          Future<void> attemptLogin() async {
            final phoneDigits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
            if (phoneDigits.length != 10) {
              setLocalState(() => errorText = 'Enter a 10-digit phone number');
              return;
            }
            if (passCtrl.text.trim().length < 4) {
              setLocalState(() => errorText = 'Password must be at least 4 characters');
              return;
            }
            setLocalState(() {
              errorText = null;
              localBusy = true;
            });
            if (mounted) setState(() => _authBusy = true);
            try {
              final phone = '+91$phoneDigits';
              final resp = await http.post(Uri.parse('$_apiBase/auth/login'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'phone': phone, 'password': passCtrl.text}));
              if (resp.statusCode != 200) throw Exception('Invalid credentials');
              final data = jsonDecode(resp.body) as Map<String, dynamic>;
              final token = data['token']?.toString();
              final user = data['user'] as Map<String, dynamic>?;
              if (token == null || user == null) throw Exception('Invalid response');
              final role = user['role']?.toString();
              final campusId = user['campusId']?.toString();
              final userId = (user['_id'] ?? user['id'])?.toString();
              final name = user['name']?.toString();
              final userPhone = user['phone']?.toString();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('staffToken', token);
              await prefs.setString('staffRole', role ?? '');
              await prefs.setString('staffCampus', campusId ?? '');
              if (userId != null) await prefs.setString('staffUserId', userId);
              if (name != null) await prefs.setString('staffName', name);
              if (userPhone != null) await prefs.setString('staffPhone', userPhone);
              if (mounted) {
                setState(() {
                  _authToken = token;
                  _authRole = role;
                  _authCampusId = campusId?.isEmpty == true ? null : campusId;
                  _authUserId = userId;
                  _authName = name;
                  _authPhone = userPhone;
                });
                await _loadInitialData();
              }
              Navigator.of(ctx, rootNavigator: true).pop(true);
            } catch (e) {
              setLocalState(() => errorText = 'Login failed: ${e.toString().replaceAll('Exception: ', '')}');
            } finally {
              setLocalState(() => localBusy = false);
              if (mounted) setState(() => _authBusy = false);
            }
          }

          return AlertDialog(
            title: const Text('Staff login'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone (10 digits)', prefixText: '+91 '),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocalState(() => showPassword = !showPassword),
                    ),
                  ),
                  obscureText: !showPassword,
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: localBusy ? null : attemptLogin,
                child: localBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Login'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _staffLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staffToken');
    await prefs.remove('staffRole');
    await prefs.remove('staffCampus');
    await prefs.remove('staffUserId');
    await prefs.remove('staffName');
    await prefs.remove('staffPhone');
    setState(() {
      _authToken = null;
      _authRole = null;
      _authCampusId = null;
      _authUserId = null;
      _authName = null;
      _authPhone = null;
      _users = [];
      _usersError = null;
      _usersLoading = false;
    });
    await _loadInitialData();
  }

  Future<void> _loadLikes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('likedMeals') ?? [];
    setState(() => _likedMealIds = stored.toSet());
  }

  Future<void> _persistLikes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedMeals', _likedMealIds.toList());
  }

  List<MealInfo> _sortMeals(List<MealInfo> items) {
    const order = ['breakfast', 'lunch', 'snacks', 'dinner'];
    final orderMap = {for (var i = 0; i < order.length; i++) order[i]: i};
    final sorted = List<MealInfo>.from(items);
    sorted.sort((a, b) {
      final ai = orderMap[a.mealType] ?? 99;
      final bi = orderMap[b.mealType] ?? 99;
      if (ai != bi) return ai.compareTo(bi);
      return a.time.compareTo(b.time);
    });
    return sorted;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final campusList = await _fetchCampuses();
      if (campusList.isEmpty) {
        throw Exception('No campuses found');
      }

      List<CampusOption> filteredCampuses = campusList;
      if (_authRole == 'manager' && _authCampusId != null) {
        filteredCampuses = campusList.where((c) => c.id == _authCampusId).toList();
        if (filteredCampuses.isEmpty) {
          throw Exception('Assigned college not available');
        }
      }

      final campusId = filteredCampuses.isNotEmpty ? filteredCampuses.first.id : campusList.first.id;
      final hallList = await _fetchHalls(campusId);
      final hallId = hallList.isNotEmpty ? hallList.first.id : null;
      final menuList = hallId != null ? await _fetchMenu(hallId, dates[selectedDay].value) : <MealInfo>[];

      if (!mounted) return;
      setState(() {
        campuses = filteredCampuses;
        halls = hallList;
        selectedCampusId = campusId;
        selectedHallId = hallId;
        meals = _sortMeals(menuList);
        loading = false;
        menuLoading = false;
      });
      if ((_authRole ?? '').toLowerCase() == 'admin') {
        unawaited(_loadUsers(silent: true));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load data';
        loading = false;
        menuLoading = false;
      });
    }
  }

  Future<void> _loadHallsForCampus(String campusId) async {
    if (_authRole == 'manager' && _authCampusId != null) {
      campusId = _authCampusId!;
    }
    setState(() {
      menuLoading = true;
      selectedHallId = null;
      halls = [];
      meals = [];
    });

    try {
      final hallList = await _fetchHalls(campusId);
      final hallId = hallList.isNotEmpty ? hallList.first.id : null;
      final menuList = hallId != null ? await _fetchMenu(hallId, dates[selectedDay].value) : <MealInfo>[];
      if (!mounted) return;
      setState(() {
        halls = hallList;
        selectedHallId = hallId;
        meals = _sortMeals(menuList);
        menuLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load halls';
        menuLoading = false;
      });
    }
  }

  Future<void> _loadMenuForHall(String hallId, DateTime date) async {
    setState(() {
      menuLoading = true;
    });
    try {
      final menuList = await _fetchMenu(hallId, date);
      if (!mounted) return;
      setState(() {
        meals = _sortMeals(menuList);
        menuLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load menu';
        menuLoading = false;
      });
    }
  }

  Future<void> _loadContact() async {
    setState(() => contactLoading = true);
    try {
      final info = await _fetchContact();
      if (!mounted) return;
      setState(() {
        contactInfo = info;
        contactLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => contactLoading = false);
    }
  }

  void _handleSettingsLabelTap() {
    if (_showStaffSettings) return;
    final next = (_settingsTapCount ?? 0) + 1;
    setState(() {
      _settingsTapCount = next;
      if (next >= 5) _settingsUnlocked = true;
    });
    if (next == 5 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff options unlocked')),
      );
    }
  }

  void _resetSettingsTapCount() {
    if (_settingsUnlocked) return;
    if (_settingsTapCount != null) {
      setState(() {
        _settingsTapCount = null;
      });
    }
  }

  Future<List<CampusOption>> _fetchCampuses() async {
    final uri = Uri.parse('$_apiBase/campuses');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    final list = data.map((e) => CampusOption.fromJson(e as Map<String, dynamic>)).toList();
    if (_isManager) {
      if (_authCampusId == null) {
        throw Exception('Manager has no assigned college');
      }
      return list.where((c) => c.id == _authCampusId).toList();
    }
    return list;
  }

  Future<List<HallOption>> _fetchHalls(String campusId) async {
    if (_isManager && _authCampusId != null) campusId = _authCampusId!;
    final uri = Uri.parse('$_apiBase/halls?campusId=$campusId');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => HallOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MealInfo>> _fetchMenu(String hallId, DateTime date) async {
    final dateParam = _formatApiDate(date);
    final uri = Uri.parse('$_apiBase/menu?hallId=$hallId&date=$dateParam');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => MealInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ContactInfo> _fetchContact() async {
    final uri = Uri.parse('$_apiBase/contact');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return ContactInfo.fromJson(data);
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    if (!mounted) return;
    setState(() {
      _usersLoading = true;
      if (!silent) _usersError = null;
    });
    try {
      final resp = await http.get(Uri.parse('$_apiBase/users'), headers: _authHeaders);
      if (resp.statusCode != 200) {
        throw Exception('Error ${resp.statusCode}');
      }
      final data = jsonDecode(resp.body) as List<dynamic>;
      final list = data.map((e) => StaffUser.fromJson(e as Map<String, dynamic>)).where((u) => u.role == 'manager').toList();
      if (!mounted) return;
      setState(() {
        _users = list..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _usersError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _usersError = 'Failed to load users';
      });
    } finally {
      if (!mounted) return;
      setState(() => _usersLoading = false);
    }
  }

  Future<void> _openUserForm({StaffUser? user}) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    if (campuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Load colleges first')));
      return;
    }
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: (user?.phone ?? '').replaceAll('+91', ''));
    final passCtrl = TextEditingController();
    String? selectedCampus = user?.campusId ?? _authCampusId ?? selectedCampusId ?? (campuses.isNotEmpty ? campuses.first.id : null);
    String? errorText;
    bool showPass = false;
    bool localBusy = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          if (selectedCampus != null && campuses.every((c) => c.id != selectedCampus)) {
            selectedCampus = campuses.first.id;
          }
          Future<void> submit() async {
            final phoneDigits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
            if (nameCtrl.text.trim().length < 2) {
              setLocalState(() => errorText = 'Enter a name (min 2 chars)');
              return;
            }
            if (phoneDigits.length != 10) {
              setLocalState(() => errorText = 'Enter a 10-digit phone number');
              return;
            }
            if (selectedCampus == null || (selectedCampus?.isEmpty ?? true)) {
              setLocalState(() => errorText = 'Choose a college');
              return;
            }
            if (user == null && passCtrl.text.trim().length < 6) {
              setLocalState(() => errorText = 'Password must be at least 6 characters');
              return;
            }
            if (user != null && passCtrl.text.isNotEmpty && passCtrl.text.trim().length < 6) {
              setLocalState(() => errorText = 'Password must be at least 6 characters');
              return;
            }

            setLocalState(() {
              errorText = null;
              localBusy = true;
            });
            if (mounted) setState(() => _authBusy = true);

            try {
              final body = {
                'name': nameCtrl.text.trim(),
                'phone': '+91$phoneDigits',
                'role': 'manager',
                'campusId': selectedCampus,
                if (passCtrl.text.trim().isNotEmpty) 'password': passCtrl.text.trim(),
              };
              http.Response resp;
              if (user == null) {
                resp = await http.post(Uri.parse('$_apiBase/users'), headers: _authHeaders, body: jsonEncode(body));
                if (resp.statusCode != 201) {
                  final msg = resp.body.isNotEmpty ? resp.body : 'Create failed (${resp.statusCode})';
                  throw Exception(msg);
                }
              } else {
                resp = await http.put(Uri.parse('$_apiBase/users/${user.id}'), headers: _authHeaders, body: jsonEncode(body));
                if (resp.statusCode != 200) {
                  final msg = resp.body.isNotEmpty ? resp.body : 'Update failed (${resp.statusCode})';
                  throw Exception(msg);
                }
              }
              if (mounted) {
                await _loadUsers();
                _showSuccess(user == null ? 'Manager added' : 'Manager updated');
              }
              Navigator.of(ctx, rootNavigator: true).pop(true);
            } catch (e) {
              setLocalState(() => errorText = e.toString().replaceAll('Exception: ', ''));
            } finally {
              setLocalState(() => localBusy = false);
              if (mounted) setState(() => _authBusy = false);
            }
          }

          return AlertDialog(
            title: Text(user == null ? 'Add manager' : 'Edit manager'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone (10 digits)', prefixText: '+91 '),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCampus,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'College'),
                    items: campuses
                        .map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (val) => setLocalState(() => selectedCampus = val),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    decoration: InputDecoration(
                      labelText: user == null ? 'Password (min 6)' : 'Password (leave blank to keep)',
                      suffixIcon: IconButton(
                        icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setLocalState(() => showPass = !showPass),
                      ),
                    ),
                    obscureText: !showPass,
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: localBusy ? null : submit,
                child: localBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(user == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openUserManagerSheet() async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    if (_users == null) {
      await _loadUsers();
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) {
        String query = '';
        String sortBy = 'name'; // name | campus
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 12,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              Future<void> refresh() async {
                await _loadUsers(silent: true);
                if (mounted) setSheet(() {});
              }

              List<StaffUser> list = (_users ?? const <StaffUser>[]);
              if (query.isNotEmpty) {
                final q = query.toLowerCase();
                list = list
                    .where((u) => u.name.toLowerCase().contains(q) || u.phone.toLowerCase().contains(q) || _campusNameById(u.campusId).toLowerCase().contains(q))
                    .toList();
              }
              list.sort((a, b) {
                if (sortBy == 'campus') {
                  final ca = _campusNameById(a.campusId).toLowerCase();
                  final cb = _campusNameById(b.campusId).toLowerCase();
                  final c = ca.compareTo(cb);
                  if (c != 0) return c;
                }
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });

              return SizedBox(
                height: MediaQuery.of(sheetCtx).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group_outlined, color: Color(0xFF374C8D)),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Manage managers', style: TextStyle(fontWeight: FontWeight.w700))),
                        IconButton(
                          tooltip: 'Add manager',
                          onPressed: _authBusy
                              ? null
                              : () async {
                                  await _openUserForm();
                                  if (mounted) setSheet(() {});
                                },
                          icon: const Icon(Icons.person_add_alt_1),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: _authBusy ? null : refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search by name, phone, college',
                              filled: true,
                              fillColor: Color(0xFFF1F3F8),
                              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            onChanged: (val) => setSheet(() => query = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<String>(
                            value: sortBy,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                              DropdownMenuItem(value: 'campus', child: Text('Sort: College')),
                            ],
                            onChanged: (val) => setSheet(() => sortBy = val ?? 'name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_usersLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    else if (_usersError != null)
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_usersError ?? 'Failed to load managers')),
                          TextButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                        ],
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemBuilder: (_, idx) {
                            final u = list[idx];
                            return ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(u.name),
                              subtitle: Text('Phone: ${u.phone}\nCollege: ${_campusNameById(u.campusId)}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit), onPressed: _authBusy ? null : () async {
                                    await _openUserForm(user: u);
                                    if (mounted) setSheet(() {});
                                  }),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: _authBusy ? null : () => _deleteUser(u.id, u.name),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemCount: list.length,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(String id, String name) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete manager'),
        content: Text('Remove $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    if (mounted) setState(() => _authBusy = true);
    try {
      await http.delete(Uri.parse('$_apiBase/users/$id'), headers: _authHeaders);
      await _loadUsers();
      if (mounted) _showSuccess('Manager removed');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _authBusy = false);
    }
  }

  Future<void> _likeMeal(MealInfo meal) async {
    if (_likedMealIds.contains(meal.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already liked this item on this device')),
      );
      return;
    }

    final updatedMeals = meals.map((m) => m.id == meal.id ? m.copyWith(likes: m.likes + 1) : m).toList();
    setState(() {
      meals = updatedMeals;
      _likedMealIds = {..._likedMealIds, meal.id};
    });
    _persistLikes();

    final uri = Uri.parse('$_apiBase/menu/${meal.id}/like');
    try {
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'delta': 1}));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final serverLikes = (data['likes'] as num?)?.toInt() ?? meal.likes;
        setState(() {
          meals = meals.map((m) => m.id == meal.id ? m.copyWith(likes: serverLikes) : m).toList();
        });
      } else {
        throw Exception('Failed like');
      }
    } catch (_) {
      setState(() {
        meals = meals.map((m) => m.id == meal.id ? m.copyWith(likes: m.likes - 1) : m).toList();
        _likedMealIds.remove(meal.id);
      });
      _persistLikes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not like right now. Please try again.')),
      );
    }
  }

  Future<void> _editMeal(MealInfo meal) async {
    if (!_canEdit) return;
    final titleCtrl = TextEditingController(text: meal.title);
    final itemsCtrl = TextEditingController(text: meal.subtitle);
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    void _seedRange() {
      final parts = meal.time.split(RegExp(r'-|–'));
      if (parts.isNotEmpty) startCtrl.text = parts[0].trim();
      if (parts.length > 1) endCtrl.text = parts[1].trim();
      if (startCtrl.text.isEmpty) startCtrl.text = meal.time;
    }
    _seedRange();

    TimeOfDay? _parseTime(String text) {
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false).firstMatch(text);
      if (match == null) return null;
      var hour = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final period = (match.group(3) ?? '').toLowerCase();
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }

    String _formatTimeOfDay(TimeOfDay t) {
      final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour12:$minute $suffix';
    }

    Future<void> _pickTime(TextEditingController ctrl) async {
      final initial = _parseTime(ctrl.text) ?? TimeOfDay.now();
      final picked = await showTimePicker(context: context, initialTime: initial);
      if (picked != null) ctrl.text = _formatTimeOfDay(picked);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit menu'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Meal title (e.g., Breakfast)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: itemsCtrl,
                decoration: const InputDecoration(labelText: 'Menu items'),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Start time'),
                      readOnly: true,
                      onTap: () => _pickTime(startCtrl),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End time'),
                      readOnly: true,
                      onTap: () => _pickTime(endCtrl),
                    ),
                  ),
                ],
              ),
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
    final title = titleCtrl.text.trim();
    final start = startCtrl.text.trim();
    final end = endCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a meal title')));
      return;
    }
    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both start and end time')));
      return;
    }
    try {
      await http.put(Uri.parse('$_apiBase/menu/${meal.id}'),
          headers: _authHeaders,
          body: jsonEncode({
            'title': title,
            'subtitle': itemsCtrl.text.trim(),
            'timeRange': '$start - $end',
          }));
      if (selectedHallId != null) {
        await _loadMenuForHall(selectedHallId!, dates[selectedDay].value);
      }
      _showSuccess('Menu updated');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  String get _selectedCampusName {
    for (final c in campuses) {
      if (c.id == selectedCampusId) return c.name;
    }
    return 'Select college';
  }

  String get _selectedHallName {
    for (final h in halls) {
      if (h.id == selectedHallId) return h.name;
    }
    return 'Select hall';
  }

  void _onCampusSelected(String name) {
    if (_isManager && _authCampusId != null) return; // manager locked to assigned campus
    final campus = campuses.firstWhere((c) => c.name == name, orElse: () => CampusOption(id: '', name: ''));
    if (campus.id.isEmpty) return;
    setState(() {
      selectedCampusId = campus.id;
    });
    _loadHallsForCampus(campus.id);
  }

  void _onHallSelected(String name) {
    final hall = halls.firstWhere((h) => h.name == name, orElse: () => HallOption(id: '', name: '', campusId: ''));
    if (hall.id.isEmpty) return;
    setState(() {
      selectedHallId = hall.id;
    });
    _loadMenuForHall(hall.id, dates[selectedDay].value);
  }

  Future<void> _promptAddCampus({BuildContext? sheetContext}) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    final name = await _promptText(context, 'College name');
    if (name == null || name.isEmpty) return;
    try {
      final resp = await http.post(Uri.parse('$_apiBase/campuses'), headers: _authHeaders, body: jsonEncode({'name': name}));
      if (resp.statusCode != 201) {
        throw Exception('Create failed (${resp.statusCode})');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final campus = CampusOption.fromJson(data);
      setState(() {
        campuses = [...campuses, campus]..sort((a, b) => a.name.compareTo(b.name));
        selectedCampusId = campus.id;
      });
      await _loadHallsForCampus(campus.id);
      if (sheetContext != null && Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }
      _showSuccess('College added', ctx: sheetContext ?? context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  Future<void> _promptRenameCampus({VoidCallback? onUpdated, BuildContext? alertContext}) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    final campusId = selectedCampusId ?? _authCampusId;
    if (campusId == null || campusId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a college first')));
      return;
    }
    final campus = campuses.firstWhere((c) => c.id == campusId, orElse: () => CampusOption(id: campusId, name: ''));
    final name = await _promptText(context, 'Rename college', initial: campus.name);
    if (name == null || name.isEmpty) return;
    await http.put(Uri.parse('$_apiBase/campuses/$campusId'), headers: _authHeaders, body: jsonEncode({'name': name}));
    setState(() {
      campuses = campuses.map((c) => c.id == campusId ? CampusOption(id: c.id, name: name) : c).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
    _showSuccess('College renamed', ctx: alertContext ?? context);
    onUpdated?.call();
  }

  Future<void> _promptRenameCampusByName(String campusName, {VoidCallback? onUpdated, BuildContext? alertContext}) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    final campus = campuses.firstWhere((c) => c.name == campusName, orElse: () => CampusOption(id: '', name: ''));
    if (campus.id.isEmpty) return;
    final name = await _promptText(context, 'Rename college', initial: campus.name);
    if (name == null || name.isEmpty) return;
    await http.put(Uri.parse('$_apiBase/campuses/${campus.id}'), headers: _authHeaders, body: jsonEncode({'name': name}));
    setState(() {
      campuses = campuses.map((c) => c.id == campus.id ? CampusOption(id: c.id, name: name) : c).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
    _showSuccess('College renamed', ctx: alertContext ?? context);
    onUpdated?.call();
  }

  Future<void> _deleteCampus(String campusId, {BuildContext? alertContext}) async {
    if ((_authRole ?? '').toLowerCase() != 'admin') return;
    final confirm = await showDialog<bool>(
      context: alertContext ?? context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete college'),
        content: const Text('This will remove the college and all its messes. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await http.delete(Uri.parse('$_apiBase/campuses/$campusId'), headers: _authHeaders);
    setState(() {
      campuses = campuses.where((c) => c.id != campusId).toList();
      if (selectedCampusId == campusId) {
        selectedCampusId = campuses.isNotEmpty ? campuses.first.id : null;
        selectedHallId = null;
        halls = [];
        meals = [];
      }
    });
    final nextCampus = selectedCampusId;
    if (nextCampus != null) {
      await _loadHallsForCampus(nextCampus);
    }
    _showSuccess('College deleted', ctx: alertContext ?? context);
  }

  Future<void> _promptAddHall({BuildContext? sheetContext}) async {
    if (!_canEdit) return;
    if (selectedCampusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a college first')));
      return;
    }
    if (_isManager && _authCampusId != null) {
      selectedCampusId = _authCampusId;
    }
    final name = await _promptText(context, 'Mess name');
    if (name == null || name.isEmpty) return;
    try {
      final resp = await http.post(Uri.parse('$_apiBase/halls'),
          headers: _authHeaders,
          body: jsonEncode({'name': name, 'campusId': selectedCampusId}));
      if (resp.statusCode != 201) {
        throw Exception('Create failed (${resp.statusCode})');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final hall = HallOption.fromJson(data);
      setState(() {
        halls = [...halls, hall]..sort((a, b) => a.name.compareTo(b.name));
        selectedHallId = hall.id;
        selectedCampusId = hall.campusId;
      });
      await _loadMenuForHall(hall.id, dates[selectedDay].value);
      if (sheetContext != null && Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }
      _showSuccess('Mess added', ctx: sheetContext ?? context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  Future<void> _promptRenameHall({VoidCallback? onUpdated, BuildContext? alertContext}) async {
    if (!_canEdit) return;
    final hallId = selectedHallId;
    if (hallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a mess first')));
      return;
    }
    final hall = halls.firstWhere((h) => h.id == hallId, orElse: () => HallOption(id: hallId, name: '', campusId: selectedCampusId ?? ''));
    final name = await _promptText(context, 'Rename mess', initial: hall.name);
    if (name == null || name.isEmpty) return;
    await http.put(Uri.parse('$_apiBase/halls/$hallId'),
        headers: _authHeaders,
        body: jsonEncode({'name': name, 'campusId': hall.campusId}));
    await _loadHallsForCampus(hall.campusId);
    _showSuccess('Mess renamed', ctx: alertContext ?? context);
    onUpdated?.call();
  }

  Future<void> _promptRenameHallByName(String hallName, {VoidCallback? onUpdated, BuildContext? alertContext}) async {
    if (!_canEdit) return;
    final hall = halls.firstWhere(
      (h) => h.name == hallName,
      orElse: () => HallOption(id: '', name: '', campusId: selectedCampusId ?? ''),
    );
    if (hall.id.isEmpty) return;
    final name = await _promptText(context, 'Rename mess', initial: hall.name);
    if (name == null || name.isEmpty) return;
    await http.put(Uri.parse('$_apiBase/halls/${hall.id}'),
        headers: _authHeaders,
        body: jsonEncode({'name': name, 'campusId': hall.campusId}));
    await _loadHallsForCampus(hall.campusId);
    _showSuccess('Mess renamed', ctx: alertContext ?? context);
    onUpdated?.call();
  }

  Future<void> _deleteHall(String hallId, {BuildContext? alertContext}) async {
    if (!_canEdit) return;
    await http.delete(Uri.parse('$_apiBase/halls/$hallId'), headers: _authHeaders);
    await _loadHallsForCampus(selectedCampusId ?? _authCampusId ?? '');
    _showSuccess('Mess deleted', ctx: alertContext ?? context);
  }

  void _openSelectorSheet(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    if (_isManager && label.toLowerCase().contains('college')) return; // manager locked
    var currentItems = List<String>.from(items);
    String? inlineNotice;
    void showInline(String msg) {
      inlineNotice = msg;
      Future.delayed(const Duration(seconds: 2), () {
        inlineNotice = null;
        if (Navigator.of(context).canPop()) {
          // ensure sheet rebuilds if still open
          try {
            // ignore setState after dispose errors
            // will be called inside StatefulBuilder
          } catch (_) {}
        }
      });
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String query = '';
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final filtered = currentItems
                  .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                  .toList();
              final lowerLabel = label.toLowerCase();
              final isHall = lowerLabel.contains('mess');
              final isCampus = lowerLabel.contains('college');

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select $label',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF2F3A6A)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search $label',
                        filled: true,
                        fillColor: const Color(0xFFF1F3F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => query = val),
                    ),
                    const SizedBox(height: 12),
                    if ((_authRole ?? '').toLowerCase() == 'admin' && isCampus) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _promptAddCampus(sheetContext: sheetContext),
                              icon: const Icon(Icons.add),
                              label: const Text('Add college'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = item == value;
                          final allowCampusEdit = (_authRole ?? '').toLowerCase() == 'admin' && isCampus;
                          final allowHallEdit = _canEdit && isHall;
                          Widget? trailing;
                          if (allowHallEdit) {
                            trailing = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF374C8D)),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF374C8D)),
                                  tooltip: 'Rename this mess',
                                  onPressed: () => _promptRenameHallByName(item, alertContext: sheetContext, onUpdated: () {
                                    currentItems = halls.map((e) => e.name).toList();
                                    setState(() {
                                      inlineNotice = 'Mess renamed';
                                    });
                                  }),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Delete this mess',
                                  onPressed: () async {
                                    final hall = halls.firstWhere((h) => h.name == item, orElse: () => HallOption(id: '', name: '', campusId: selectedCampusId ?? ''));
                                    if (hall.id.isEmpty) return;
                                    final confirm = await showDialog<bool>(
                                      context: sheetContext,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete mess'),
                                            content: Text('Delete "$item" and its menus?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await _deleteHall(hall.id, alertContext: sheetContext);
                                      currentItems = halls.map((e) => e.name).toList();
                                      setState(() {
                                        inlineNotice = 'Mess deleted';
                                      });
                                    }
                                  },
                                ),
                              ],
                            );
                          } else if (allowCampusEdit) {
                            trailing = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF374C8D)),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF374C8D)),
                                  tooltip: 'Rename this college',
                                  onPressed: () => _promptRenameCampusByName(item, alertContext: sheetContext, onUpdated: () {
                                    currentItems = campuses.map((e) => e.name).toList();
                                    setState(() {
                                      inlineNotice = 'College renamed';
                                    });
                                  }),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Delete this college',
                                  onPressed: () async {
                                    final campus = campuses.firstWhere((c) => c.name == item, orElse: () => CampusOption(id: '', name: ''));
                                    if (campus.id.isEmpty) return;
                                    final confirm = await showDialog<bool>(
                                      context: sheetContext,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete college'),
                                        content: Text('Delete "$item" and all its messes?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _deleteCampus(campus.id, alertContext: sheetContext);
                                      currentItems = campuses.map((e) => e.name).toList();
                                      setState(() {
                                        inlineNotice = 'College deleted';
                                      });
                                    }
                                  },
                                ),
                              ],
                            );
                          } else {
                            trailing = isSelected ? const Icon(Icons.check_circle, color: Color(0xFF374C8D)) : null;
                          }
                          return ListTile(
                            title: Text(item),
                            trailing: trailing,
                            onTap: () {
                              onSelected(item);
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: filtered.length,
                      ),
                    ),
                    if (_canEdit && isHall) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _promptAddHall(sheetContext: sheetContext),
                              icon: const Icon(Icons.add),
                              label: const Text('Add mess'),
                            ),
                          ),
                        ],
                      ),
                    if ((_authRole ?? '').toLowerCase() == 'admin' && isCampus) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _promptAddCampus(sheetContext: sheetContext),
                              icon: const Icon(Icons.add),
                              label: const Text('Add college'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _promptRenameCampus(alertContext: sheetContext, onUpdated: () {
                                currentItems = campuses.map((e) => e.name).toList();
                                setState(() {
                                  inlineNotice = 'College renamed';
                                });
                              }),
                              icon: const Icon(Icons.edit),
                              label: const Text('Rename'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                    if (inlineNotice != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(inlineNotice!, style: const TextStyle(color: Color(0xFF1B5E20))),
                      ),
                    ],
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _promptText(BuildContext context, String label, {String initial = ''}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      _buildSettingsContent(),
      _buildContactContent(),
    ];
    final int currentTab = _tabIndex.clamp(0, pages.length - 1).toInt();

    return Scaffold(
      body: SafeArea(child: pages[currentTab]),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: currentTab,
        onSelect: (i) => setState(() => _tabIndex = i.clamp(0, pages.length - 1).toInt()),
      ),
    );
  }

  void _centerSelectedDate(int index) {
    if (!_dateScrollController.hasClients) return;
    const double itemWidth = 96;
    const double spacing = 10;
    final double targetCenter = index * (itemWidth + spacing) + itemWidth / 2;
    final double viewWidth = MediaQuery.of(context).size.width;
    final double desiredOffset = targetCenter - viewWidth / 2;
    final double maxOffset = _dateScrollController.position.maxScrollExtent;
    final double offset = desiredOffset.clamp(0, maxOffset);
    _dateScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _TopBar(
          timeText: _formatTime(_nowIst),
          dateText: _formatDate(_nowIst),
          campus: _selectedCampusName,
          onCampusTap: () => _openSelectorSheet(
            context,
            label: 'College',
            value: _selectedCampusName,
            items: campuses.map((e) => e.name).toList(),
            onSelected: _onCampusSelected,
          ),
          disableCampusTap: _isManager,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchSelector(
                  label: 'Mess / Hall',
                  value: _selectedHallName,
                  onTap: () => _openSelectorSheet(
                    context,
                    label: 'Mess / Hall',
                    value: _selectedHallName,
                    items: halls.map((e) => e.name).toList(),
                    onSelected: _onHallSelected,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select date', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        if (_canEdit)
                          TextButton.icon(
                            onPressed: _copyMenuDialog,
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Copy menus'),
                          ),
                        TextButton.icon(
                          onPressed: _pickAnyDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: const Text('Choose'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DateTabs(
                  dates: dates,
                  selectedIndex: selectedDay,
                  controller: _dateScrollController,
                  onSelected: (index) {
                    setState(() => selectedDay = index);
                    _centerSelectedDate(index);
                    final hallId = selectedHallId;
                    if (hallId != null) {
                      _loadMenuForHall(hallId, dates[index].value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      errorMessage!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.red[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                if (menuLoading && meals.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (meals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No menu found for this date.'),
                  )
                else
                  ...meals.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MealCard(
                          meal: meal,
                          liked: _likedMealIds.contains(meal.id),
                          onLike: () => _likeMeal(meal),
                          onEdit: _canEdit ? () => _editMeal(meal) : null,
                        ),
                      )),
                if (menuLoading && meals.isNotEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserManagementCard() {
    final count = (_users ?? const <StaffUser>[]).where((u) => u.role == 'manager').length;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.group_outlined, color: Color(0xFF374C8D)),
        title: const Text('User management (admins)'),
        subtitle: Text(count == 0 ? 'Add managers and assign colleges' : '$count manager${count == 1 ? '' : 's'}'),
        trailing: _usersLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _authBusy ? null : _openUserManagerSheet,
      ),
    );
  }

  Widget _buildSettingsContent() {
    final totalCampuses = campuses.length;
    final totalHalls = halls.length;
    final hasData = totalCampuses > 0 || totalHalls > 0;
    final showStaff = _showStaffSettings;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        if (_settingsTapGuard) {
          _settingsTapGuard = false;
          return;
        }
        _resetSettingsTapCount();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _settingsTapGuard = true,
              onTap: _handleSettingsLabelTap,
              child: Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.apps, color: Color(0xFF374C8D)),
              title: const Text('App name'),
              subtitle: const Text('CampusRise'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF374C8D)),
              title: const Text('Version'),
              subtitle: const Text('1.0'),
            ),
            if (showStaff)
              ListTile(
                leading: Icon(_authToken == null ? Icons.lock_open : Icons.verified_user, color: const Color(0xFF374C8D)),
                title: Text(_authToken == null ? 'Staff login' : 'Logged in as ${_authRole ?? ''}'),
                subtitle: _authToken == null
                    ? const Text('Managers can edit menus and mess names')
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (_authName != null && _authName!.isNotEmpty) Text('Name: ${_authName}', style: Theme.of(context).textTheme.bodySmall),
                        if (_authPhone != null && _authPhone!.isNotEmpty) Text('Phone: ${_authPhone}', style: Theme.of(context).textTheme.bodySmall),
                        Text(_authRole == 'manager'
                            ? 'Manager scoped to campus: ${_authCampusId ?? '-'}'
                            : 'Admin access'),
                      ]),
                trailing: _authBusy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: _authToken == null ? _staffLogin : _staffLogout,
                        child: Text(_authToken == null ? 'Login' : 'Logout'),
                      ),
              ),
            if (_authToken != null) ...[
              ListTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFF374C8D)),
                title: const Text('Edit profile'),
                subtitle: const Text('Update your name and phone'),
                onTap: _editProfileInfo,
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFF374C8D)),
                title: const Text('Change password'),
                subtitle: const Text('Set a new password (min 6 chars)'),
                onTap: _changeProfilePassword,
              ),
            ],
            if ((_authRole ?? '').toLowerCase() == 'admin') _buildUserManagementCard(),
            if (hasData)
              ListTile(
                leading: const Icon(Icons.storage_outlined, color: Color(0xFF374C8D)),
                title: const Text('Live data'),
                subtitle: Text('Campuses: $totalCampuses · Halls: $totalHalls'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactContent() {
    final info = contactInfo;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (contactLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )
          else if (info == null)
            const Text('Contact info not available right now.')
          else ...[
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Color(0xFF374C8D)),
              title: const Text('Email'),
              subtitle: Text(info.email),
              onTap: () async {
                final uri = Uri.parse('mailto:${info.email}');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: Color(0xFF374C8D)),
              title: const Text('Phone'),
              subtitle: Text(info.phone),
              onTap: () async {
                final uri = Uri.parse('tel:${info.phone}');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: Color(0xFF374C8D)),
              title: const Text('Address'),
              subtitle: Text(info.address),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String timeText;
  final String dateText;
  final String campus;
  final VoidCallback onCampusTap;
  final bool disableCampusTap;

  const _TopBar({
    required this.timeText,
    required this.dateText,
    required this.campus,
    required this.onCampusTap,
    this.disableCampusTap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: disableCampusTap ? null : onCampusTap,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.apartment, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                campus,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_drop_down, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeText,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: const Color(0xFFF8C23D), fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateText,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTabs extends StatelessWidget {
  final List<DateTab> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ScrollController controller;

  const _DateTabs({
    required this.dates,
    required this.selectedIndex,
    required this.onSelected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: controller,
      child: Row(
        children: dates.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: index == dates.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                width: 96,
                height: 68,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF374C8D) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: const Color(0xFFE4E7F1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected ? Colors.white : const Color(0xFF4F5A8E),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tab.date,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected ? Colors.white : const Color(0xFF8C93B1),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SearchSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              label.toLowerCase().contains('college')
                  ? Icons.apartment
                  : Icons.location_on_outlined,
              color: const Color(0xFF4F5A8E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: const Color(0xFF8C93B1)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: const Color(0xFF4F5A8E), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF9BA3C2)),
          ],
        ),
      ),
    );
  }
}

class MealCard extends StatelessWidget {
  final MealInfo meal;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback? onEdit;

  const MealCard({super.key, required this.meal, required this.liked, required this.onLike, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: meal.highlighted ? const Color(0xFFF0F3FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: meal.highlighted ? const Color(0xFF374C8D).withOpacity(0.12) : const Color(0xFFE4E7F1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: meal.iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meal.icon, color: meal.iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF2F3A6A),
                                  fontWeight: FontWeight.w800,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFFADB4CC), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              meal.time,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF515C84),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF515C84),
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5B678E),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onLike,
                icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 20),
                label: Text('${meal.likes}'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8C23D).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Color(0xFFF8C23D)),
                    const SizedBox(width: 4),
                    Text(
                      meal.rating.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFF2F3A6A), fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF374C8D)),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF25D366)),
                tooltip: 'Share via WhatsApp',
                onPressed: () => _shareViaWhatsApp(context),
              ),
            ],
          ),
        ],
      ),
    );

    return card;
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final text = '${meal.title} - ${meal.subtitle} | ${meal.time}';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _BottomNavBar({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374C8D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.home, label: 'Home', active: currentIndex == 0, onTap: () => onSelect(0)),
          _NavItem(icon: Icons.settings, label: 'Settings', active: currentIndex == 1, onTap: () => onSelect(1)),
          _NavItem(icon: Icons.call, label: 'Contact', active: currentIndex == 2, onTap: () => onSelect(2)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFF8C23D) : Colors.white;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
  }
}
