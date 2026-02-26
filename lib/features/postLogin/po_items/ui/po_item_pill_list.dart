import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/po_item_providers.dart';

class PoItemPillList extends ConsumerWidget {
  final String poId;

  const PoItemPillList({super.key, required this.poId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poItemsAsync = ref.watch(processedPoSummaryItemsProvider(poId));
    final theme = Theme.of(context);

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

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final qty = double.tryParse(item.itemQty.toString()) ?? 0.0;
            final qtyStr = qty == qty.roundToDouble()
                ? qty.toInt().toString()
                : qty.toStringAsFixed(1);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 6),
                  Text(
                    item.itemName ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      qtyStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
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
  }
}
