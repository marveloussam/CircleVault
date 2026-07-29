import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/payment_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  late final String _uid;
  bool _initialLoadDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _uid = context.read<AuthViewModel>().currentUser?.uid ?? '';
      debugPrint('[AddCardScreen] init — uid=$_uid');
      // Load existing card state from Firestore so we can show card details
      // and decide whether the CTA says "Add Card" or "Update Card".
      context.read<PaymentViewModel>().loadCard(_uid);
    }
  }

  // ─── Start card-setup / update flow ────────────────────────────────────────

  Future<void> _startCardSetup(PaymentViewModel vm) async {
    if (vm.isLoading) return;

    debugPrint('[AddCardScreen] _startCardSetup() — uid=$_uid');

    final result = await vm.prepareCardSetup(uid: _uid);

    if (!mounted) return;

    if (result == null) {
      debugPrint('[AddCardScreen] prepareCardSetup returned null — '
          'error: ${vm.errorMessage}');
      AppSnackbar.showError(
        context,
        vm.errorMessage ?? AppStrings.genericError,
      );
      return;
    }

    debugPrint('[AddCardScreen] Got authorization URL — '
        'reference: ${result.reference}');

    final webViewResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PaystackWebViewScreen(
          authorizationUrl: result.authorizationUrl,
          reference: result.reference,
        ),
      ),
    );

    debugPrint('[AddCardScreen] WebView returned: $webViewResult');

    if (!mounted) return;

    if (webViewResult != true) {
      // User cancelled or closed the WebView — stay on screen, no snackbar needed.
      debugPrint('[AddCardScreen] Card setup cancelled by user.');
      return;
    }

    // WebView completed successfully — verify the transaction and save the card.
    debugPrint('[AddCardScreen] Verifying card with reference: '
        '${result.reference}');

    final success = await vm.verifyAndSaveCard(
      uid: _uid,
      reference: result.reference,
    );

    if (!mounted) return;

    if (success) {
      debugPrint('[AddCardScreen] Card verified and saved ✅ — '
          'popping back to caller.');
      AppSnackbar.showSuccess(
        context,
        vm.hasLinkedCard
            ? 'Card updated successfully.'
            : AppStrings.cardAdded,
      );
      // Pop with true so the caller (e.g. ProfileScreen / HomeScreen) knows
      // to refresh its own card-linked state.
      Navigator.pop(context, true);
    } else {
      debugPrint('[AddCardScreen] verifyAndSaveCard failed — '
          'error: ${vm.errorMessage}');
      // On failure we stay on the screen so the user can retry, and we
      // reload the latest card state (it may or may not have changed).
      await vm.loadCard(_uid);
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        vm.errorMessage ?? AppStrings.cardError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentViewModel>(
      builder: (context, vm, _) {
        final hasCard = vm.hasLinkedCard;
        final cardLast4 = vm.card?['paystackCardLast4'] as String?;
        final cardBank = vm.card?['paystackCardBank'] as String?;

        debugPrint('[AddCardScreen] build — hasCard=$hasCard, '
            'last4=$cardLast4, bank=$cardBank, '
            'isLoading=${vm.isLoading}');

        return LoadingOverlay(
          isLoading: vm.isLoading,
          message: vm.isLoading ? 'Verifying card…' : null,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                hasCard ? 'Payment Method' : AppStrings.addCard,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _HeaderSection(hasCard: hasCard),
                    const SizedBox(height: 20),

                    // ── Existing card details card ──────────────────────────
                    if (hasCard) ...[
                      _LinkedCardTile(
                        last4: cardLast4 ?? '••••',
                        bank: cardBank ?? 'Unknown bank',
                        onRemove: () => _confirmRemoveCard(vm),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Expanded(child: _BenefitsSection()),

                    const Text(
                      AppStrings.paymentSecured,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Primary CTA — label changes based on card state ─────
                    CustomButton(
                      label: hasCard
                          ? 'Update Card'
                          : AppStrings.proceedToAddCard,
                      icon: Icons.credit_card_rounded,
                      isLoading: vm.isLoading,
                      onPressed:
                      vm.isLoading ? null : () => _startCardSetup(vm),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Confirm + execute card removal ────────────────────────────────────────

  Future<void> _confirmRemoveCard(PaymentViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Remove Card',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Removing your card will stop automatic contributions until you link a new one.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    debugPrint('[AddCardScreen] Removing card for uid=$_uid');
    await vm.removeCard(_uid);

    if (!mounted) return;


      await vm.loadCard(_uid);
      if (!mounted) return;
      AppSnackbar.showInfo(context, 'Card removed.');

  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — adapts title/subtitle based on whether a card is linked
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.hasCard});

  final bool hasCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
            border:
            Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: const Center(
            child: Text('💳', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          hasCard ? 'Update your debit card' : 'Link your debit card',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasCard
              ? 'Replace your linked card. Your contributions will use the new card.'
              : 'Securely add your card for automated contributions and payouts.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Linked card details tile
// ─────────────────────────────────────────────────────────────────────────────

class _LinkedCardTile extends StatelessWidget {
  const _LinkedCardTile({
    required this.last4,
    required this.bank,
    required this.onRemove,
  });

  final String last4;
  final String bank;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          // Card icon with subtle gold ring
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Card details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•••• •••• •••• $last4',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bank,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Linked badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 12),
                SizedBox(width: 4),
                Text(
                  'Linked',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
            tooltip: 'Remove card',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paystack WebView Screen
// ─────────────────────────────────────────────────────────────────────────────

class _PaystackWebViewScreen extends StatefulWidget {
  const _PaystackWebViewScreen({
    required this.authorizationUrl,
    required this.reference,
  });

  final String authorizationUrl;
  final String reference;

  @override
  State<_PaystackWebViewScreen> createState() =>
      _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState
    extends State<_PaystackWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;

  static const String _callbackHost = 'circlevault.app';
  static const String _callbackPath = '/callback';

  // checkout.paystack.com is a SPA — after payment it fires window.postMessage
  // with {event: "successful"|"failed"|"closed"} from its iframe. The outer
  // page never navigates away, so onNavigationRequest / onPageStarted never see
  // the callback URL. We inject a JS listener that forwards every postMessage
  // to the Dart "PaystackEvent" channel. URL checks remain as a fallback for
  // redirect-style Paystack integrations.
  static const String _js = r"""
(function() {
  if (window._cvListenerAttached) return;
  window._cvListenerAttached = true;
  window.addEventListener('message', function(e) {
    try {
      var d = typeof e.data === 'string' ? e.data : JSON.stringify(e.data);
      PaystackEvent.postMessage(d);
    } catch(err) {
      PaystackEvent.postMessage('{"error":"' + String(err) + '"}');
    }
  }, false);
})();
""";

  void _onPaystackEvent(JavaScriptMessage msg) {
    if (_hasPopped) return;
    final raw = msg.message;
    debugPrint('[WebView] postMessage: $raw');

    try {
      dynamic parsed;
      try { parsed = jsonDecode(raw); } catch (_) { parsed = raw; }
      if (parsed is Map &&
          parsed['status'] == 'success' &&
          parsed['reference'] != null) {
        debugPrint(
            '[WebView] ✅ Success payload detected directly.'
        );
        _pop(true);
        return;
      }
      String? event;
      if (parsed is Map) {
        event = parsed['event'] as String?;
      } else if (parsed is String) {
        event = parsed;
      }

      debugPrint('[WebView] postMessage event=$event');

      if (event == 'successful' || event == 'success') {
        debugPrint('[WebView] ✅ Payment successful via postMessage.');
        _pop(true);
      } else if (event == 'failed') {
        debugPrint('[WebView] ❌ Payment failed via postMessage.');
        _pop(false);
      } else if (event == 'closed') {
        debugPrint('[WebView] 🔒 Checkout closed via postMessage.');
        _pop(false);
      }
    } catch (e) {
      debugPrint('[WebView] postMessage parse error: $e');
    }
  }

  void _checkUrl(String url) {
    if (_hasPopped) return;
    debugPrint('[WebView] _checkUrl: $url');
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (uri.host == _callbackHost && uri.path == _callbackPath) {
      final trxref = uri.queryParameters['trxref'];
      final ref    = uri.queryParameters['reference'];
      final ok     = trxref != null && ref != null;
      debugPrint('[WebView] ✅ Callback URL — trxref=$trxref ref=$ref ok=$ok');
      _pop(ok);
      return;
    }
    if (uri.scheme == 'paystack-close') {
      debugPrint('[WebView] paystack-close scheme.');
      _pop(false);
    }
  }

  void _pop(bool result) {
    if (_hasPopped) return;
    _hasPopped = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[WebView] Loading: ${widget.authorizationUrl}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..addJavaScriptChannel('PaystackEvent', onMessageReceived: _onPaystackEvent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          debugPrint('[WebView] pageStarted: $url');
          _checkUrl(url);
          if (!_hasPopped) setState(() => _isLoading = true);
        },
        onPageFinished: (url) {
          debugPrint('[WebView] pageFinished: $url');
          _checkUrl(url);
          if (!_hasPopped) {
            setState(() => _isLoading = false);
            _controller.runJavaScript(_js).catchError(
                  (e) => debugPrint('[WebView] JS inject error: $e'),
            );
          }
        },
        onWebResourceError: (error) {
          debugPrint('[WebView] resource error code=${error.errorCode} '
              'desc=${error.description}');
          if (error.errorCode == -1) return;
          if (!_hasPopped) {
            AppSnackbar.showError(context, 'Connection error: ${error.description}');
          }
        },
        onNavigationRequest: (request) {
          debugPrint('[WebView] navigationRequest: ${request.url}');
          _checkUrl(request.url);
          if (_hasPopped) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Secure Card Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.textSecondary),
          onPressed: () {
            debugPrint('[WebView] User closed WebView manually.');
            // Set _hasPopped so any in-flight navigation callbacks
            // don't fire a second pop after this one.
            _hasPopped = true;
            Navigator.of(context).pop(null);
          },
          tooltip: 'Cancel',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: const [
                Icon(Icons.lock_rounded,
                    color: AppColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'Paystack',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppColors.background,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent),
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading secure payment page…',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefits section
// ─────────────────────────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  static const _items = [
    (
    Icons.lock_outline_rounded,
    'Secure tokenization',
    'Your card details are encrypted and handled by Paystack. Circle Vault never sees your card number.',
    ),
    (
    Icons.schedule_rounded,
    'Automated contributions',
    'Your card will be charged automatically on each contribution date.',
    ),
    (
    Icons.verified_outlined,
    'Card verification',
    'A temporary ₦50 authorization is used to securely link your card.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final item = _items[index];
        return _InfoItem(
          icon: item.$1,
          title: item.$2,
          subtitle: item.$3,
        );
      },
    );
  }
}