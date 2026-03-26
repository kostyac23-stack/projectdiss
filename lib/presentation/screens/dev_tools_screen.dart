import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/specialist_provider.dart';
import '../../domain/repositories/specialist_repository.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import '../../data/services/logging_service.dart';
import 'seed_data.dart';

/// Developer tools screen for data management
class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  final LoggingService _loggingService = LoggingService(enabled: true);
  bool _isLoading = false;

  Future<SpecialistRepository> _getRepository() async {
    final repo = SpecialistRepositoryImpl();
    await repo.initialize();
    return repo;
  }

  Future<void> _seedData() async {
    setState(() => _isLoading = true);
    try {
      final repo = await _getRepository();
      await repo.clearAll();
      await repo.insertSpecialists(SeedData.generateSpecialists(200));
      await _loggingService.info('Seeded 200 specialists');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database seeded with 200 specialists')),
      );
      final provider = context.read<SpecialistProvider>();
      await provider.loadRankedSpecialists();
    } catch (e) {
      await _loggingService.error('Failed to seed data', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final repo = await _getRepository();
      final json = await repo.exportToJson();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/specialists_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      await _loggingService.info('Exported data to ${file.path}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data exported to ${file.path}')),
      );
    } catch (e) {
      await _loggingService.error('Failed to export data', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final json = await file.readAsString();
        final repo = await _getRepository();
        await repo.clearAll();
        await repo.importFromJson(json);
        await _loggingService.info('Imported data from ${file.path}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
        final provider = context.read<SpecialistProvider>();
        await provider.loadRankedSpecialists();
      }
    } catch (e) {
      await _loggingService.error('Failed to import data', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all specialists? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final repo = await _getRepository();
        await repo.clearAll();
        await _loggingService.info('Cleared all data');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
        final provider = context.read<SpecialistProvider>();
        await provider.loadRankedSpecialists();
      } catch (e) {
        await _loggingService.error('Failed to clear data', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showStatistics() async {
    try {
      final repo = await _getRepository();
      final stats = await repo.getStatistics();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Database Statistics'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Specialists: ${stats['total_specialists']}'),
                if (stats['price'] is Map) ...[
                  const SizedBox(height: 8),
                  Text('Price Range: \$${stats['price']['min_price']?.toStringAsFixed(0)} - \$${stats['price']['max_price']?.toStringAsFixed(0)}'),
                  Text('Average Price: \$${stats['price']['avg_price']?.toStringAsFixed(0)}'),
                ],
                if (stats['rating'] is Map) ...[
                  const SizedBox(height: 8),
                  Text('Rating Range: ${stats['rating']['min_rating']?.toStringAsFixed(1)} - ${stats['rating']['max_rating']?.toStringAsFixed(1)}'),
                  Text('Average Rating: ${stats['rating']['avg_rating']?.toStringAsFixed(1)}'),
                ],
                if (stats['categories'] is List && (stats['categories'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Categories:'),
                  ...(stats['categories'] as List).map((cat) => Text('  - ${cat['category']}: ${cat['count']}')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: const Text('Seed Database'),
                        subtitle: const Text('Generate 200 synthetic specialists'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _seedData,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.restart_alt),
                        title: const Text('Reset Onboarding'),
                        subtitle: const Text('Show the welcome screen on next launch'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('first_launch');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Onboarding reset! Restart the app to view.')),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.upload_file),
                        title: const Text('Export Data'),
                        subtitle: const Text('Save all specialists to JSON file'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _exportData,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text('Import Data'),
                        subtitle: const Text('Load specialists from JSON file'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _importData,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                        subtitle: const Text('Delete all specialists'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _clearData,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.bar_chart),
                        title: const Text('Statistics'),
                        subtitle: const Text('View database statistics'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showStatistics,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

