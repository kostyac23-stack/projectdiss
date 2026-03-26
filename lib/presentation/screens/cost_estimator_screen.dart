import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/specialist.dart';
import '../../data/repositories/specialist_repository_impl.dart';

/// Cost estimator screen — estimates price range based on category and job scope
class CostEstimatorScreen extends StatefulWidget {
  const CostEstimatorScreen({super.key});

  @override
  State<CostEstimatorScreen> createState() => _CostEstimatorScreenState();
}

class _CostEstimatorScreenState extends State<CostEstimatorScreen> {
  final SpecialistRepositoryImpl _repo = SpecialistRepositoryImpl();
  String? _selectedCategory;
  double _complexity = 2; // 1=Simple, 2=Medium, 3=Complex
  double _hoursEstimate = 2;
  List<String> _categories = [];
  List<Specialist> _categorySpecialists = [];
  bool _isLoading = true;
  bool _hasEstimate = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await _repo.initialize();
    final all = await _repo.getAllSpecialists();
    final cats = all.map((s) => s.category).toSet().toList()..sort();
    if (mounted) setState(() { _categories = cats; _isLoading = false; });
  }

  Future<void> _estimate() async {
    if (_selectedCategory == null) return;
    final all = await _repo.getAllSpecialists();
    final filtered = all.where((s) => s.category == _selectedCategory).toList();
    setState(() {
      _categorySpecialists = filtered;
      _hasEstimate = true;
    });
  }

  double get _minPrice {
    if (_categorySpecialists.isEmpty) return 0;
    final prices = _categorySpecialists.map((s) => s.price).toList()..sort();
    return prices.first * _hoursEstimate * (_complexity * 0.5 + 0.5);
  }

  double get _maxPrice {
    if (_categorySpecialists.isEmpty) return 0;
    final prices = _categorySpecialists.map((s) => s.price).toList()..sort();
    return prices.last * _hoursEstimate * (_complexity * 0.5 + 0.5);
  }

  double get _avgPrice {
    if (_categorySpecialists.isEmpty) return 0;
    final avg = _categorySpecialists.map((s) => s.price).reduce((a, b) => a + b) / _categorySpecialists.length;
    return avg * _hoursEstimate * (_complexity * 0.5 + 0.5);
  }

  String get _complexityLabel {
    if (_complexity <= 1.5) return 'Simple';
    if (_complexity <= 2.5) return 'Medium';
    return 'Complex';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
          ),
        ),
        title: Text('Cost Estimator', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Category selector
                Text('Service Category', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a category'),
                      value: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() { _selectedCategory = v; _hasEstimate = false; }),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Complexity slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Job Complexity', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _complexity <= 1.5 ? Colors.green[100] : _complexity <= 2.5 ? Colors.orange[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_complexityLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12,
                          color: _complexity <= 1.5 ? Colors.green[800] : _complexity <= 2.5 ? Colors.orange[800] : Colors.red[800])),
                    ),
                  ],
                ),
                Slider(
                  value: _complexity,
                  min: 1, max: 3,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) { setState(() => _complexity = v); if (_selectedCategory != null) _estimate(); },
                ),

                const SizedBox(height: 16),

                // Hours estimate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Hours', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${_hoursEstimate.toStringAsFixed(0)}h', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2E7D32))),
                  ],
                ),
                Slider(
                  value: _hoursEstimate,
                  min: 1, max: 40,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) { setState(() => _hoursEstimate = v); if (_selectedCategory != null) _estimate(); },
                ),

                const SizedBox(height: 24),

                // Estimate button
                ElevatedButton(
                  onPressed: _selectedCategory != null ? _estimate : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Calculate Estimate', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                ),

                if (_hasEstimate && _categorySpecialists.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildResultCard(),
                  const SizedBox(height: 16),
                  Text('Based on ${_categorySpecialists.length} specialists in "${_selectedCategory}"',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
                ],

                if (_hasEstimate && _categorySpecialists.isEmpty) ...[
                  const SizedBox(height: 32),
                  Center(child: Text('No specialists found in this category',
                      style: GoogleFonts.inter(color: Colors.grey[600]))),
                ],
              ],
            ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('Estimated Cost Range', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPriceColumn('Low', _minPrice, Colors.white70),
              Container(width: 1, height: 50, color: Colors.white30),
              _buildPriceColumn('Average', _avgPrice, Colors.white),
              Container(width: 1, height: 50, color: Colors.white30),
              _buildPriceColumn('High', _maxPrice, Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '$_complexityLabel job • ${_hoursEstimate.toStringAsFixed(0)} hours',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceColumn(String label, double price, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text('\$${price.toStringAsFixed(0)}', style: GoogleFonts.inter(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
