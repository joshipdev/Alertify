import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'camera_view.dart';
import 'device_service.dart';
import 'theme.dart';

String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

void _snack(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

// ───────────────────────── Splash ─────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 260,
            child: CustomPaint(painter: WavePainter(const Color(0xFF3F74D1))),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 190,
            child: CustomPaint(painter: WavePainter(AppColors.lightBlue, heightFactor: 0.6)),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AlertifyLogo(size: 150, showWifi: true),
                SizedBox(height: 18),
                Text('Alertify',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('Home Alert System\nWith Mobile Access',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Login ─────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _busy = false;

  Future<void> _enter({required bool create}) async {
    final email = _email.text.trim();
    final password = _pass.text;
    if (!email.contains('@') || password.length < 6) {
      _snack(context, 'Enter a valid email and a password (at least 6 characters).');
      return;
    }
    setState(() => _busy = true);
    try {
      final credential = create
          ? await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email, password: password)
          : await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email, password: password);
      device.userEmail = credential.user?.email ?? email;
      await device.connect();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _snack(context, e.message ?? 'Authentication failed (${e.code}).');
    } catch (e) {
      if (!mounted) return;
      _snack(context, 'Unable to connect to Alertify: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.navy),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.6)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 110,
            child: CustomPaint(
                painter: WavePainter(AppColors.lightBlue.withValues(alpha: 0.6))),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const AlertifyLogo(
                      size: 120, houseColor: AppColors.navy, shieldColor: AppColors.blue),
                  const Text('Alertify',
                      style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 42,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Secure Your Home,\nAnywhere',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 1.3)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Email Address', Icons.mail_outline),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    decoration: _dec(
                      'Password',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _busy ? null : () => _enter(create: false),
                      child: _busy ? const CircularProgressIndicator() : const Text('Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or')),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _busy ? null : () => _enter(create: true),
                      child: const Text('Create Account',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.blue),
                    onPressed: () {
                      device.userEmail = 'demo-user@alertify.local';
                      device.cameraOnline = true;
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeShell()));
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: const Text('Continue in Demo / Offline Mode',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Shell (bottom nav) ─────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(onGo: (i) => setState(() => _tab = i)),
      const AlertsTab(),
      const SettingsTab(),
    ];
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.bg,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.blue),
              label: 'Home'),
          NavigationDestination(
            icon: ListenableBuilder(
              listenable: device,
              builder: (_, __) => Badge(
                isLabelVisible: device.events.isNotEmpty && device.motionActive,
                child: const Icon(Icons.notifications_none),
              ),
            ),
            selectedIcon: const Icon(Icons.notifications, color: AppColors.blue),
            label: 'Alerts',
          ),
          const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.blue),
              label: 'Settings'),
        ],
      ),
    );
  }
}

