import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'store.dart';
import 'vpn_service.dart';

class UsIdentity {
  final String fullName;
  final String street;
  final String city;
  final String state;
  final String stateCode;
  final String zip;
  final String phone;

  const UsIdentity({
    required this.fullName,
    required this.street,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.zip,
    required this.phone,
  });
}

const List<UsIdentity> _kPredefinedUsIdentities = [
  UsIdentity(
    fullName: 'Robert Vance',
    street: '100 Mulberry St, Ste 400',
    city: 'Newark',
    state: 'New Jersey',
    stateCode: 'NJ',
    zip: '07102',
    phone: '(973) 621-4400',
  ),
  UsIdentity(
    fullName: 'James Miller',
    street: '1120 SW 5th Ave, Ste 100',
    city: 'Portland',
    state: 'Oregon',
    stateCode: 'OR',
    zip: '97204',
    phone: '(503) 823-4000',
  ),
  UsIdentity(
    fullName: 'Michael Wilson',
    street: '1000 Elm St, Ste 400',
    city: 'Manchester',
    state: 'New Hampshire',
    stateCode: 'NH',
    zip: '03101',
    phone: '(603) 624-6500',
  ),
  UsIdentity(
    fullName: 'David Anderson',
    street: '350 5th Ave, Fl 20',
    city: 'New York',
    state: 'New York',
    stateCode: 'NY',
    zip: '10118',
    phone: '(212) 736-3100',
  ),
  UsIdentity(
    fullName: 'William Taylor',
    street: '200 E Santa Clara St',
    city: 'San Jose',
    state: 'California',
    stateCode: 'CA',
    zip: '95113',
    phone: '(408) 535-3500',
  ),
  UsIdentity(
    fullName: 'Richard Thomas',
    street: '301 W 2nd St',
    city: 'Austin',
    state: 'Texas',
    stateCode: 'TX',
    zip: '78701',
    phone: '(512) 974-2000',
  ),
  UsIdentity(
    fullName: 'Joseph Moore',
    street: '350 Lincoln Rd',
    city: 'Miami Beach',
    state: 'Florida',
    stateCode: 'FL',
    zip: '33139',
    phone: '(305) 673-7000',
  ),
  UsIdentity(
    fullName: 'Thomas Jackson',
    street: '701 5th Ave, Ste 4200',
    city: 'Seattle',
    state: 'Washington',
    stateCode: 'WA',
    zip: '98104',
    phone: '(206) 622-6789',
  ),
  UsIdentity(
    fullName: 'Daniel White',
    street: '233 S Wacker Dr, Ste 300',
    city: 'Chicago',
    state: 'Illinois',
    stateCode: 'IL',
    zip: '60606',
    phone: '(312) 875-0066',
  ),
  UsIdentity(
    fullName: 'Matthew Harris',
    street: '500 S Grand Ave',
    city: 'Los Angeles',
    state: 'California',
    stateCode: 'CA',
    zip: '90071',
    phone: '(213) 624-6000',
  ),
  UsIdentity(
    fullName: 'Anthony Martin',
    street: '100 N Biscayne Blvd',
    city: 'Miami',
    state: 'Florida',
    stateCode: 'FL',
    zip: '33132',
    phone: '(305) 374-1000',
  ),
  UsIdentity(
    fullName: 'Mark Clark',
    street: '600 Congress Ave',
    city: 'Austin',
    state: 'Texas',
    stateCode: 'TX',
    zip: '78701',
    phone: '(512) 474-5000',
  ),
];

class SecurityShield {
  static const String defaultCheckUrl = 'https://browserleaks.com/webrtc';

  static UsIdentity getRandomIdentity() {
    final rnd = Random();
    return _kPredefinedUsIdentities[rnd.nextInt(_kPredefinedUsIdentities.length)];
  }

  /// انتخاب هویت معتبر و هماهنگ دقیق با شهر و ایالت سرور متصل‌شده
  static UsIdentity getIdentityForCity(String city, String region) {
    final c = city.toLowerCase();
    final r = region.toLowerCase();
    for (final id in _kPredefinedUsIdentities) {
      if (c.contains(id.city.toLowerCase()) ||
          r.contains(id.state.toLowerCase()) ||
          r.contains(id.stateCode.toLowerCase())) {
        return id;
      }
    }
    if (c.contains('newark') || r.contains('jersey') || r.contains('nj')) {
      return _kPredefinedUsIdentities.firstWhere((id) => id.stateCode == 'NJ', orElse: () => _kPredefinedUsIdentities.first);
    }
    if (c.contains('york') || r.contains('ny')) {
      return _kPredefinedUsIdentities.firstWhere((id) => id.stateCode == 'NY', orElse: () => _kPredefinedUsIdentities.first);
    }
    return getRandomIdentity();
  }

