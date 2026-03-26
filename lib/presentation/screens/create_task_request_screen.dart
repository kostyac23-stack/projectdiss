import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/models/task_request.dart';
import '../../data/repositories/task_request_repository_impl.dart';
import '../providers/auth_provider.dart';

/// Screen for clients to create a new task request (Profi.ru style)
class CreateTaskRequestScreen extends StatefulWidget {
  const CreateTaskRequestScreen({super.key});

  @override
  State<CreateTaskRequestScreen> createState() => _CreateTaskRequestScreenState();
}

class _CreateTaskRequestScreenState extends State<CreateTaskRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _repo = TaskRequestRepositoryImpl();

  String _selectedCategory = 'Plumbing';
  TaskUrgency _selectedUrgency = TaskUrgency.flexible;
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Cleaning', 'Tutoring', 'Beauty',
    'Repair', 'Moving', 'IT & Tech', 'Design', 'Photography',
    'Fitness', 'Cooking', 'Legal', 'Accounting', 'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user == null) return;

      await _repo.initialize();
      final request = TaskRequest(
        clientId: user.id!,
        clientName: user.name,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        budgetMin: double.tryParse(_budgetMinController.text),
        budgetMax: double.tryParse(_budgetMaxController.text),
        preferredDate: _preferredDate,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        urgency: _selectedUrgency,
        createdAt: DateTime.now(),
      );

      await _repo.createTaskRequest(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request posted successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFFF6B6B)],
            ),
          ),
        ),
        title: Text('Post a Request', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'What do you need help with?',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Describe your task and specialists will respond with offers',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),

              // Category
              _sectionLabel('Service Category'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B)),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              _sectionLabel('Task Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what you need in detail...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                ),
                validator: (v) => (v == null || v.trim().length < 10) ? 'Please provide a detailed description (min 10 chars)' : null,
              ),
              const SizedBox(height: 20),

              // Budget range
              _sectionLabel('Budget Range (\$)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('—', style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF94A3B8))),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMaxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              _sectionLabel('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Address or "Remote"',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 20),

              // Preferred date
              _sectionLabel('Preferred Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _preferredDate != null
                            ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                            : 'Select a date (optional)',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: _preferredDate != null ? const Color(0xFF1E293B) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Urgency
              _sectionLabel('Urgency'),
              const SizedBox(height: 10),
              Row(
                children: TaskUrgency.values.map((u) {
                  final isSelected = _selectedUrgency == u;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedUrgency = u),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE53935) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              u == TaskUrgency.asap
                                  ? Icons.flash_on_rounded
                                  : u == TaskUrgency.withinWeek
                                      ? Icons.schedule_rounded
                                      : Icons.pending_outlined,
                              size: 22,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              u.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF6B6B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Posting...' : 'Post Request',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
    );
  }
}
