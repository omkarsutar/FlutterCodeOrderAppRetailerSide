import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/po_item_providers.dart';
import '../../products/providers/product_providers.dart';
import '../../../../core/providers/localization_provider.dart';

class PoItemPillList extends ConsumerWidget {
  final String poId;

  const PoItemPillList({super.key, required this.poId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poItemsAsync = ref.watch(processedPoSummaryItemsProvider(poId));
    final productsAsync = ref.watch(productsStreamProvider);
    final currentLanguage = ref.watch(languageProvider);
    final theme = Theme.of(context);

    final isHindiOrMarathi = currentLanguage == AppLanguage.hindi ||
        currentLanguage == AppLanguage.marathi;

    return poItemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Text(
        'Error loading items',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return productsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (products) {
            return Column(
              children: items.map((item) {
                final product = products.firstWhere(
                  (p) => p.productId == item.productId,
                  orElse: () => throw Exception('Product not found'),
                );

                String displayName = item.itemName ?? 'Unknown';
                if (isHindiOrMarathi &&
                    product.productNameHindi != null &&
                    product.productNameHindi!.isNotEmpty) {
                  displayName = product.productNameHindi!;
                }

                String? productImage = product.productImage;
                if (productImage != null && productImage.isNotEmpty) {
                  productImage = Uri.encodeFull(Uri.decodeFull(productImage));
                }

                final qty = double.tryParse(item.itemQty.toString()) ?? 0.0;
                final qtyStr = qty == qty.roundToDouble()
                    ? qty.toInt().toString()
                    : qty.toStringAsFixed(1);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          color: theme.colorScheme.surface,
                          child: (productImage != null &&
                                  productImage.isNotEmpty)
                              ? Image.network(
                                  productImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                )
                              : const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product Name
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quantity
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          qtyStr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
