import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_provider.dart';
import '../../domain/models/search_filters.dart';
import '../../domain/models/matching_weights.dart';
import '../../data/services/settings_service.dart';

/// Full-page filter screen combining search filters + matching weights
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  final SettingsService _settingsService = SettingsService();

  // Search filters
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  int? _minExperience;
  double? _maxDistance;

  // Matching weights
  MatchingWeights? _weights;
  bool _isLoading = true;

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final provider = context.read<SpecialistProvider>();
    final filters = provider.filters;
    final weights = await _settingsService.getWeights();
    setState(() {
      _selectedCategory = filters.category;
      _minPrice = filters.minPrice;
      _maxPrice = filters.maxPrice;
      _minRating = filters.minRating;
      _minExperience = filters.minExperience;
      _maxDistance = filters.maxDistanceKm;
      _minPriceController.text = _minPrice?.toStringAsFixed(0) ?? '';
      _maxPriceController.text = _maxPrice?.toStringAsFixed(0) ?? '';
      _weights = weights;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final provider = context.read<SpecialistProvider>();
    provider.updateFilters(
      SearchFilters(
        keyword: provider.filters.keyword,
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        minExperience: _minExperience,
        maxDistanceKm: _maxDistance,
        userLatitude: provider.userLatitude,
        userLongitude: provider.userLongitude,
      ),
    );
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _minExperience = null;
      _maxDistance = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    final provider = context.read<SpecialistProvider>();
    provider.clearFilters();
    Navigator.pop(context);
  }

  Future<void> _updateWeights(MatchingWeights newWeights) async {
    setState(() => _weights = newWeights);
    if (mounted) {
      // Use provider.updateWeights() so the provider's internal _weights
      // are updated BEFORE re-ranking — this makes scores update correctly
      await context.read<SpecialistProvider>().updateWeights(newWeights);
    }
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
        title: Text('Filters & Preferences', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: Text('Clear All', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- SEARCH FILTERS ---
                _sectionHeader('Search Filters', Icons.filter_list_rounded),
                const SizedBox(height: 16),

                _buildCategoryFilter(),
                const SizedBox(height: 20),
                _buildPriceFilter(),
                const SizedBox(height: 20),
                _buildRatingFilter(),
                const SizedBox(height: 20),
                _buildExperienceFilter(),
                const SizedBox(height: 20),
                _buildDistanceFilter(),

                const SizedBox(height: 32),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),

                // --- MATCHING WEIGHTS ---
                _sectionHeader('Matching Priorities', Icons.tune_rounded),
                const SizedBox(height: 6),
                Text(
                  'Adjust how much each factor matters when ranking specialists',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),

                if (_weights != null) ...[
                  _buildWeightSlider('Skills Match', _weights!.skills, Icons.psychology_rounded, const Color(0xFF6366F1)),
                  _buildWeightSlider('Price', _weights!.price, Icons.attach_money_rounded, const Color(0xFF10B981)),
                  _buildWeightSlider('Location', _weights!.location, Icons.location_on_rounded, const Color(0xFF0EA5E9)),
                  _buildWeightSlider('Rating', _weights!.rating, Icons.star_rounded, const Color(0xFFF59E0B)),
                  _buildWeightSlider('Experience', _weights!.experience, Icons.work_rounded, const Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          'Total: ${((_weights!.skills + _weights!.price + _weights!.location + _weights!.rating + _weights!.experience) * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
              ],
            ),

      // Apply button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
            boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Apply Filters', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFE53935)),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    const categories = [
      'Plumber', 'Electrician', 'Carpenter', 'Painter',
      'Designer', 'Developer', 'Consultant', 'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = isSelected ? null : category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE53935) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Range', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min',
                  prefixText: '\$ ',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                ),
                onChanged: (v) => _minPrice = double.tryParse(v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('—', style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF94A3B8))),
            ),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max',
                  prefixText: '\$ ',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                ),
                onChanged: (v) => _maxPrice = double.tryParse(v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Minimum Rating', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
              child: Text(
                _minRating != null ? '${_minRating!.toStringAsFixed(1)} ⭐' : 'Any',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
              ),
            ),
          ],
        ),
        Slider(
          value: _minRating ?? 0.0,
          min: 0.0,
          max: 5.0,
          divisions: 50,
          onChanged: (v) => setState(() => _minRating = v),
        ),
      ],
    );
  }

  Widget _buildExperienceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min Experience', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8)),
              child: Text(
                _minExperience != null ? '$_minExperience yrs' : 'Any',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
        Slider(
          value: _minExperience?.toDouble() ?? 0.0,
          min: 0.0,
          max: 20.0,
          divisions: 20,
          onChanged: (v) => setState(() => _minExperience = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Max Distance', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
              child: Text(
                _maxDistance != null ? '${_maxDistance!.toStringAsFixed(0)} km' : 'Any',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
              ),
            ),
          ],
        ),
        Slider(
          value: _maxDistance ?? 0.0,
          min: 0.0,
          max: 100.0,
          divisions: 100,
          onChanged: (v) => setState(() => _maxDistance = v),
        ),
      ],
    );
  }

  Widget _buildWeightSlider(String label, double value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(activeTrackColor: color, thumbColor: color, inactiveTrackColor: color.withOpacity(0.15)),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: (newValue) {
                final currentTotal = _weights!.skills + _weights!.price +
                    _weights!.location + _weights!.rating + _weights!.experience;
                final otherTotal = currentTotal - value;
                final scale = otherTotal > 0 ? (1.0 - newValue) / otherTotal : 1.0;

                final updated = _weights!.copyWith(
                  skills: label == 'Skills Match' ? newValue : _weights!.skills * scale,
                  price: label == 'Price' ? newValue : _weights!.price * scale,
                  location: label == 'Location' ? newValue : _weights!.location * scale,
                  rating: label == 'Rating' ? newValue : _weights!.rating * scale,
                  experience: label == 'Experience' ? newValue : _weights!.experience * scale,
                );
                _updateWeights(updated);
              },
            ),
          ),
        ],
      ),
    );
  }
}
