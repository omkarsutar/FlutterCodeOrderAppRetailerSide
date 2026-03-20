import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/models/entity_meta.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import '../model/purchase_order_model.dart';
import '../providers/purchase_order_list_controller.dart';
import '../providers/purchase_order_providers.dart';
import 'purchase_order_list_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom Purchase Order List Page - Riverpod & JSON based
///
/// Single Responsibility: Display purchase orders with search, filtering, and navigation.
/// Focuses only on presentation and user interaction, delegating state management to Riverpod.
class PurchaseOrderListByShopID extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final List<String>? searchFields;
  final SortingConfig? initialSorting;

  const PurchaseOrderListByShopID({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.fieldConfigs,
    required this.timestampField,
    required this.viewRouteName,
    required this.newRouteName,
    required this.rbacModule,
    this.searchFields,
    this.initialSorting,
  });

  @override
  ConsumerState<PurchaseOrderListByShopID> createState() =>
      _PurchaseOrderListByShopIDState();
}

class _PurchaseOrderListByShopIDState
    extends ConsumerState<PurchaseOrderListByShopID> {
  final TextEditingController _searchController = TextEditingController();

  /// Get retailer shop_id from retailer_shop_link table
  Future<String?> _getRetailerShopId() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final link = await Supabase.instance.client
          .from('retailer_shop_link')
          .select('shop_id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      return link?['shop_id'] as String?;
    } catch (e) {
      debugPrint(
        'PurchaseOrderListByShopID: Error fetching retailer shop_id: $e',
      );
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(purchaseOrderServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );

        // Reset filters when entering this specialized view
        ref
            .read(
              purchaseOrderListControllerProvider('purchaseOrderList').notifier,
            )
            .resetFilters(searchFields: widget.searchFields);
      });
    } else {
      // Even if no initial sorting, reset filters to ensure a clean state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(
              purchaseOrderListControllerProvider('purchaseOrderList').notifier,
            )
            .resetFilters(searchFields: widget.searchFields);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get retailer shop_id dynamically
    return FutureBuilder<String?>(
      future: _getRetailerShopId(),
      builder: (context, snapshot) {
        final filterShopId = snapshot.data;

        // Watch controller state (handles loading, errors, filtering)
        final listState = ref.watch(
          purchaseOrderListControllerProvider('purchaseOrderList'),
        );

        final displayList = filterShopId != null
            ? listState.filteredPurchaseOrders
                  .where((po) => po.poShopId == filterShopId)
                  .toList()
            : listState.filteredPurchaseOrders;

        // Create a mutable copy and sort by creation date (latest first)
        final sortedDisplayList = List<ModelPurchaseOrder>.from(displayList);
        sortedDisplayList.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1; // null dates go to bottom
          if (b.createdAt == null) return -1; // null dates go to bottom
          return b.createdAt!.compareTo(a.createdAt!); // descending order
        });

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: CustomAppBar(
            title: widget.entityMeta.entityNamePlural,
            showBack: false, // Show drawer icon instead of back button
          ),
          drawer: const CustomDrawer(),
          /* floatingActionButton: CreateEntityButton(
            moduleName: ModelPurchaseOrderFields.table,
            newRouteName: widget.newRouteName,
            entityLabel: widget.entityMeta.entityName,
          ), */
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.25,
                  ),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Purchase Orders List
                Expanded(
                  child: _buildListContent(theme, listState, sortedDisplayList),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the list content based on controller state
  /// Handles loading, error, and data states
  Widget _buildListContent(
    ThemeData theme,
    PurchaseOrderListState listState,
    List<ModelPurchaseOrder> displayList,
  ) {
    // Loading state
    if (listState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (listState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading ${widget.entityMeta.entityNamePluralLower}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              listState.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(
                      purchaseOrderListControllerProvider(
                        'purchaseOrderList',
                      ).notifier,
                    )
                    .refreshData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              listState.searchQuery.isEmpty
                  ? 'No ${widget.entityMeta.entityNamePluralLower} found'
                  : 'No matching ${widget.entityMeta.entityNamePluralLower}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(
              purchaseOrderListControllerProvider('purchaseOrderList').notifier,
            )
            .refreshData();
      },
      child: _buildList(displayList),
    );
  }

  /// Builds the ListView of purchase orders
  Widget _buildList(List<ModelPurchaseOrder> displayList) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayList.length + 1,
      itemBuilder: (context, index) {
        if (index < displayList.length) {
          final displayListItem = displayList[index];
          return PurchaseOrderListTile(
            entity: displayListItem,
            adapter: ref.watch(purchaseOrderAdapterProvider),
            onTap: () => null,
          );
        } else {
          // Bottom padding for FAB
          return const SizedBox(height: 80);
        }
      },
    );
  }
}
