import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/task_request.dart';
import '../../data/repositories/task_request_repository_impl.dart';
import 'task_request_detail_screen.dart';

/// Client's view of their posted task requests
class MyRequestsScreen extends StatefulWidget {
  final int clientId;

  const MyRequestsScreen({super.key, required this.clientId});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _repo = TaskRequestRepositoryImpl();
  List<TaskRequest> _requests = [];
  Map<int, int> _bidCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      await _repo.initialize();
      final requests = await _repo.getRequestsByClientId(widget.clientId);
      final bidCounts = <int, int>{};
      for (final r in requests) {
        if (r.id != null) {
          bidCounts[r.id!] = await _repo.getBidCountForRequest(r.id!);
        }
      }
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _bidCounts = bidCounts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('No requests yet', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF9CA3AF))),
            const SizedBox(height: 4),
            Text('Post your first task request!', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFD1D5DB))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final r = _requests[index];
          final bidCount = _bidCounts[r.id] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskRequestDetailScreen(requestId: r.id!, isSpecialist: false),
                    ),
                  );
                  _loadRequests();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_categoryIcon(r.category), size: 22, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.category, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              r.description,
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _statusBadge(r.status),
                                const SizedBox(width: 8),
                                if (bidCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$bidCount bid${bidCount != 1 ? 's' : ''}',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFE53935)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(TaskRequestStatus status) {
    Color color;
    switch (status) {
      case TaskRequestStatus.open: color = const Color(0xFF10B981);
      case TaskRequestStatus.inProgress: color = const Color(0xFF3B82F6);
      case TaskRequestStatus.completed: color = const Color(0xFF6366F1);
      case TaskRequestStatus.cancelled: color = const Color(0xFF94A3B8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Plumbing': return Icons.plumbing_rounded;
      case 'Electrical': return Icons.electrical_services_rounded;
      case 'Cleaning': return Icons.cleaning_services_rounded;
      case 'Tutoring': return Icons.school_rounded;
      case 'Beauty': return Icons.spa_rounded;
      default: return Icons.miscellaneous_services_rounded;
    }
  }
}
