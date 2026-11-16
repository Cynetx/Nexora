import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/models.dart' show SignInState, SignInStep;
import 'firefox_service.dart';
import 'firefox_signup_page.dart';

/// ورود به حساب Mozilla/Firefox داخل خود اپ: ایمیل و پسورد اجباری هستند،
/// دکمه‌ی Login درخواست را به API حساب‌های Mozilla می‌فرستد و اگر سرور
/// کد امنیتی بخواهد، «Verify Code» نمایش داده می‌شود و کد همین‌جا وارد/پیست می‌شود.
class FirefoxLoginPage extends StatefulWidget {
  const FirefoxLoginPage({super.key, required this.service, this.email = ''});
  final FirefoxService service;
  final String email;

  @override
  State<FirefoxLoginPage> createState() => _FirefoxLoginPageState();
}

class _FirefoxLoginPageState extends State<FirefoxLoginPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  final _code = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  bool _success = false;
  String? _id;
  String? _error;
  SignInState? _ask; // مرحله‌ای که منتظر ورودی کاربر است

  @override
  void dispose() {
    if (_id != null && !_success) unawaited(widget.service.cancelBrowserSignIn());
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? '$what را وارد کن' : null;

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'ایمیل را وارد کن';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'ایمیل معتبر نیست';
    return null;
  }

  Future<void> _request() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _ask = null;
    });
    try {
      final state = await widget.service.startPasswordSignIn(_email.text.trim(), _password.text);
      _id = state.id;
      await _drive(state);
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted && _ask == null && !_success) setState(() => _busy = false);
    }
  }

  /// وضعیت ورود را پیگیری می‌کند تا به پایان برسد یا ورودی از کاربر لازم شود.
  Future<void> _drive(SignInState first) async {
    var state = first;
    final id = _id!;
    final until = DateTime.now().add(const Duration(minutes: 3));
    while (mounted) {
      if (state.step == SignInStep.done) {
        await widget.service.finishPasswordSignIn();
        if (!mounted) return;
        _success = true;
        Navigator.of(context).pop(true);
        return;
      }
      if (state.step == SignInStep.failed || state.step == SignInStep.cancelled) {
        final msg = state.error.isNotEmpty ? state.error : (state.message.isNotEmpty ? state.message : 'ورود انجام نشد');
        setState(() {
          _busy = false;
          _ask = null;
          _id = null;
          _error = msg;
        });
        return;
      }
      if (state.needsAnswer) {
        setState(() {
          _busy = false;
          _ask = state;
          _code.clear();
        });
        return;
      }
      if (DateTime.now().isAfter(until)) {
        setState(() {
          _busy = false;
          _error = 'تأیید ورود Mozilla بیش از حد طول کشید';
        });
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      state = await widget.service.signInStatus(id);
    }
  }

  Future<void> _submitCode() async {
    final value = _code.text.trim();
    final id = _id;
    if (value.isEmpty || id == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _ask = null;
    });
    try {
      final state = await widget.service.answerSignIn(id, value);
      await _drive(state);
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted && _ask == null && !_success) setState(() => _busy = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) return;
    // کدهای تأیید معمولاً عددی/حرفی کوتاه‌اند؛ فاصله‌ها حذف می‌شوند.
    setState(() {
      _code.text = text.replaceAll(RegExp(r'\s+'), '');
      _code.selection = TextSelection.collapsed(offset: _code.text.length);
    });
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');

  Uint8List? _captchaBytes(String dataUrl) {
    final i = dataUrl.indexOf('base64,');
    if (i < 0) return null;
    try {
      return base64Decode(dataUrl.substring(i + 7));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ask = _ask;
    return Scaffold(
      appBar: AppBar(title: const Text('ورود Firefox')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            if (_busy) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(minHeight: 2)),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    enabled: !_busy && ask == null,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.alternate_email_rounded), border: OutlineInputBorder()),
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy && ask == null,
                    obscureText: _obscure,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _request(),
                    decoration: InputDecoration(
                      labelText: 'پسورد',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      ),
                    ),
                    validator: (v) => _requiredValidator(v, 'پسورد'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _busy || ask != null ? null : _request,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Login'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ],
              ),
            ),
            if (ask == null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: _busy ? null : () => startFirefoxSignUp(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Sign Up'),
                ),
              ),
            if (_busy && ask == null)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text('در حال ورود به Mozilla؛ منتظر پاسخ…', textAlign: TextAlign.center),
              ),
            if (ask != null) ...[
              const SizedBox(height: 22),
              _verifyCard(theme, ask),
            ],
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _verifyCard(ThemeData theme, SignInState ask) {
    final captcha = ask.step == SignInStep.needCaptcha ? _captchaBytes(ask.captcha) : null;
    final hint = switch (ask.step) {
      SignInStep.needTotp => 'Enter the code from your authenticator app.',
      SignInStep.needUnblockCode => 'Enter the unblock code sent to your email.',
      SignInStep.needCaptcha => 'Type the characters shown in the image.',
      _ => 'Enter the verification code sent to your email.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Verify Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
              const SizedBox(height: 6),
              Text(hint, style: theme.textTheme.bodyMedium),
              if (ask.message.isNotEmpty && ask.message != hint) ...[
                const SizedBox(height: 4),
                Text(ask.message, style: theme.textTheme.bodySmall),
              ],
              if (captcha != null) ...[
                const SizedBox(height: 10),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Image.memory(captcha, height: 70, fit: BoxFit.contain),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitCode(),
                decoration: InputDecoration(
                  labelText: 'Verify Code',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Paste',
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _submitCode,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
