import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/specialist.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import 'specialist_detail_screen.dart';

/// Map-style view showing specialists as positioned cards based on location
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final SpecialistRepositoryImpl _repo = SpecialistRepositoryImpl();
  List<Specialist> _specialists = [];
  bool _isLoading = true;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  Future<void> _loadSpecialists() async {
    await _repo.initialize();
    final all = await _repo.getAllSpecialists();
    final cats = all.map((s) => s.category).toSet().toList()..sort();
    final filtered = _selectedCategory != null
        ? all.where((s) => s.category == _selectedCategory).toList()
        : all;
    if (mounted) setState(() { _specialists = filtered; _categories = cats; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0277BD), Color(0xFF4FC3F7)]),
          ),
        ),
        title: Text('Specialist Map', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category filter
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      _buildCatChip(null, 'All'),
                      ..._categories.map((c) => _buildCatChip(c, c)),
                    ],
                  ),
                ),
                
                // Map area with positioned specialist pins
                Expanded(
                  child: _specialists.isEmpty
                      ? Center(child: Text('No specialists found', style: GoogleFonts.inter(color: Colors.grey)))
                      : Stack(
                          children: [
                            // Grid background simulating a map
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                image: DecorationImage(
                                  image: const AssetImage('assets/images/app_icon.png'),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Colors.grey[200]!.withValues(alpha: 0.3), BlendMode.lighten),
                                  opacity: 0.05,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _GridPainter(),
                                size: Size.infinite,
                              ),
                            ),
                            // Specialist pins
                            ..._specialists.asMap().entries.map((entry) {
                              final index = entry.key;
                              final specialist = entry.value;
                              // Position based on lat/lon or deterministic pseudo-random
                              final dx = specialist.latitude != null
                                  ? ((specialist.latitude! % 1).abs() * 0.8 + 0.1)
                                  : ((index * 137 + 50) % 100) / 120.0 + 0.05;
                              final dy = specialist.longitude != null
                                  ? ((specialist.longitude! % 1).abs() * 0.7 + 0.1)
                                  : ((index * 83 + 30) % 100) / 120.0 + 0.1;

                              return Positioned(
                                left: MediaQuery.of(context).size.width * dx,
                                top: (MediaQuery.of(context).size.height * 0.5) * dy,
                                child: GestureDetector(
                                  onTap: () => _showSpecialistPopup(specialist),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
                                          border: Border.all(color: const Color(0xFFE53935), width: 1.5),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: const Color(0xFFE53935),
                                              child: Text(specialist.name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(specialist.name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                                                Text('\$${specialist.price.toStringAsFixed(0)}/hr',
                                                    style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600])),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Pin marker
                                      CustomPaint(
                                        painter: _PinPainter(),
                                        size: const Size(12, 8),
                                      ),
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53935),
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.3), blurRadius: 4)],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                ),
                
                // Bottom list
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    itemCount: _specialists.length,
                    itemBuilder: (context, index) {
                      final s = _specialists[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SpecialistDetailScreen(specialistId: s.id!),
                        )),
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(s.category, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.amber[600]),
                                  Text(' ${s.rating.toStringAsFixed(1)}', style: GoogleFonts.inter(fontSize: 11)),
                                  const Spacer(),
                                  Text('\$${s.price.toStringAsFixed(0)}/hr', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCatChip(String? cat, String label) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () { setState(() => _selectedCategory = cat); _loadSpecialists(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0277BD) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF0277BD) : Colors.grey[300]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showSpecialistPopup(Specialist specialist) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24, backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                  child: Text(specialist.name[0], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFE53935), fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(specialist.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(specialist.category, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('\$${specialist.price.toStringAsFixed(0)}/hr', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                Text(' ${specialist.rating.toStringAsFixed(1)}', style: GoogleFonts.inter(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                Text(' ${specialist.experienceYears}y exp', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                if (specialist.address != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  Expanded(child: Text(' ${specialist.address}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => SpecialistDetailScreen(specialistId: specialist.id!))); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('View Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withValues(alpha: 0.1)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE53935);
    final path = Path()
      ..moveTo(0, 0) ..lineTo(size.width, 0) ..lineTo(size.width / 2, size.height) ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
