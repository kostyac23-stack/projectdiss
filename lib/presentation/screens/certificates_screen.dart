import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/certificate.dart';
import '../../data/repositories/certificate_repository_impl.dart';
import '../widgets/full_screen_image_viewer.dart';

/// Screen for viewing specialist certificates and diplomas
class CertificatesScreen extends StatefulWidget {
  final int specialistId;
  final String specialistName;
  final bool isOwnProfile;

  const CertificatesScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.isOwnProfile = false,
  });

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final CertificateRepositoryImpl _repo = CertificateRepositoryImpl();
  List<Certificate> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    await _repo.initialize();
    await _repo.seedDemoCertificates(widget.specialistId);
    final certs = await _repo.getCertificates(widget.specialistId);
    if (mounted) setState(() { _certificates = certs; _isLoading = false; });
  }

  IconData _getTypeIcon(CertificateType type) {
    switch (type) {
      case CertificateType.certificate: return Icons.workspace_premium;
      case CertificateType.diploma: return Icons.school;
      case CertificateType.license: return Icons.verified;
      case CertificateType.training: return Icons.menu_book;
      case CertificateType.award: return Icons.emoji_events;
    }
  }

  Color _getTypeColor(CertificateType type) {
    switch (type) {
      case CertificateType.certificate: return const Color(0xFF1565C0);
      case CertificateType.diploma: return const Color(0xFF6A1B9A);
      case CertificateType.license: return const Color(0xFF2E7D32);
      case CertificateType.training: return const Color(0xFFE65100);
      case CertificateType.award: return const Color(0xFFF9A825);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
          ),
        ),
        title: Text('Certificates & Diplomas', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No certificates yet', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _certificates.length,
                  itemBuilder: (context, index) {
                    final cert = _certificates[index];
                    final color = _getTypeColor(cert.type);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_getTypeIcon(cert.type), color: color, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(cert.type.displayName, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                                ),
                                                if (cert.isExpired) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(6)),
                                                    child: Text('EXPIRED', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(cert.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                                            if (cert.issuedBy != null) ...[
                                              const SizedBox(height: 4),
                                              Text('Issued by: ${cert.issuedBy}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                            ],
                                            if (cert.issuedDate != null) ...[
                                              const SizedBox(height: 2),
                                              Text('Date: ${cert.issuedDate!.day}/${cert.issuedDate!.month}/${cert.issuedDate!.year}',
                                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (cert.imagePath != null)
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => FullScreenImageViewer(imageProvider: FileImage(File(cert.imagePath!)), heroTag: 'cert_${cert.id}'),
                                            ));
                                          },
                                          child: Hero(
                                            tag: 'cert_${cert.id}',
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              margin: const EdgeInsets.only(left: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: FileImage(File(cert.imagePath!)),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (cert.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(cert.description!, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700])),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.isOwnProfile)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                                onPressed: () async {
                                  await _repo.deleteCertificate(cert.id!);
                                  _loadCertificates();
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: widget.isOwnProfile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1565C0),
              onPressed: () => _showAddDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final issuedByCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CertificateType selectedType = CertificateType.certificate;
    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Certificate', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CertificateType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: CertificateType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: issuedByCtrl, decoration: const InputDecoration(labelText: 'Issued By', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() => selectedImagePath = pickedFile.path);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Add Document Photo', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                await _repo.addCertificate(Certificate(
                  specialistId: widget.specialistId,
                  title: titleCtrl.text,
                  issuedBy: issuedByCtrl.text.isNotEmpty ? issuedByCtrl.text : null,
                  description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                  issuedDate: DateTime.now(),
                  type: selectedType,
                  imagePath: selectedImagePath,
                ));
                if (mounted) Navigator.pop(ctx);
                _loadCertificates();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
