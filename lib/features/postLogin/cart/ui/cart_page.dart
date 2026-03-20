import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../providers/cart_view_logic.dart';
import '../providers/cart_controller.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../products/product_barrel.dart';
import 'cart_item_card.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _profitHighlightController;
  late Animation<double> _profitScaleAnimation;
  late Animation<Color?> _profitColorAnimation;

  @override
  void initState() {
    super.initState();
    _profitHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _profitScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.easeInOut,
          ),
        );

    _profitColorAnimation =
        ColorTween(
          begin: Colors.green.withValues(alpha: 0.2),
          end: Colors.white,
        ).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.linear,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider).initPendingOrder(context);
    });
  }

  @override
  void dispose() {
    _profitHighlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewData = ref.watch(cartViewLogicProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final products = productsAsync.value ?? [];
    final l10n = ref.watch(l10nProvider);

    final isOffline = productsAsync.hasError &&
        (productsAsync.error is NoInternetException ||
            productsAsync.error.toString().contains('no_internet'));

    ref.listen(
      cartViewLogicProvider.select((d) => (d.totalProfit, d.itemCount)),
      (previous, next) {
        if (previous != next && next.$1 != '0.00') {
          _profitHighlightController.forward(from: 0.0);
        }
      },
    );

    final canPop = context.canPop();

    return Scaffold(
      appBar: CustomAppBar(title: l10n['my_cart'] ?? 'My Cart'),
      drawer: canPop ? null : const CustomDrawer(),
      body: Column(
        children: [
          if (!viewData.isEmpty) _buildSummaryHeader(context, viewData, l10n),
          Expanded(
            child: isOffline
                ? _buildOfflineState(context, l10n)
                : viewData.isEmpty
                    ? _buildEmptyState(context, theme, l10n)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        itemCount: viewData.items.length,
                        itemBuilder: (context, index) {
                          final processedItem = viewData.items[index];
                          return CartItemCard(
                            key: ValueKey(processedItem.item.poItemId),
                            entity: processedItem.item,
                            products: products,
                          );
                        },
                      ),
          ),
          if (!viewData.isEmpty) _buildActionFooter(context, viewData, l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    ProcessedCartData viewData,
    Map<String, String> l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem(
              context,
              l10n['items'] ?? 'Items',
              '${viewData.itemCount}',
              valueSize: 18,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            AnimatedBuilder(
              animation: _profitHighlightController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _profitHighlightController.value > 0
                        ? _profitColorAnimation.value
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: ScaleTransition(
                    scale: _profitScaleAnimation,
                    child: _buildSummaryItem(
                      context,
                      l10n['shop_profit'] ?? 'Shop Profit on MRP',
                      '₹${viewData.totalProfit}',
                      color: Colors.green[700],
                      valueSize: 18,
                      isBold: true,
                    ),
                  ),
                );
              },
            ),
            _buildSummaryItem(
              context,
              l10n['final_amount'] ?? 'Final Amount',
              '₹${viewData.totalAmount}',
              isBold: true,
              crossAxisAlignment: CrossAxisAlignment.center,
              valueSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter(
    BuildContext context,
    ProcessedCartData viewData,
    Map<String, String> l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Add Items
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed('products'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n['add_items'] ?? 'Add Items'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Empty Cart
            OutlinedButton(
              onPressed: () =>
                  ref.read(cartControllerProvider).clearCart(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 10),
            // Place Order
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => ref
                    .read(cartControllerProvider)
                    .handleOrderAction(context, viewData),
                icon: const Icon(
                  Icons.shopping_cart_checkout_rounded,
                  size: 18,
                ),
                label: Text(
                  l10n['place_order'] ?? 'Place Order',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    Map<String, String> l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l10n['empty_cart_msg'] ?? 'Your cart is empty',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.goNamed('products'),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(l10n['go_to_products'] ?? 'Go to Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState(BuildContext context, Map<String, String> l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n['no_internet'] ?? 'No internet connection',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n['internet_disconnected'] ??
                  'You are offline. Some features may not work.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(productsStreamProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double? valueSize,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? theme.colorScheme.onSurface,
      fontSize: valueSize ?? 14,
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}
