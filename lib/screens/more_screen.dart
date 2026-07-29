import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'shopping_screen.dart';
import 'vault_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          NestCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ...MockData.members.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MemberAvatar(
                      initials: m.initials,
                      color: m.color,
                      size: 40,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MockData.familyName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${MockData.members.length} members',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              FeatureTile(
                title: 'Lists',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.tileOrange,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShoppingScreen()),
                ),
              ),
              FeatureTile(
                title: 'Expenses',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.tileYellow,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                ),
              ),
              FeatureTile(
                title: 'Vault',
                icon: Icons.folder_rounded,
                color: AppColors.tilePurple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VaultScreen()),
                ),
              ),
              FeatureTile(
                title: 'Emergency',
                icon: Icons.health_and_safety_rounded,
                color: AppColors.tileRed,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionLabel('Family wall'),
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < MockData.timeline.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        MemberAvatar(
                          initials: MockData.memberById(
                            MockData.timeline[i].memberId,
                          ).initials,
                          color: MockData.memberById(
                            MockData.timeline[i].memberId,
                          ).color,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MockData.timeline[i].text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                MockData.timeline[i].time,
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != MockData.timeline.length - 1)
                    const Divider(height: 1, indent: 58),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