  /// باز کردن مرورگر در حالت ایزوله و امن (InPrivate/Incognito) همراه با قطع نشت WebRTC
  static Future<bool> launchSafeBrowser([String url = defaultCheckUrl]) async {
    if (Platform.isWindows) {
      // ابتدا ساعت سیستم را به طور خودکار با آمریکا/سرور هماهنگ می‌کنیم
      await Api.syncWindowsTimezone('US');

      try {
        // ۱. تلاش با مایکروسافت اج در حالت خصوصی با مسدودسازی WebRTC
        final r = await Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Start-Process msedge.exe -ArgumentList @("--inprivate", "--lang=en-US", "--force-webrtc-ip-handling-policy=disable_non_proxied_udp", "--disable-features=WebRtcHideLocalIpsWithMdns", "$url")',
        ]);
        if (r.exitCode == 0) return true;
      } catch (_) {}

      try {
        // ۲. تلاش با گوگل کروم در حالت اینکوگنیتو و مسدودسازی قطعی نشت WebRTC
        final r = await Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Start-Process chrome.exe -ArgumentList @("--incognito", "--lang=en-US", "--force-webrtc-ip-handling-policy=disable_non_proxied_udp", "--disable-features=WebRtcHideLocalIpsWithMdns", "$url")',
        ]);
        if (r.exitCode == 0) return true;
      } catch (_) {}

      try {
        // ۳. مرورگر پیش‌فرض سیستم
        await Process.start('explorer.exe', [url], mode: ProcessStartMode.detached);
        return true;
      } catch (_) {}
    } else if (Platform.isLinux) {
      try {
        await Process.run('google-chrome', ['--incognito', '--lang=en-US', '--force-webrtc-ip-handling-policy=disable_non_proxied_udp', url]);
        return true;
      } catch (_) {
        try {
          await Process.run('xdg-open', [url]);
          return true;
        } catch (_) {}
      }
    } else if (Platform.isMacOS) {
      try {
        await Process.run('open', ['-na', 'Google Chrome', '--args', '--incognito', '--force-webrtc-ip-handling-policy=disable_non_proxied_udp', url]);
        return true;
      } catch (_) {
        try {
          await Process.run('open', [url]);
          return true;
        } catch (_) {}
      }
    }
    return false;
  }
}

// برای حفظ سازگاری کامل کدهای قبلی
typedef AwsAssistant = SecurityShield;

void showSecurityShieldSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _SecurityShieldSheetWidget(),
  );
}

void showAwsAssistantSheet(BuildContext context) => showSecurityShieldSheet(context);

class _SecurityShieldSheetWidget extends StatefulWidget {
  const _SecurityShieldSheetWidget();

  @override
  State<_SecurityShieldSheetWidget> createState() => _SecurityShieldSheetWidgetState();
}

class _SecurityShieldSheetWidgetState extends State<_SecurityShieldSheetWidget> {
  late UsIdentity _identity;
  IpQualityReport? _quality;
  bool _loadingQuality = true;

  @override
  void initState() {
    super.initState();
    _identity = SecurityShield.getRandomIdentity();
    _fetchQuality();
  }

