import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../providers/nodos_provider.dart';
import '../../../iam/providers/profile_provider.dart';
import '../../../iam/presentation/widgets/profile_dialog.dart';

const _navy950 = AppColors.navy950;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _darkMint = AppColors.darkMint;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;

class TopBar extends ConsumerWidget {
  final bool isMobile;
  const TopBar({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider);
    final profile = ref.watch(profileProvider).profile;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _navy950,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: _slate100),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          // VPN status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _darkMint.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _darkMint, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mint,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'VPN · IRONLINK-NODE-01',
                  style: TextStyle(
                    color: _mint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Campana de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: _slate400, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Avatar interactivo
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ProfileDialog.show(context),
            child: UserAvatar(
              avatarUrl: profile?.avatarUrl,
              avatarColor: profile?.avatarColor,
              name: profile?.name.isNotEmpty == true ? profile!.name : username,
              size: 36,
              showBorder: true,
              borderColor: _mint,
            ),
          ),
        ],
      ),
    );
  }
}
