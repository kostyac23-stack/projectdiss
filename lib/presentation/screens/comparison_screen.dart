import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/specialist.dart';
import '../../data/repositories/specialist_repository_impl.dart';

/// Side-by-side specialist comparison screen
class ComparisonScreen extends StatefulWidget {
  final List<int> specialistIds;

  const ComparisonScreen({super.key, required this.specialistIds});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final SpecialistRepositoryImpl _repo = SpecialistRepositoryImpl();
  List<Specialist> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  Future<void> _loadSpecialists() async {
    await _repo.initialize();
    final list = <Specialist>[];
    for (final id in widget.specialistIds) {
      final s = await _repo.getSpecialistById(id);
      if (s != null) list.add(s);
    }
    if (mounted) setState(() { _specialists = list; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
          ),
        ),
        title: Text('Compare Specialists', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _specialists.isEmpty
              ? const Center(child: Text('No specialists to compare'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _specialists.length * 200.0 + 120,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildHeaderRow(),
                          const Divider(height: 24, thickness: 2),
                          _buildComparisonRow('Category', _specialists.map((s) => s.category).toList(), Icons.work_outline),
                          _buildComparisonRow('Price/hr', _specialists.map((s) => '\$${s.price.toStringAsFixed(0)}').toList(), Icons.attach_money),
                          _buildRatingRow(),
                          _buildComparisonRow('Experience', _specialists.map((s) => '${s.experienceYears} years').toList(), Icons.timeline),
                          _buildSkillsRow(),
                          _buildComparisonRow('Verified', _specialists.map((s) => s.isVerified ? '✅ Yes' : '❌ No').toList(), Icons.verified),
                          if (_specialists.any((s) => s.address != null))
                            _buildComparisonRow('Location', _specialists.map((s) => s.address ?? 'N/A').toList(), Icons.location_on),
                          if (_specialists.any((s) => s.responseTimeHours != null))
                            _buildComparisonRow('Response Time', _specialists.map((s) => s.responseTimeHours != null ? '${s.responseTimeHours!.toStringAsFixed(1)}h' : 'N/A').toList(), Icons.schedule),
                          const SizedBox(height: 16),
                          _buildVerdictRow(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        const SizedBox(width: 120),
        ..._specialists.map((s) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                child: Text(s.name[0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFE53935))),
              ),
              const SizedBox(height: 8),
              Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildComparisonRow(String label, List<String> values, IconData icon) {
    // Find best value for highlighting
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
              ],
            ),
          ),
          ...values.map((v) => Expanded(
            child: Text(v, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          )),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    final maxRating = _specialists.map((s) => s.rating).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(child: Text('Rating', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
              ],
            ),
          ),
          ..._specialists.map((s) => Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 14, color: s.rating == maxRating && maxRating > 0 ? Colors.amber : Colors.grey),
                const SizedBox(width: 2),
                Text(s.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: s.rating == maxRating && maxRating > 0 ? Colors.amber[800] : null,
                    )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSkillsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Icon(Icons.build, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(child: Text('Skills', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
              ],
            ),
          ),
          ..._specialists.map((s) => Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: s.skills.take(5).map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(skill, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFE53935))),
              )).toList(),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildVerdictRow() {
    // Simple verdict: best overall based on rating + experience + price
    Specialist? best;
    double bestScore = -1;
    for (final s in _specialists) {
      final score = (s.rating / 5.0) * 0.4 + (s.experienceYears / 20.0).clamp(0, 1) * 0.3 + (1 - s.price / 300).clamp(0, 1) * 0.3;
      if (score > bestScore) { bestScore = score; best = s; }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Overall Match', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(best?.name ?? 'N/A', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${(bestScore * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