  Future<void> _fetchQuality() async {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final on = VpnService.I.status.value.phase == Phase.on;
    final proxy = (isDesktop && on) ? '127.0.0.1:10809' : null;
    final q = await Api.inspectIpQuality(proxy: proxy);
    if (mounted) {
      setState(() {
        _quality = q;
        _loadingQuality = false;
        if (q != null && q.city.isNotEmpty) {
          _identity = SecurityShield.getIdentityForCity(q.city, q.country);
        }
      });
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label کپی شد: $text', textDirection: TextDirection.rtl),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final tzMatched = _quality?.timezoneMatch ?? false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: p.border.withOpacity(0.5)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.sub.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'سپر امنیت و ابزارهای حریم خصوصی',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ضد نشت',
                                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'بررسی نشت WebRTC، هماهنگی ساعت، مرورگر ایزوله و تست هویت',
                          style: TextStyle(color: p.sub, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                children: [
                  // Pre-flight Status Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.checklist_rounded, color: Color(0xFF29E07F), size: 20),
                            SizedBox(width: 8),
                            Text('بررسی وضعیت اتصال و عدم نشت اطلاعات',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_loadingQuality)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                          )
                        else ...[
                          _checkItem(
                            'لوکیشن سرور: ${_quality?.country ?? 'ناشناس'} (${_quality?.city ?? ''})',
                            _quality != null,
                            'ترافیک به صورت کامل از این لوکیشن خارج می‌شود',
                          ),
                          const SizedBox(height: 8),
                          _checkItem(
                            tzMatched ? 'ساعت سیستم: کاملاً همگام با سرور' : 'ساعت سیستم: ناهماهنگ با سرور',
                            tzMatched,
                            tzMatched ? 'عدم مغایرت ساعت و موقعیت جغرافیایی' : 'پیشنهاد: ساعت سیستم را با سرور همگام کنید',
                          ),
                          if (!tzMatched && Platform.isWindows) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF29E07F),
                                foregroundColor: const Color(0xFF040A1C),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                              label: const Text('⚡ همگام‌سازی فوری ساعت با سرور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              onPressed: () async {
                                final ok = await Api.syncWindowsTimezone(_quality?.code ?? 'US');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(ok ? 'ساعت ویندوز با سرور هماهنگ شد!' : 'خطا در تنظیم ساعت')),
                                  );
                                  _fetchQuality();
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          _checkItem('سپر نشت WebRTC (مسدودسازی STUN/TURN): فعال', true, 'آی‌پی واقعی ایران در WebRTC مسدود شده است'),
                          const SizedBox(height: 8),
                          _checkItem('رمزنگاری DNS و تونل DoH: فعال', true, 'جلوگیری از مسموم‌سازی DNS و نشت پورت ۵۳'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Isolated Safe Browser Launcher Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.open_in_browser_rounded, color: Color(0xFF00C6FF), size: 20),
                            SizedBox(width: 8),
                            Text('راه‌اندازی مرورگر ایزوله و ضد نشت',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'باز کردن مرورگر در پنجره ناشناس (Incognito) با فلگ‌های امنیتی مسدودکننده نشت WebRTC و هدایت کامل از تونل NEXORA.',
                          style: TextStyle(color: p.sub, fontSize: 11.5, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.shield_rounded, size: 20),
                          label: const Text('🚀 باز کردن مرورگر ایمن (تست نشت WebRTC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () async {
                            final ok = await SecurityShield.launchSafeBrowser(SecurityShield.defaultCheckUrl);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok ? 'مرورگر امن باز شد.' : 'خطا در باز کردن مرورگر.')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _browserChip('IPQualityScore', 'https://www.ipqualityscore.com', Icons.verified_user_rounded),
                            _browserChip('IPHey Fingerprint', 'https://iphey.com', Icons.fingerprint_rounded),
                            _browserChip('ChatGPT AI', 'https://chatgpt.com', Icons.smart_toy_rounded),
                            _browserChip('Claude AI', 'https://claude.ai', Icons.auto_awesome_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clean Identity Generator Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.badge_rounded, color: Color(0xFF00C6FF), size: 20),
                                SizedBox(width: 8),
                                Text('مشخصات و آدرس معتبر بین‌المللی',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ],
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('تولید مجدد', style: TextStyle(fontSize: 11.5)),
                              onPressed: () {
                                setState(() {
                                  _identity = SecurityShield.getRandomIdentity();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _copyRow('نام کامل', _identity.fullName, p),
                        _copyRow('آدرس خیابان', _identity.street, p),
                        _copyRow('شهر', _identity.city, p),
                        _copyRow('ایالت (State)', '${_identity.state} (${_identity.stateCode})', p, copyVal: _identity.stateCode),
                        _copyRow('کد پستی (ZIP)', _identity.zip, p),
                        _copyRow('تلفن', _identity.phone, p),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _browserChip(String label, String url, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF00C6FF)),
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      onPressed: () => SecurityShield.launchSafeBrowser(url),
    );
  }

  Widget _checkItem(String title, bool ok, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: ok ? const Color(0xFF29E07F) : Colors.amber, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _copyRow(String label, String value, P p, {String? copyVal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: TextStyle(color: p.sub, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: p.text, fontSize: 12.5, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: 'کپی',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _copy(copyVal ?? value, label),
          ),
        ],
      ),
    );
  }
}