/// Navy header + rounded light body used by every main page.
class NavyPage extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget child;
  const NavyPage({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  SizedBox(width: 56, child: leading),
                  Expanded(
                    child: Center(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(
                      width: 56,
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Home ─────────────────────────

class HomeTab extends StatelessWidget {
  final void Function(int) onGo;
  const HomeTab({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      title: 'Alertify',
      leading: const Icon(Icons.menu, color: Colors.white, size: 28),
      actions: [
        IconButton(
          onPressed: () => onGo(1),
          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
        ),
      ],
      child: ListenableBuilder(
        listenable: device,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _statusCard(),
            const SizedBox(height: 14),
            _card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Sensor Monitoring',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _sensorTile(Icons.directions_run, 'Motion',
                          device.motionActive ? 'DETECTED' : 'Clear',
                          device.motionActive)),
                      const SizedBox(width: 10),
                      Expanded(child: _sensorTile(Icons.door_front_door, 'Door / Window',
                          device.doorOpen ? 'OPEN' : 'Closed',
                          device.doorOpen)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _sensorTile(Icons.local_fire_department, 'Smoke / Gas',
                          device.smokeDetected ? 'WARNING' : (device.mq2Ready ? 'Normal' : 'Warming'),
                          device.smokeDetected)),
                      const SizedBox(width: 10),
                      Expanded(child: _sensorTile(Icons.speed, 'MQ-2 raw',
                          '${device.gasRaw}', false)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _quick(Icons.notifications, 'Notifications', () => onGo(1))),
              const SizedBox(width: 12),
              Expanded(child: _quick(Icons.settings, 'Settings', () => onGo(2))),
            ]),
            const SizedBox(height: 14),
            _deviceRow(),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    late IconData icon;
    late Color color;
    late String title;
    late String sub;
    if (!device.cameraOnline) {
      icon = Icons.wifi_off;
      color = AppColors.grey;
      title = 'Device Offline';
      sub = 'Waiting for ESP32 heartbeat';
    } else if (device.alarmActive || device.smokeDetected || (device.motionActive && device.armed) || (device.doorOpen && device.armed)) {
      icon = Icons.warning_amber_rounded;
      color = AppColors.red;
      title = device.smokeDetected ? 'Smoke / Gas Alert!' :
          (device.doorOpen ? 'Door / Window Open!' : 'Motion Detected!');
      sub = 'Check your property immediately';
    } else if (!device.armed) {
      icon = Icons.shield_outlined;
      color = AppColors.orange;
      title = 'System Disarmed';
      sub = 'Alerts are paused';
    } else {
      icon = Icons.verified_user;
      color = AppColors.green;
      title = 'Your Home is Safe';
      sub = 'All systems are normal';
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 54, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ]),
    );
  }

  Widget _deviceRow() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(device.cameraOnline ? Icons.developer_board : Icons.wifi_off,
              color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ESP32 Security Controller',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(device.cameraOnline ? 'Connected to Firebase' : 'Offline / no heartbeat',
                  style: TextStyle(
                      color: device.cameraOnline ? AppColors.green : AppColors.grey)),
            ]),
          ),
          const Icon(Icons.sensors, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(device.mq2Ready ? 'MQ-2 Ready' : 'MQ-2 Warm-up'),
        ]),
      ),
    );
  }

  Widget _sensorTile(IconData icon, String title, String value, bool danger) {
    final color = danger ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ],
        )),
      ]),
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) {
    return _card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(icon, color: AppColors.navy, size: 30),
            const SizedBox(height: 6),
            Text(label),
          ]),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

// ───────────────────────── Notifications ─────────────────────────

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Clear all',
          onPressed: device.clearEvents,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
        ),
      ],
      child: ListenableBuilder(
        listenable: device,
        builder: (context, _) {
          if (device.events.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return Container(
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: device.events.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _tile(device.events[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(AlertEvent e) {
    late IconData icon;
    late Color color;
    switch (e.type) {
      case AlertType.motion:
        icon = Icons.directions_run;
        color = AppColors.red;
      case AlertType.armed:
        icon = Icons.verified_user;
        color = AppColors.green;
      case AlertType.disarmed:
        icon = Icons.shield_outlined;
        color = AppColors.orange;
      case AlertType.lowBattery:
        icon = Icons.battery_alert;
        color = AppColors.blue;
      case AlertType.cameraOffline:
        icon = Icons.videocam_off;
        color = AppColors.grey;
      case AlertType.doorOpen:
        icon = Icons.sensor_door;
        color = AppColors.red;
      case AlertType.smoke:
      case AlertType.gas:
        icon = Icons.local_fire_department;
        color = AppColors.red;
      case AlertType.deviceOnline:
        icon = Icons.wifi;
        color = AppColors.green;
      case AlertType.unknown:
        icon = Icons.notifications;
        color = AppColors.grey;
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, color: color),
      ),
      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(e.subtitle),
      trailing: Text(fmtTime(e.time), style: const TextStyle(color: AppColors.grey)),
    );
  }
}

// ───────────────────────── Settings ─────────────────────────

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      title: 'Settings',
      child: ListenableBuilder(
        listenable: device,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.border,
                  child: Icon(Icons.person, size: 36, color: AppColors.navy),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('User Account',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(device.userEmail, style: const TextStyle(color: AppColors.grey)),
                  ]),
                ),
                const Icon(Icons.chevron_right),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                _item(Icons.photo_camera, 'Camera Settings', onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CameraSettingsScreen()));
                }),
                const Divider(height: 1),
                _item(Icons.verified_user, 'Security Mode',
                    value: device.armed ? 'Armed' : 'Disarmed',
                    valueColor: device.armed ? AppColors.blue : AppColors.orange,
                    onTap: () => device.setArmed(!device.armed)),
                const Divider(height: 1),
                _item(Icons.notifications, 'Notification Settings',
                    onTap: () => _snack(context, 'Push notifications are enabled (demo)')),
                const Divider(height: 1),
                _item(Icons.developer_mode, 'Hardware Simulator',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => const _SimulatorSheet(),
                      );
                    }),
                const Divider(height: 1),
                _item(Icons.info, 'About Alertify', onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Alertify',
                    applicationVersion: '1.0.0 (demo)',
                    applicationIcon:
                        const AlertifyLogo(size: 48, houseColor: AppColors.navy),
                    children: const [
                      Text('Home Alert System With Mobile Access.\n'
                          'This demo uses a simulated CCTV / IoT device.'),
                    ],
                  );
                }),
              ]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label,
      {String? value, Color? valueColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(label),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (value != null)
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w500)),
        const Icon(Icons.chevron_right),
      ]),
      onTap: onTap,
    );
  }
}

