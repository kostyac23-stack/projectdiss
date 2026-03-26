import 'package:flutter/material.dart';
import '../../domain/models/search_filters.dart';

/// Advanced filters screen with sort options
class AdvancedFiltersScreen extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onFiltersChanged;

  const AdvancedFiltersScreen({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  late SearchFilters _filters;
  String _sortBy = 'relevance'; // relevance, price_low, price_high, rating, distance

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _filters = SearchFilters();
      _sortBy = 'relevance';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters & Sort'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sort options
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            title: const Text('Relevance (Best Match)'),
            value: 'relevance',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Price: Low to High'),
            value: 'price_low',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Price: High to Low'),
            value: 'price_high',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Rating: Highest First'),
            value: 'rating',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Distance: Nearest First'),
            value: 'distance',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Price range
          Text(
            'Price Range',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(
              _filters.minPrice ?? 0,
              _filters.maxPrice ?? 1000,
            ),
            min: 0,
            max: 1000,
            divisions: 50,
            labels: RangeLabels(
              '\$${(_filters.minPrice ?? 0).toStringAsFixed(0)}',
              '\$${(_filters.maxPrice ?? 1000).toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() {
                _filters = _filters.copyWith(
                  minPrice: values.start,
                  maxPrice: values.end,
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Rating filter
          Text(
            'Minimum Rating',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _filters.minRating ?? 0.0,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            label: '${(_filters.minRating ?? 0.0).toStringAsFixed(1)} stars',
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(minRating: value);
              });
            },
          ),
          const SizedBox(height: 16),

          // Experience filter
          Text(
            'Minimum Experience (years)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: (_filters.minExperience ?? 0).toDouble(),
            min: 0,
            max: 20,
            divisions: 20,
            label: '${_filters.minExperience ?? 0} years',
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(minExperience: value.toInt());
              });
            },
          ),
          const SizedBox(height: 16),

          // Distance filter
          Text(
            'Maximum Distance (km)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _filters.maxDistanceKm ?? 50.0,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            label: '${(_filters.maxDistanceKm ?? 50.0).toStringAsFixed(0)} km',
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(maxDistanceKm: value);
              });
            },
          ),
          const SizedBox(height: 16),

          // Verified only
          SwitchListTile(
            title: const Text('Verified Specialists Only'),
            subtitle: const Text('Show only verified specialists'),
            value: _filters.verifiedOnly ?? false,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(verifiedOnly: value);
              });
            },
          ),
          const SizedBox(height: 32),

          // Apply button
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}

