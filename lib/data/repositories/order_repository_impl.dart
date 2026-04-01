import '../../domain/models/order.dart';
import '../database/database_helper.dart';

/// Repository for managing orders
class OrderRepositoryImpl {
  Future<void> initialize() async {
    await DatabaseHelper.database;
  }

  /// Get all orders
  Future<List<Order>> getAllOrders() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableOrders,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  /// Get orders by specialist ID
  Future<List<Order>> getOrdersBySpecialistId(int specialistId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableOrders,
      where: 'specialist_id = ?',
      whereArgs: [specialistId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableOrders,
      where: 'status = ?',
      whereArgs: [status.toString()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  /// Get order by ID
  Future<Order?> getOrderById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableOrders,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  /// Create a new order
  Future<int> insertOrder(Order order) async {
    final db = await DatabaseHelper.database;
    final orderMap = order.toMap();
    orderMap['created_at'] = DateTime.now().toIso8601String();
    orderMap['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert(
      DatabaseHelper.tableOrders,
      orderMap,
    );
  }

  /// Update an order
  Future<int> updateOrder(Order order) async {
    if (order.id == null) {
      throw ArgumentError('Order ID is required for update');
    }
    final db = await DatabaseHelper.database;
    final orderMap = order.toMap();
    orderMap['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      DatabaseHelper.tableOrders,
      orderMap,
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  /// Update order status
  Future<int> updateOrderStatus(int orderId, OrderStatus status) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      DatabaseHelper.tableOrders,
      {
        'status': status.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  /// Delete an order
  Future<int> deleteOrder(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableOrders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get order count by status
  Future<Map<OrderStatus, int>> getOrderCountsByStatus() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM ${DatabaseHelper.tableOrders}
      GROUP BY status
    ''');
    
    final counts = <OrderStatus, int>{};
    for (final row in result) {
      final status = OrderStatus.fromString(row['status'] as String);
      counts[status] = row['count'] as int;
    }
    
    // Initialize all statuses with 0
    for (final status in OrderStatus.values) {
      counts.putIfAbsent(status, () => 0);
    }
    
    return counts;
  }
}

