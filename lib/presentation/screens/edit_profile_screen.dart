import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/user.dart';
import '../../domain/models/specialist_profile.dart';
import '../../domain/models/specialist.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/specialist_profile_repository_impl.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import '../providers/auth_provider.dart';
import '../providers/specialist_provider.dart';

/// Modern edit profile screen with sectioned layout and styled inputs
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Specialist-specific fields
  final _categoryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _tagsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _responseTimeController = TextEditingController();
  final _experienceController = TextEditingController();
  
  final _authRepository = AuthRepositoryImpl();
  final _specialistProfileRepo = SpecialistProfileRepositoryImpl();
  final _specialistRepository = SpecialistRepositoryImpl();
  
  bool _isLoading = true;
  bool _isSaving = false;
  User? _currentUser;
  SpecialistProfile? _specialistProfile;
  bool _isSpecialist = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    _skillsController.dispose();
    _priceController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _tagsController.dispose();
    _availabilityController.dispose();
    _responseTimeController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _currentUser = user;
      _isSpecialist = user.role == UserRole.specialist;
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
      if (user.profileImagePath != null) {
        _selectedImage = File(user.profileImagePath!);
      }
    });

    if (_isSpecialist) {
      await _specialistProfileRepo.initialize();
      final profile = await _specialistProfileRepo.getProfileByUserId(user.id!);
      
      if (profile != null && mounted) {
        await _specialistRepository.initialize();
        final specialist = profile.specialistId != null
            ? await _specialistRepository.getSpecialistById(profile.specialistId!)
            : null;

        setState(() {
          _specialistProfile = profile;
          _categoryController.text = profile.category;
          _skillsController.text = profile.skills.join(', ');
          _priceController.text = profile.price.toStringAsFixed(0);
          _bioController.text = profile.bio ?? '';
          _addressController.text = profile.address ?? '';
          _tagsController.text = profile.tags.join(', ');
          _availabilityController.text = profile.availabilityNotes ?? '';
          _responseTimeController.text = profile.responseTimeHours?.toStringAsFixed(1) ?? '';
          _experienceController.text = specialist?.experienceYears.toString() ?? '0';
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user == null) return;

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        profileImagePath: _selectedImage?.path ?? user.profileImagePath,
      );
      
      await _authRepository.updateUser(updatedUser);
      authProvider.refreshUser();
      PaintingBinding.instance.imageCache.clear();

      if (_isSpecialist) {
        await _specialistRepository.initialize();
        
        final skills = _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final tags = _tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        int? specialistId = _specialistProfile?.specialistId;

        if (specialistId == null) {
          final specialist = Specialist(
            name: user.name,
            category: _categoryController.text.trim(),
            skills: skills,
            price: double.tryParse(_priceController.text) ?? 0.0,
            rating: 0.0,
            experienceYears: int.tryParse(_experienceController.text) ?? 0,
            bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            tags: tags,
            availabilityNotes: _availabilityController.text.trim().isEmpty ? null : _availabilityController.text.trim(),
            isVerified: _specialistProfile?.isVerified ?? false,
            responseTimeHours: _responseTimeController.text.trim().isEmpty ? null : double.tryParse(_responseTimeController.text),
            imagePath: _selectedImage?.path ?? user.profileImagePath,
          );
          specialistId = await _specialistRepository.insertSpecialist(specialist);
        } else {
          final specialist = await _specialistRepository.getSpecialistById(specialistId);
          if (specialist != null) {
            final updatedSpecialist = specialist.copyWith(
              name: user.name,
              category: _categoryController.text.trim(),
              skills: skills,
              price: double.tryParse(_priceController.text) ?? 0.0,
              experienceYears: int.tryParse(_experienceController.text) ?? specialist.experienceYears,
              bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
              address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
              tags: tags,
              availabilityNotes: _availabilityController.text.trim().isEmpty ? null : _availabilityController.text.trim(),
              responseTimeHours: _responseTimeController.text.trim().isEmpty ? null : double.tryParse(_responseTimeController.text),
              imagePath: _selectedImage?.path ?? user.profileImagePath,
            );
            await _specialistRepository.updateSpecialist(updatedSpecialist);
          } else {
            // The specialist was deleted from the raw database (e.g. via DevTools). Recreate it!
            final newSpecialist = Specialist(
              name: user.name,
              category: _categoryController.text.trim(),
              skills: skills,
              price: double.tryParse(_priceController.text) ?? 0.0,
              rating: 0.0,
              experienceYears: int.tryParse(_experienceController.text) ?? 0,
              bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
              address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
              tags: tags,
              availabilityNotes: _availabilityController.text.trim().isEmpty ? null : _availabilityController.text.trim(),
              isVerified: _specialistProfile?.isVerified ?? false,
              responseTimeHours: _responseTimeController.text.trim().isEmpty ? null : double.tryParse(_responseTimeController.text),
              imagePath: _selectedImage?.path ?? user.profileImagePath,
            );
            specialistId = await _specialistRepository.insertSpecialist(newSpecialist);
          }
        }

        final profile = SpecialistProfile(
          id: _specialistProfile?.id,
          userId: user.id!,
          specialistId: specialistId,
          category: _categoryController.text.trim(),
          skills: skills,
          price: double.tryParse(_priceController.text) ?? 0.0,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          tags: tags,
          availabilityNotes: _availabilityController.text.trim().isEmpty ? null : _availabilityController.text.trim(),
          responseTimeHours: _responseTimeController.text.trim().isEmpty ? null : double.tryParse(_responseTimeController.text),
          isVerified: _specialistProfile?.isVerified ?? false,
        );

        await _specialistProfileRepo.saveProfile(profile);
        
        // Refresh the Search Discovery feed actively!
        if (mounted) {
          await context.read<SpecialistProvider>().loadRankedSpecialists(isQuietRefresh: true);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Profile updated!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]))),
          title: Text('Edit Profile', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]))),
        title: Text('Edit Profile', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, color: Colors.white, size: 20),
            label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFE53935).withValues(alpha: 0.05), Colors.transparent],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Change Photo', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
                                  ),
                                  title: Text('Take a Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                  subtitle: Text('Use your camera', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: const Color(0xFF6A1B9A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.photo_library, color: Color(0xFF6A1B9A)),
                                  ),
                                  title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                  subtitle: Text('Pick an existing photo', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _selectedImage == null ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]) : null,
                            image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                            boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.2), blurRadius: 12)],
                          ),
                          child: _selectedImage == null ? Center(
                            child: Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ) : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                    ),
                    Text('Tap to change photo', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),

              // Personal info section
              _buildSection('Personal Information', Icons.person_outline, [
                _buildField(_nameController, 'Full Name', Icons.person, required: true),
                _buildField(_emailController, 'Email', Icons.email, enabled: false),
                _buildField(_phoneController, 'Phone Number', Icons.phone, type: TextInputType.phone),
              ]),

              // Specialist info section
              if (_isSpecialist) ...[
                _buildSection('Professional Details', Icons.work_outline, [
                  _buildField(_categoryController, 'Service Category', Icons.category, required: true, hint: 'e.g., Plumber, Electrician'),
                  _buildField(_skillsController, 'Skills', Icons.build, required: true, hint: 'Comma-separated', maxLines: 2),
                  Row(
                    children: [
                      Expanded(child: _buildField(_priceController, 'Price (\$/hr)', Icons.attach_money, required: true, type: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(_experienceController, 'Experience (yrs)', Icons.timeline, type: TextInputType.number)),
                    ],
                  ),
                  _buildField(_responseTimeController, 'Avg. Response Time (hours)', Icons.access_time, type: TextInputType.number),
                ]),

                _buildSection('About You', Icons.description_outlined, [
                  _buildField(_bioController, 'Bio', Icons.description, hint: 'Tell clients about yourself and your experience...', maxLines: 4),
                  _buildField(_addressController, 'Service Location', Icons.location_on, hint: 'City or address'),
                ]),

                _buildSection('Discoverability', Icons.tag, [
                  _buildField(_tagsController, 'Tags', Icons.label, hint: 'Comma-separated tags for search'),
                  _buildField(_availabilityController, 'Availability', Icons.calendar_today, hint: 'e.g., Mon-Fri 9am-6pm', maxLines: 2),
                ]),
              ],

              // Save button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE53935), size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          ...children.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, String label, IconData icon, {
    bool required = false, bool enabled = true, String? hint,
    int maxLines = 1, TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: type,
      style: GoogleFonts.inter(fontSize: 14, color: enabled ? const Color(0xFF1E293B) : Colors.grey[500]),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[350]),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) return 'This field is required';
        return null;
      } : null,
    );
  }
}
