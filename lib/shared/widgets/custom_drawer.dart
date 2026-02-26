import 'package:flutter/material.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/core_providers.dart';

import '../../core/utils/dialogs.dart';
import '../../core/providers/localization_provider.dart';
import '../../router/app_routes.dart';
import 'read_entity_tile.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  bool _hasImageError = false;

  String? _userDisplayName() {
    final user = ref.watch(userProfileProvider).value;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Fallback to metadata if profile not yet loaded/available
      final name = currentUser?.userMetadata?['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      return currentUser?.email;
    }
    return user.fullName ?? currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    // Watch initialization state to trigger rebuilds for Role display, etc.
    ref.watch(rbacInitializationProvider);

    final authService = ref.watch(authServiceProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final avatarUrl = ref.watch(userAvatarUrlProvider);
    final displayName = _userDisplayName();
    final theme = Theme.of(context);
    final l10n = ref.watch(l10nProvider);
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    final initials = displayName != null && displayName.isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e[0])
              .join()
              .toUpperCase()
        : '?';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: Container(
                        width: 60,
                        height: 60,
                        color: theme.colorScheme.primaryContainer,
                        child: avatarUrl != null && !_hasImageError
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  // Defer setState to avoid "Build scheduled during frame"
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && !_hasImageError) {
                                      setState(() => _hasImageError = true);
                                    }
                                  });
                                  return Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Text(
                      "Orderzapp",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  displayName != null
                      ? (l10n['welcome_user'] ?? 'Welcome, {name}').replaceAll(
                          '{name}',
                          displayName,
                        )
                      : l10n['welcome_orderzapp'] ?? 'Welcome to Orderzapp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rbacService.roleName != null)
                  Text(
                    '${l10n['role'] ?? 'Role'}: ${rbacService.roleName!}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Products
          ReadEntityTile(
            moduleName: ModelProductFields.table, // "products"
            routeName: ProductsRoutesJson.listRouteName,
            title: l10n['products'] ?? 'Products',
            icon: Icons.shopping_bag,
            allowAnonymous: true,
          ),

          ListTile(
            leading: const Icon(Icons.shopping_cart), // 🛒 My Cart
            title: Text(l10n['my_cart'] ?? 'My Cart'),
            onTap: () => context.goNamed(AppRoute.cartName),
          ),

          // Purchase Orders by Shop
          if (isLoggedIn && rbacService.roleName == 'retailer')
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(l10n['purchase_history'] ?? 'Purchase History'),
              onTap: () => context.goNamed('purchase-orders-by-shop'),
            ),

          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person), // 👤 Profile
              title: Text(l10n['profile'] ?? 'Profile'),
              onTap: () => context.goNamed(AppRoute.profileName),
            ),

          // PO Items
          /* ReadEntityTile(
            moduleName: ModelPoItemFields.table, // "po_items"
            routeName: PoItemsRoutesJson.listRouteName,
            title: 'PO Items',
            icon: Icons.list_alt,
          ), */
          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.login), // 🔑 Login
              title: Text(l10n['login'] ?? 'Login'),
              onTap: () => context.goNamed(AppRoute.loginName),
            ),

          /* if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.waving_hand), // 👋 Welcome
              title: const Text('Welcome'),
              onTap: () => context.goNamed(AppRoute.welcomeName),
            ), */
          if (Supabase.instance.client.auth.currentSession != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n['logout'] ?? 'Logout'),
              onTap: () async {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: l10n['logout'] ?? 'Logout',
                  content: 'Are you sure you want to Logout?',
                  confirmLabel: l10n['logout'] ?? 'Logout',
                );
                if (confirmed) {
                  await authService.signOut();
                }
              },
            ),
        ],
      ),
    );
  }
}
