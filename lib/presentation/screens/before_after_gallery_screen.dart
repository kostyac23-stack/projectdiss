import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/before_after_project.dart';
import '../../data/repositories/before_after_repository_impl.dart';
import '../widgets/full_screen_image_viewer.dart';

/// Gallery screen showing before/after project showcases
class BeforeAfterGalleryScreen extends StatefulWidget {
  final int specialistId;
  final String specialistName;
  final String category;
  final bool isOwnProfile;

  const BeforeAfterGalleryScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
    required this.category,
    this.isOwnProfile = false,
  });

  @override
  State<BeforeAfterGalleryScreen> createState() => _BeforeAfterGalleryScreenState();
}

class _BeforeAfterGalleryScreenState extends State<BeforeAfterGalleryScreen> {
  final BeforeAfterRepositoryImpl _repo = BeforeAfterRepositoryImpl();
  List<BeforeAfterProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    await _repo.initialize();
    await _repo.seedDemoProjects(widget.specialistId, widget.category);
    final projects = await _repo.getProjects(widget.specialistId);
    if (mounted) setState(() { _projects = projects; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
          ),
        ),
        title: Text('Work Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No projects yet', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return _buildProjectCard(project);
                  },
                ),
      floatingActionButton: widget.isOwnProfile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF6A1B9A),
              onPressed: () => _showAddDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildProjectCard(BeforeAfterProject project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6A1B9A).withOpacity(0.05), const Color(0xFFAB47BC).withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.compare, color: Color(0xFF6A1B9A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (project.description != null)
                        Text(project.description!, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (widget.isOwnProfile)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                    onPressed: () async {
                      await _repo.deleteProject(project.id!);
                      _loadProjects();
                    },
                  ),
              ],
            ),
          ),
          
          // Before / After sections
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Before
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 14, color: Colors.red[400]),
                            const SizedBox(width: 4),
                            Text('BEFORE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700], letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: project.beforeImagePath == null ? Colors.red[100] : null,
                            borderRadius: BorderRadius.circular(8),
                            image: project.beforeImagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(project.beforeImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: project.beforeImagePath == null
                              ? Icon(Icons.photo_outlined, size: 32, color: Colors.red[300])
                              : Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(imageProvider: FileImage(File(project.beforeImagePath!)), heroTag: 'before_${project.id}'),
                                      ));
                                    },
                                  ),
                                ),
                        ),
                        if (project.beforeDescription != null) ...[
                          const SizedBox(height: 8),
                          Text(project.beforeDescription!, style: GoogleFonts.inter(fontSize: 11, color: Colors.red[800]),
                              textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_forward, color: Colors.grey[400]),
                      const SizedBox(height: 4),
                      Icon(Icons.auto_awesome, size: 16, color: Colors.amber[600]),
                    ],
                  ),
                ),
                
                // After
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('AFTER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700], letterSpacing: 1)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14, color: Colors.green[400]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: project.afterImagePath == null ? Colors.green[100] : null,
                            borderRadius: BorderRadius.circular(8),
                            image: project.afterImagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(project.afterImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: project.afterImagePath == null
                              ? Icon(Icons.photo_outlined, size: 32, color: Colors.green[300])
                              : Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(imageProvider: FileImage(File(project.afterImagePath!)), heroTag: 'after_${project.id}'),
                                      ));
                                    },
                                  ),
                                ),
                        ),
                        if (project.afterDescription != null) ...[
                          const SizedBox(height: 8),
                          Text(project.afterDescription!, style: GoogleFonts.inter(fontSize: 11, color: Colors.green[800]),
                              textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(project.category, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final beforeCtrl = TextEditingController();
    final afterCtrl = TextEditingController();
    String? beforeImagePath;
    String? afterImagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Project', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.gallery);
                          if (file != null) setDialogState(() => beforeImagePath = file.path);
                        },
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red[50], border: Border.all(color: Colors.red[200]!), borderRadius: BorderRadius.circular(8),
                          ),
                          child: beforeImagePath != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(beforeImagePath!), fit: BoxFit.cover))
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.red[400]), Text('Add Before', style: TextStyle(fontSize: 10, color: Colors.red[800])),
                                ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.gallery);
                          if (file != null) setDialogState(() => afterImagePath = file.path);
                        },
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.green[50], border: Border.all(color: Colors.green[200]!), borderRadius: BorderRadius.circular(8),
                          ),
                          child: afterImagePath != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(afterImagePath!), fit: BoxFit.cover))
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.green[400]), Text('Add After', style: TextStyle(fontSize: 10, color: Colors.green[800])),
                                ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: beforeCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Before Description', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: afterCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'After Description', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await _repo.addProject(BeforeAfterProject(
                specialistId: widget.specialistId,
                title: titleCtrl.text,
                description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                beforeDescription: beforeCtrl.text.isNotEmpty ? beforeCtrl.text : null,
                afterDescription: afterCtrl.text.isNotEmpty ? afterCtrl.text : null,
                category: widget.category,
                beforeImagePath: beforeImagePath,
                afterImagePath: afterImagePath,
              ));
              if (mounted) Navigator.pop(ctx);
              _loadProjects();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ));
  }
}
