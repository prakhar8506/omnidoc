import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/billing/device_trial.dart';
import '../../core/env/app_env.dart';
import '../../core/state/app_state.dart';

class PremiumAccess {
  static void require(BuildContext context, AppState appState, VoidCallback action) {
    if (appState.hasPremium) {
      action();
      return;
    }
    PremiumScreen.show(context, appState);
  }
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, required this.appState});

  final AppState appState;

  static void show(BuildContext context, AppState appState) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PremiumScreen(appState: appState)),
    );
  }

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Razorpay? _razorpay;
  bool _busy = false;
  String? _error;

  static const _features = [
    ('Lab explanations', 'Plain-language reading of the reports you upload.'),
    ('Health AI', 'Questions about your logged vitals, meals, and reports.'),
    ('Meal plans', 'A weekly plan that follows the goal you already set.'),
    ('Workout plan', 'A session matched to today’s readiness, medicines, and time.'),
    ('Heart-rate zones', 'Zone ranges when a real resting heart rate and date of birth are saved.'),
    ('Export', 'A PDF and FHIR copy of what you have logged.'),
  ];

  @override
  void initState() {
    super.initState();
    final pay = Razorpay();
    pay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaid);
    pay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPayError);
    pay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {});
    _razorpay = pay;
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _startTrial() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final blocked = await DeviceTrial.claim();
    if (!mounted) return;
    if (blocked != null) {
      setState(() {
        _busy = false;
        _error = blocked;
      });
      return;
    }
    widget.appState.startPremiumTrial();
    setState(() => _busy = false);
  }

  Future<void> _subscribe() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    if (!AppEnv.isSupabaseConfigured) {
      setState(() {
        _busy = false;
        _error = 'Payments are not available until the server is configured.';
      });
      return;
    }
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'razorpay-order',
        body: {'receipt': widget.appState.userName},
      );
      final data = response.data;
      if (data is! Map || data['order_id'] == null || data['key_id'] == null) {
        throw StateError('missing order');
      }
      _razorpay?.open({
        'key': data['key_id'],
        'amount': 59900,
        'currency': 'INR',
        'name': 'Cura Premium',
        'description': '1 year · ₹599',
        'order_id': data['order_id'],
        'theme': {'color': '#6E5DF6'},
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open Razorpay. Check that the payment function is deployed.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPaid(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    setState(() => _busy = true);
    try {
      final verified = await Supabase.instance.client.functions.invoke(
        'razorpay-verify',
        body: {
          'order_id': orderId,
          'payment_id': paymentId,
          'signature': signature,
        },
      );
      final data = verified.data;
      if (data is Map && data['ok'] == true) {
        final until = DateTime.tryParse(data['premium_until']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 365));
        widget.appState.grantPremiumUntil(until);
        if (mounted) Navigator.pop(context);
        return;
      }
      throw StateError('unverified');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Payment reached Razorpay but could not be confirmed. Contact support with your payment id.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _error = response.message ?? 'Payment was not completed.');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    final card = Theme.of(context).colorScheme.surface;
    final active = widget.appState.hasPremium;

    return Scaffold(
      appBar: AppBar(
        title: Text('Go Premium', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            active ? 'Premium is active on this account.' : '₹599 a year',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink),
          ),
          const SizedBox(height: 6),
          Text(
            '7 days free on this phone, once. After that, one payment covers the year.',
            style: TextStyle(fontSize: 14, height: 1.4, color: ink.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 18),
          for (final feature in _features)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_open_rounded, size: 18, color: dark ? const Color(0xFFC7C1FF) : const Color(0xFF5B4EEA)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(feature.$1, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                        const SizedBox(height: 2),
                        Text(feature.$2, style: TextStyle(fontSize: 13, height: 1.35, color: ink.withValues(alpha: 0.72))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF5E7E), fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy || active ? null : _startTrial,
            child: Text(_busy ? 'Please wait' : 'Start 7-day free trial'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : _subscribe,
            child: const Text('Subscribe · ₹599/year'),
          ),
          const SizedBox(height: 14),
          Text(
            'ECG, blood pressure, sleep, and the other watch readings appear only when the tracker you connect actually sends them. Cura does not invent a missing reading or a biological age. Premium unlocks coaching tools that use the data already on file.',
            style: TextStyle(fontSize: 12, height: 1.4, color: ink.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}
