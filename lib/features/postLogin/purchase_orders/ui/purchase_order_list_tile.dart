import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/date_utils.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_items/po_item_barrel.dart';

import '../../../../core/services/entity_service.dart';
import '../model/purchase_order_model.dart';
import '../providers/purchase_order_tile_logic.dart';

class PurchaseOrderListTile extends ConsumerStatefulWidget {
  final ModelPurchaseOrder entity;
  final EntityAdapter<ModelPurchaseOrder> adapter;
  final VoidCallback? onTap;
  final bool? poItemTile;
  final bool showShare;
  final void Function(String oldStatus, String newStatus)? onStatusChanged;

  const PurchaseOrderListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
    this.poItemTile,
    this.showShare = false,
    this.onStatusChanged,
  });

  @override
  ConsumerState<PurchaseOrderListTile> createState() =>
      _PurchaseOrderListTileState();
}

class _PurchaseOrderListTileState extends ConsumerState<PurchaseOrderListTile> {
  bool _isUpdating = false;
  bool _isExpanded = false;

  void _onStatusChanged(String? newStatus) {
    if (newStatus == null) return;
    PurchaseOrderTileLogic.updateStatus(
      context: context,
      ref: ref,
      entity: widget.entity,
      newStatus: newStatus,
      setUpdating: (val) => setState(() => _isUpdating = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRbacReady = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final canUpdate = isRbacReady && rbacService.canUpdate('purchase_order');
    final canDelete = isRbacReady && rbacService.canDelete('purchase_order');

    final dateStr = widget.entity.createdAt != null
        ? formatTimestamp(widget.entity.createdAt!)
        : '';
    final shopName =
        widget.adapter
            .getLabelValue(widget.entity, ModelPurchaseOrderFields.poShopId)
            ?.toString() ??
        'Unknown Shop';
    final status = widget.entity.status ?? 'pending';
    final itemCount = widget.entity.poLineItemCount ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.poItemTile != true) ...[
                _buildHeader(theme, dateStr, _isExpanded, status),
                const SizedBox(height: 12),
              ],
              _buildShopInfo(context, theme, shopName, canDelete, status),
              const SizedBox(height: 12),
              _buildStatsRow(theme, itemCount, status, canUpdate),
              if (widget.entity.poId != null && _isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                PoItemPillList(poId: widget.entity.poId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    String dateStr,
    bool isExpanded,
    String status,
  ) {
    final statusColor = PurchaseOrderTileLogic.getStatusColor(status);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            dateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _StatusBadge(status: status, statusColor: statusColor),
        const SizedBox(width: 8),
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildShopInfo(
    BuildContext context,
    ThemeData theme,
    String shopName,
    bool canDelete,
    String status,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            shopName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    int itemCount,
    String status,
    bool canUpdate,
  ) {
    final profitStr = PurchaseOrderTileLogic.formatCurrency(
      widget.entity.profitToShop,
    );
    final amountStr = PurchaseOrderTileLogic.formatCurrency(
      widget.entity.poTotalAmount,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(label: 'Items', value: '$itemCount'),
        _StatItem(
          label: 'Shop Profit',
          value: '₹$profitStr',
          valueColor: Colors.green[700],
        ),
        _StatItem(
          label: 'Total Amount',
          value: '₹$amountStr',
          valueColor: theme.colorScheme.primary,
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color statusColor;

  const _StatusBadge({required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
