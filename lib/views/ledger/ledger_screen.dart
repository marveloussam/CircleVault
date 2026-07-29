import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../viewmodels/ledger_viewmodel.dart';
import '../../viewmodels/circle_viewmodel.dart';
import '../../widgets/common/app_shimmer.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/ledger/ledger_summary_card.dart';
import '../../widgets/ledger/transaction_tile.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late String _circleId;
  bool _argsLoaded = false;
  Map<String, UserModel> _userMap = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _circleId = ModalRoute.of(context)!.settings.arguments as String;
      _argsLoaded = true;
      context.read<LedgerViewModel>().watchTransactions(_circleId);
    }
  }

  Future<void> _loadUserNames(List<String> uids) async {
    final repo = context.read<UserRepository>();
    final map = <String, UserModel>{};
    for (final uid in uids) {
      if (_userMap.containsKey(uid)) continue;
      try {
        map[uid] = await repo.getUser(uid);
      } catch (_) {}
    }
    if (mounted && map.isNotEmpty) {
      setState(() => _userMap.addAll(map));
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleName =
        context.watch<CircleViewModel>().currentCircle?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.ledger,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (circleName.isNotEmpty)
              Text(
                circleName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: Consumer<LedgerViewModel>(
        builder: (context, vm, _) {
          // Lazy-load member names for all transaction uids
          if (vm.transactions.isNotEmpty) {
            final uids =
                vm.transactions.map((t) => t.memberUid).toSet().toList();
            final missing = uids.where((u) => !_userMap.containsKey(u));
            if (missing.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _loadUserNames(uids),
              );
            }
          }

          if (vm.isLoading && vm.transactions.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(top: 16),
              children: List.generate(
                6,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: TransactionTileShimmer(),
                ),
              ),
            );
          }

          if (vm.transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle:
                  'Transactions will appear here once contributions begin.',
            );
          }

          return ListView(
            children: [
              const SizedBox(height: 8),

              // Summary stats card
              LedgerSummaryCard(
                totalContributedKobo: vm.totalContributedKobo,
                totalPaidOutKobo: vm.totalPaidOutKobo,
                transactionCount: vm.transactions.length,
                circleName: circleName,
              ),

              // Transaction list
              ...List.generate(vm.transactions.length, (i) {
                final tx = vm.transactions[i];
                return Column(
                  children: [
                    TransactionTile(
                      transaction: tx,
                      memberName: _userMap[tx.memberUid]?.name,
                    ),
                    if (i < vm.transactions.length - 1)
                      const TransactionDivider(),
                  ],
                );
              }),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
