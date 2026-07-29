// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:pinput/pinput.dart';
// import 'package:provider/provider.dart';
//
// import '../../core/constants/app_colors.dart';
// import '../../core/constants/app_strings.dart';
// import '../../viewmodels/auth_viewmodel.dart';
// import '../../widgets/common/custom_button.dart';
// import '../../widgets/common/error_snackbar.dart';
// import '../../widgets/common/loading_overlay.dart';
//
// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key});
//
//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }
//
// class _OtpScreenState extends State<OtpScreen> {
//   final _pinController = TextEditingController();
//   final _pinFocusNode = FocusNode();
//   String _otp = '';
//   int _secondsLeft = 60;
//   Timer? _timer;
//
//   late String _phone;
//   bool _argsLoaded = false;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_argsLoaded) {
//       final args =
//       ModalRoute.of(context)!.settings.arguments as Map<String, String>;
//       _phone = args['phone']!;
//       _argsLoaded = true;
//       _startTimer();
//     }
//   }
//
//   void _startTimer() {
//     _timer?.cancel();
//     setState(() => _secondsLeft = 60);
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_secondsLeft == 0) {
//         t.cancel();
//       } else {
//         setState(() => _secondsLeft--);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _pinController.dispose();
//     _pinFocusNode.dispose();
//     super.dispose();
//   }
//
//   Future<void> _verify(AuthViewModel vm) async {
//     if (_otp.length != 6) {
//       AppSnackbar.showError(context, AppStrings.otpInvalid);
//       return;
//     }
//
//     final success = await vm.verifyOtp(_otp,
//     );
//
//     if (!mounted) return;
//     if (success) {
//       Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
//     } else {
//       AppSnackbar.showError(
//           context, vm.errorMessage ?? AppStrings.genericError);
//     }
//   }
//
//   Future<void> _resend(AuthViewModel vm) async {
//     if (_secondsLeft > 0) return;
//     AppSnackbar.showInfo(context, 'Resending OTP…');
//     if (!mounted) return;
//     Navigator.of(context).pop();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // ── Pinput theme ────────────────────────────────────────────────────────
//     final defaultPinTheme = PinTheme(
//       width: 48,
//       height: 52,
//       textStyle: const TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 20,
//         fontWeight: FontWeight.w700,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.divider, width: 1),
//       ),
//     );
//
//     final focusedPinTheme = defaultPinTheme.copyWith(
//       decoration: defaultPinTheme.decoration!.copyWith(
//         border: Border.all(color: AppColors.accent, width: 1.5),
//         color: AppColors.surface,
//       ),
//     );
//
//     final submittedPinTheme = defaultPinTheme.copyWith(
//       decoration: defaultPinTheme.decoration!.copyWith(
//         color: AppColors.accent.withOpacity(0.08),
//         border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
//       ),
//     );
//
//     final errorPinTheme = defaultPinTheme.copyWith(
//       decoration: defaultPinTheme.decoration!.copyWith(
//         border: Border.all(color: AppColors.error, width: 1.5),
//       ),
//     );
//
//     return Consumer<AuthViewModel>(
//       builder: (context, vm, _) {
//         return LoadingOverlay(
//           isLoading: vm.isLoading,
//           message: 'Verifying…',
//           child: Scaffold(
//             backgroundColor: AppColors.background,
//             body: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 32),
//
//                     // Back button
//                     GestureDetector(
//                       onTap: () => Navigator.of(context).pop(),
//                       child: const Icon(
//                         Icons.arrow_back_ios_new_rounded,
//                         color: AppColors.textSecondary,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//
//                     // Title
//                     const Text(
//                       AppStrings.verifyPhone,
//                       style: TextStyle(
//                         color: AppColors.textPrimary,
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     RichText(
//                       text: TextSpan(
//                         style: const TextStyle(
//                           color: AppColors.textSecondary,
//                           fontSize: 14,
//                           height: 1.5,
//                         ),
//                         children: [
//                           const TextSpan(text: AppStrings.otpSentTo),
//                           TextSpan(
//                             text: _argsLoaded ? _phone : '',
//                             style: const TextStyle(
//                               color: AppColors.accent,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 36),
//
//                     // ── Pinput ───────────────────────────────────────────
//                     Center(
//                       child: Pinput(
//                         length: 6,
//                         controller: _pinController,
//                         focusNode: _pinFocusNode,
//                         autofocus: true,
//                         defaultPinTheme: defaultPinTheme,
//                         focusedPinTheme: focusedPinTheme,
//                         submittedPinTheme: submittedPinTheme,
//                         errorPinTheme: errorPinTheme,
//                         keyboardType: TextInputType.number,
//                         pinAnimationType: PinAnimationType.fade,
//                         cursor: Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Container(
//                               margin: const EdgeInsets.only(bottom: 9),
//                               width: 22,
//                               height: 2,
//                               decoration: BoxDecoration(
//                                 color: AppColors.accent,
//                                 borderRadius: BorderRadius.circular(1),
//                               ),
//                             ),
//                           ],
//                         ),
//                         onChanged: (val) => setState(() => _otp = val),
//                         onCompleted: (_) => _verify(vm),
//                         hapticFeedbackType: HapticFeedbackType.lightImpact,
//                       ),
//                     ),
//                     const SizedBox(height: 36),
//
//                     // Verify button
//                     CustomButton(
//                       label: AppStrings.verify,
//                       onPressed: vm.isLoading || _otp.length != 6
//                           ? null
//                           : () => _verify(vm),
//                       isLoading: vm.isLoading,
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Resend row
//                     Center(
//                       child: _secondsLeft > 0
//                           ? Text(
//                         '${AppStrings.resendIn}$_secondsLeft${AppStrings.seconds}',
//                         style: const TextStyle(
//                           color: AppColors.textHint,
//                           fontSize: 13,
//                         ),
//                       )
//                           : GestureDetector(
//                         onTap: () => _resend(vm),
//                         child: const Text(
//                           AppStrings.resendCode,
//                           style: TextStyle(
//                             color: AppColors.accent,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
