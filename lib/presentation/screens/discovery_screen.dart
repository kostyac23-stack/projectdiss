import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/specialist_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/matching_score.dart';
import '../../domain/models/specialist.dart';
import '../../domain/models/user.dart';
import '../../data/repositories/search_history_repository_impl.dart';
import '../../data/repositories/specialist_profile_repository_impl.dart';
import '../providers/app_localizations.dart';
import 'specialist_detail_screen.dart';
import 'settings_screen_enhanced.dart';
import 'filter_sheet.dart';
import 'orders_screen.dart';
import 'client_order_history_screen.dart';
import 'specialist_dashboard_screen.dart';
import 'portfolio_management_screen.dart';
import 'availability_screen.dart';
import 'favorites_screen.dart';
import 'task_requests_feed_screen.dart';
import 'my_requests_screen.dart';
import 'create_task_request_screen.dart';
import 'comparison_screen.dart';
import 'cost_estimator_screen.dart';
import 'map_view_screen.dart';

/// Main discovery screen with ranked specialist list
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchHistoryRepositoryImpl _searchHistoryRepository = SearchHistoryRepositoryImpl();
  final SpecialistProfileRepositoryImpl _specialistProfileRepo = SpecialistProfileRepositoryImpl();
  final FocusNode _searchFocusNode = FocusNode();
  bool _hasRequestedLocation = false;
  bool _showSearchHistory = false;
  List<String> _recentSearches = [];
  int _currentIndex = 0;
  int? _specialistId;
  Timer? _debounceTimer;
  bool _compareMode = false;
  final Set<int> _compareIds = {};

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
      _loadSearchHistory();
      _loadSpecialistId();
    });
  }

  Future<void> _loadSpecialistId() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user != null && user.role == UserRole.specialist && user.id != null) {
      await _specialistProfileRepo.initialize();
      final profile = await _specialistProfileRepo.getProfileByUserId(user.id!);
      if (profile != null && profile.specialistId != null && mounted) {
        setState(() {
          _specialistId = profile.specialistId;
        });
      }
    }
  }

  void _onSearchFocusChanged() {
    setState(() {
      _showSearchHistory = _searchFocusNode.hasFocus && _searchController.text.isEmpty;
    });
    if (_showSearchHistory) {
      _loadSearchHistory();
    }
  }

  Future<void> _loadSearchHistory() async {
    await _searchHistoryRepository.initialize();
    final history = await _searchHistoryRepository.getRecentSearches(limit: 5);
    setState(() {
      _recentSearches = history.map((h) => h.query).toList();
    });
  }

  Future<void> _initializeProvider() async {
    final provider = context.read<SpecialistProvider>();
    await provider.initialize();
    await provider.loadRankedSpecialists();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    if (_hasRequestedLocation) return;
    _hasRequestedLocation = true;

    try {
      // Test if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return; // Location services are not enabled
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // Permissions are denied
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return; // Permissions are denied forever
      }

      // When we reach here, permissions are granted
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      if (mounted) {
        final provider = context.read<SpecialistProvider>();
        provider.setUserLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showSearchHistory = false;
        });
        
        final provider = context.read<SpecialistProvider>();
        provider.updateFilters(
          provider.filters.copyWith(
            keyword: query.isEmpty ? null : query,
            clearKeyword: query.isEmpty,
          ),
          isQuietRefresh: true,
        );
        
        // Save to search history if they actually typed a full term
        if (query.isNotEmpty && query.length > 2) {
          _searchHistoryRepository.addSearch(query);
        }
      }
    });
  }

  void _selectSearchHistory(String query) {
    _searchController.text = query;
    _searchFocusNode.unfocus();
    _onSearchChanged(query);
  }

  void _showFilters() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isSpecialist = authProvider.isSpecialist;
        final isClient = authProvider.isClient;
        final currentUser = authProvider.currentUser;

        return PopScope(
          canPop: false,
          child: Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE53935), Color(0xFFFF6B6B)],
                ),
              ),
            ),
            title: Text(
              _getAppBarTitle(_currentIndex, isSpecialist),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (_currentIndex == 0) ...[
                IconButton(
                  icon: const Icon(Icons.map_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewScreen())),
                  tooltip: AppLocalizations.of(context)?.t('map_view') ?? 'Map View',
                ),
                IconButton(
                  icon: const Icon(Icons.calculate_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CostEstimatorScreen())),
                  tooltip: AppLocalizations.of(context)?.t('cost_estimator') ?? 'Cost Estimator',
                ),
                IconButton(
                  icon: Icon(_compareMode ? Icons.compare_arrows : Icons.compare, color: _compareMode ? Colors.yellowAccent : Colors.white),
                  onPressed: () => setState(() { _compareMode = !_compareMode; if (!_compareMode) _compareIds.clear(); }),
                  tooltip: _compareMode 
                      ? (AppLocalizations.of(context)?.t('exit_compare') ?? 'Exit Compare') 
                      : (AppLocalizations.of(context)?.t('compare') ?? 'Compare'),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  onPressed: _showFilters,
                  tooltip: AppLocalizations.of(context)?.t('filters') ?? 'Filters',
                ),
              ],
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreenEnhanced()),
                  );
                },
                tooltip: AppLocalizations.of(context)?.t('settings') ?? 'Settings',
              ),
            ],
          ),
          body: _buildBody(_currentIndex, isSpecialist, isClient, currentUser),
          floatingActionButton: (isClient && _currentIndex == 0)
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateTaskRequestScreen()),
                    );
                    if (result == true) {
                      setState(() => _currentIndex = 3); // Switch to My Requests
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppLocalizations.of(context)?.t('post_request') ?? 'Post Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                )
              : null,
          bottomNavigationBar: _buildBottomNavigationBar(isSpecialist, isClient, context),
          ),
        );
      },
    );
  }

  String _getAppBarTitle(int index, bool isSpecialist) {
    final l10n = AppLocalizations.of(context);
    if (isSpecialist) {
      switch (index) {
        case 0: return 'SkillsMatch';
        case 1: return l10n?.t('requests') ?? 'Requests';
        case 2: return l10n?.t('my_orders') ?? 'My Orders';
        case 3: return l10n?.t('dashboard') ?? 'Dashboard';
        case 4: return l10n?.t('portfolio') ?? 'Portfolio';
        case 5: return l10n?.t('schedule') ?? 'Schedule';
        default: return 'SkillsMatch';
      }
    } else {
      switch (index) {
        case 0: return 'SkillsMatch';
        case 1: return l10n?.t('my_orders') ?? 'My Orders';
        case 2: return l10n?.t('favorites') ?? 'Favorites';
        case 3: return l10n?.t('requests') ?? 'My Requests';
        default: return 'SkillsMatch';
      }
    }
  }

  Widget _buildBody(int index, bool isSpecialist, bool isClient, User? currentUser) {
    if (isSpecialist) {
      switch (index) {
        case 0: return _buildDiscoveryContent();
        case 1: return TaskRequestsFeedScreen(specialistId: _specialistId);
        case 2:
          return _specialistId != null
              ? OrdersScreen(specialistId: _specialistId!)
              : const Center(child: Text('Please complete your specialist profile'));
        case 3:
          return _specialistId != null
              ? SpecialistDashboardScreen(specialistId: _specialistId!)
              : const Center(child: Text('Please complete your specialist profile'));
        case 4:
          return _specialistId != null
              ? PortfolioManagementScreen(specialistId: _specialistId!)
              : const Center(child: Text('Please complete your specialist profile'));
        case 5:
          return _specialistId != null
              ? AvailabilityScreen(specialistId: _specialistId!)
              : const Center(child: Text('Please complete your specialist profile'));
        default: return _buildDiscoveryContent();
      }
    } else if (isClient && currentUser != null) {
      switch (index) {
        case 0: return _buildDiscoveryContent();
        case 1: return ClientOrderHistoryScreen(clientName: currentUser.name);
        case 2: return const FavoritesScreen();
        case 3: return MyRequestsScreen(clientId: currentUser.id!);
        default: return _buildDiscoveryContent();
      }
    }
    return _buildDiscoveryContent();
  }

  Widget _buildBottomNavigationBar(bool isSpecialist, bool isClient, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = isSpecialist
        ? [
            _NavItem(Icons.explore_rounded, Icons.explore_outlined, l10n?.t('discovery') ?? 'Discover'),
            _NavItem(Icons.assignment_rounded, Icons.assignment_outlined, l10n?.t('requests') ?? 'Requests'),
            _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, l10n?.t('orders') ?? 'Orders'),
            _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, l10n?.t('dashboard') ?? 'Dashboard'),
            _NavItem(Icons.photo_library_rounded, Icons.photo_library_outlined, l10n?.t('portfolio') ?? 'Portfolio'),
            _NavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, l10n?.t('schedule') ?? 'Schedule'),
          ]
        : isClient
            ? [
                _NavItem(Icons.explore_rounded, Icons.explore_outlined, l10n?.t('discovery') ?? 'Discover'),
                _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, l10n?.t('orders') ?? 'Orders'),
                _NavItem(Icons.favorite_rounded, Icons.favorite_outline_rounded, l10n?.t('favorites') ?? 'Favorites'),
                _NavItem(Icons.assignment_rounded, Icons.assignment_outlined, l10n?.t('requests') ?? 'Requests'),
              ]
            : [];

    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final navInnerBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: navBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -6)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: navInnerBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = _currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(vertical: selected ? 8 : 6),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)])
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? items[i].activeIcon : items[i].icon,
                        size: selected ? 22 : 20,
                        color: selected ? Colors.white : inactiveColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].labelKey,
                        style: GoogleFonts.inter(
                          fontSize: isSpecialist ? 9 : 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.white : inactiveColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDiscoveryContent() {
    return Column(
        children: [
          // Search bar with history
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search by name, skill, or tag...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              // Search history dropdown
              if (_showSearchHistory && _recentSearches.isNotEmpty)
                Positioned(
                  top: 72,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    shadowColor: Colors.black.withOpacity(0.15),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _recentSearches.length,
                        itemBuilder: (context, index) {
                          final query = _recentSearches[index];
                          return ListTile(
                            leading: const Icon(Icons.history_rounded, size: 20, color: Color(0xFF94A3B8)),
                            title: Text(query, style: GoogleFonts.inter(fontSize: 14)),
                            onTap: () => _selectSearchHistory(query),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Specialist list
          Expanded(
            child: Consumer<SpecialistProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadRankedSpecialists(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.rankedSpecialists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No specialists found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      itemCount: provider.rankedSpecialists.length,
                      itemBuilder: (context, index) {
                        final score = provider.rankedSpecialists[index];
                        return _SpecialistCard(
                          score: score,
                          compareMode: _compareMode,
                          isSelected: _compareIds.contains(score.specialist.id),
                          onCompareToggle: (id) {
                            setState(() {
                              if (_compareIds.contains(id)) {
                                _compareIds.remove(id);
                              } else if (_compareIds.length < 3) {
                                _compareIds.add(id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Max 3 specialists for comparison')),
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
                    // Floating compare bar
                    if (_compareMode && _compareIds.length >= 2)
                      Positioned(
                        bottom: 16, left: 16, right: 16,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ComparisonScreen(specialistIds: _compareIds.toList()),
                          )),
                          icon: const Icon(Icons.compare_arrows),
                          label: Text('Compare ${_compareIds.length} Specialists', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final MatchingScore score;
  final bool compareMode;
  final bool isSelected;
  final Function(int)? onCompareToggle;

  const _SpecialistCard({
    required this.score,
    this.compareMode = false,
    this.isSelected = false,
    this.onCompareToggle,
  });

  @override
  Widget build(BuildContext context) {
    final specialist = score.specialist;
    final theme = Theme.of(context);
    final matchPercent = (score.totalScore * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF3F3) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isSelected ? const Color(0xFFE53935) : const Color(0xFFF1F5F9), width: isSelected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (compareMode && onCompareToggle != null) {
              onCompareToggle!(specialist.id!);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpecialistDetailScreen(specialistId: specialist.id!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE53935), Color(0xFFFF6B6B)],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: specialist.imagePath != null
                        ? (specialist.imagePath!.startsWith('assets/') || !specialist.imagePath!.contains('/'))
                            ? Image.asset(
                                specialist.imagePath!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholderAvatar(specialist),
                              )
                            : Image.file(
                                File(specialist.imagePath!),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholderAvatar(specialist),
                              )
                        : _placeholderAvatar(specialist),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Verified
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              specialist.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (specialist.isVerified)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Category
                      Text(
                        specialist.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Stats chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Rating chip
                          _statChip(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFD97706),
                            text: specialist.rating.toStringAsFixed(1),
                            bgColor: const Color(0xFFFEF3C7),
                            textColor: const Color(0xFF92400E),
                          ),
                          // Price chip
                          _statChip(
                            icon: Icons.attach_money_rounded,
                            iconColor: const Color(0xFF059669),
                            text: '${specialist.price.toStringAsFixed(0)}/hr',
                            bgColor: const Color(0xFFECFDF5),
                            textColor: const Color(0xFF065F46),
                          ),
                          // Experience chip
                          _statChip(
                            icon: Icons.work_outline_rounded,
                            iconColor: const Color(0xFF6366F1),
                            text: '${specialist.experienceYears}y',
                            bgColor: const Color(0xFFEEF2FF),
                            textColor: const Color(0xFF3730A3),
                          ),
                          if (score.distanceKm != null)
                            _statChip(
                              icon: Icons.location_on_outlined,
                              iconColor: const Color(0xFF0EA5E9),
                              text: score.distanceKm! < 1
                                  ? '${(score.distanceKm! * 1000).toStringAsFixed(0)}m'
                                  : '${score.distanceKm!.toStringAsFixed(1)}km',
                              bgColor: const Color(0xFFF0F9FF),
                              textColor: const Color(0xFF0369A1),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Match percentage ring
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: score.totalScore.clamp(0.0, 1.0),
                          strokeWidth: 4,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            matchPercent >= 70
                                ? const Color(0xFF10B981)
                                : matchPercent >= 40
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      Text(
                        '$matchPercent%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar(Specialist specialist) {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          specialist.name.isNotEmpty ? specialist.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String labelKey;
  _NavItem(this.activeIcon, this.icon, this.labelKey);
}
