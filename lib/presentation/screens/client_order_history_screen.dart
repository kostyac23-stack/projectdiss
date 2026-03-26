import 'package:flutter/material.dart';
import '../../domain/models/order.dart';
import '../../domain/models/specialist.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import 'order_detail_screen.dart';
import 'add_review_screen.dart';
import 'create_order_screen.dart';

/// Screen for clients to view their order history
class ClientOrderHistoryScreen extends StatefulWidget {
  final String clientName;

  const ClientOrderHistoryScreen({super.key, required this.clientName});

  @override
  State<ClientOrderHistoryScreen> createState() => _ClientOrderHistoryScreenState();
}

class _ClientOrderHistoryScreenState extends State<ClientOrderHistoryScreen> {
  final OrderRepositoryImpl _orderRepo = OrderRepositoryImpl();
  final SpecialistRepositoryImpl _specialistRepo = SpecialistRepositoryImpl();
  
  List<Order> _orders = [];
  Map<int, Specialist?> _specialists = {};
  bool _isLoading = true;
  OrderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    await _orderRepo.initialize();
    await _specialistRepo.initialize();

    final allOrders = await _orderRepo.getAllOrders();
    final myOrders = allOrders.where((o) => o.clientName == widget.clientName).toList();
    
    final filteredOrders = _filterStatus != null
        ? myOrders.where((o) => o.status == _filterStatus).toList()
        : myOrders;

    final specialists = <int, Specialist?>{};
    for (final order in filteredOrders) {
      if (!specialists.containsKey(order.specialistId)) {
        final specialist = await _specialistRepo.getSpecialistById(order.specialistId);
        specialists[order.specialistId] = specialist;
      }
    }

    if (mounted) {
      setState(() {
        _orders = filteredOrders;
        _specialists = specialists;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Material(
      child: Column(
      children: [
        // Inline filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildStatusChip(null, 'All'),
              ...OrderStatus.values.map((status) =>
                  _buildStatusChip(status, status.displayName)),
            ],
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No orders yet', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Your order history will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final specialist = _specialists[order.specialistId];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(orderId: order.id!),
                              ),
                            ).then((_) => _loadOrders());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (specialist != null)
                                            Text(
                                              specialist.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          if (specialist != null)
                                            Text(
                                              specialist.category,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getStatusColor(order.status)),
                                      ),
                                      child: Text(
                                        order.status.displayName,
                                        style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(order.serviceDescription, style: Theme.of(context).textTheme.bodyMedium),
                                if (order.price != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Price: \$${order.price!.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Created: ${_formatDate(order.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                ),
                                if (order.status == OrderStatus.completed) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AddReviewScreen(specialistId: order.specialistId),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.star, size: 16),
                                          label: const Text('Review', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (specialist != null)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CreateOrderScreen(specialist: specialist),
                                                ),
                                              ).then((_) => _loadOrders());
                                            },
                                            icon: const Icon(Icons.replay, size: 16),
                                            label: const Text('Book Again', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFE53935),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus? status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _filterStatus = isSelected ? null : status);
          _loadOrders();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE53935) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFFE53935) : Colors.grey[300]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