class CameraSettingsScreen extends StatelessWidget {
  const CameraSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Camera Settings'),
      ),
      body: ListenableBuilder(
        listenable: device,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Night vision'),
              subtitle: const Text('Switches the live view to night mode'),
              value: device.nightVision,
              onChanged: device.setNightVision,
            ),
            const SizedBox(height: 8),
            const Text('Motion sensitivity',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              value: device.sensitivity,
              onChanged: device.setSensitivity,
            ),
            SwitchListTile(
              title: const Text('Camera online'),
              subtitle: const Text('Turn off to simulate a lost connection'),
              value: device.cameraOnline,
              onChanged: device.setCameraOnline,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Camera screen ─────────────────────────

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Camera'),
      ),
      body: Column(
        children: [
          const Expanded(child: CameraView(showExpand: true)),
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundAction(
                    icon: Icons.photo_camera,
                    label: 'Snapshot',
                    onTap: () => _snack(context, 'Snapshot saved to gallery (demo)'),
                  ),
                  const _TalkButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      InkResponse(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
      const SizedBox(height: 8),
      Text(label),
    ]);
  }
}

class _TalkButton extends StatefulWidget {
  const _TalkButton();
  @override
  State<_TalkButton> createState() => _TalkButtonState();
}

class _TalkButtonState extends State<_TalkButton> {
  bool _talking = false;

  @override
  Widget build(BuildContext context) {
    return _RoundAction(
      icon: _talking ? Icons.mic : Icons.mic_none,
      label: _talking ? 'Talking...' : 'Talk',
      color: _talking ? AppColors.red : AppColors.blue,
      onTap: () {
        setState(() => _talking = !_talking);
        _snack(context,
            _talking ? 'Two-way audio on (simulated)' : 'Two-way audio off');
      },
    );
  }
}

// ───────────────────────── Hardware simulator sheet ─────────────────────────

class _SimulatorSheet extends StatelessWidget {
  const _SimulatorSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: device,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hardware Simulator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Pretend to be the CCTV camera / sensor and see how the app reacts.',
                  style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.directions_run, color: AppColors.red),
                title: const Text('Trigger motion at Front Door'),
                subtitle: const Text('Sensor fires, alert is sent, camera shows intruder'),
                onTap: () {
                  device.triggerMotion();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sensor_door, color: AppColors.orange),
                title: Text(device.doorOpen ? 'Close Front Door' : 'Open Front Door'),
                subtitle: Text('Door is currently ${device.doorOpen ? "OPEN" : "CLOSED"}'),
                onTap: device.toggleDoor,
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department, color: AppColors.red),
                title: Text(device.smokeDetected ? 'Clear Smoke / Gas Alert' : 'Trigger Smoke / Gas Alert'),
                subtitle: Text('Gas level: ${device.gasRaw} (raw count)'),
                onTap: device.toggleSmoke,
              ),
              ListTile(
                leading: const Icon(Icons.battery_alert, color: AppColors.blue),
                title: const Text('Drain camera battery'),
                subtitle: Text('Now ${device.battery}% (low-battery alert at 20%)'),
                onTap: device.drainBattery,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.videocam_off, color: AppColors.grey),
                title: const Text('Camera online'),
                value: device.cameraOnline,
                onChanged: device.setCameraOnline,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.verified_user, color: AppColors.green),
                title: const Text('System armed'),
                value: device.armed,
                onChanged: device.setArmed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
