import 'package:flutter/material.dart';
import '../../domain/models/availability.dart';
import '../../data/repositories/availability_repository_impl.dart';

/// Screen for managing specialist availability schedule
class AvailabilityScreen extends StatefulWidget {
  final int specialistId;

  const AvailabilityScreen({super.key, required this.specialistId});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final AvailabilityRepositoryImpl _availabilityRepo = AvailabilityRepositoryImpl();
  Map<int, Availability> _availability = {};
  Map<int, TextEditingController> _startTimeControllers = {};
  Map<int, TextEditingController> _endTimeControllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void dispose() {
    for (final controller in _startTimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _endTimeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    await _availabilityRepo.initialize();
    final availability = await _availabilityRepo.getAvailabilityBySpecialistId(widget.specialistId);

    final Map<int, Availability> availabilityMap = {};
    final Map<int, TextEditingController> startControllers = {};
    final Map<int, TextEditingController> endControllers = {};

    for (int day = 0; day < 7; day++) {
      final existing = availability.firstWhere(
        (a) => a.dayOfWeek == day,
        orElse: () => Availability(
          specialistId: widget.specialistId,
          dayOfWeek: day,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: false,
        ),
      );

      availabilityMap[day] = existing;
      startControllers[day] = TextEditingController(text: existing.startTime);
      endControllers[day] = TextEditingController(text: existing.endTime);
    }

    if (mounted) {
      setState(() {
        _availability = availabilityMap;
        _startTimeControllers = startControllers;
        _endTimeControllers = endControllers;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final availabilityList = <Availability>[];

      for (int day = 0; day < 7; day++) {
        final avail = _availability[day]!;
        availabilityList.add(avail.copyWith(
          startTime: _startTimeControllers[day]!.text,
          endTime: _endTimeControllers[day]!.text,
        ));
      }

      await _availabilityRepo.saveAvailability(widget.specialistId, availabilityList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving availability: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Schedule'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAvailability,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Set your weekly availability',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          
          ...List.generate(7, (index) {
            final day = index;
            final avail = _availability[day]!;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _days[day],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Switch(
                          value: avail.isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _availability[day] = avail.copyWith(isAvailable: value);
                            });
                          },
                        ),
                      ],
                    ),
                    if (avail.isAvailable) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startTimeControllers[day],
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                hintText: '09:00',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('to', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _endTimeControllers[day],
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                hintText: '17:00',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveAvailability,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Availability'),
          ),
        ],
      ),
    );
  }
}

