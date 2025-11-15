import 'package:carenta/manager/screen/manager_car_screen/service/manager_car_service.dart';
import 'package:carenta/manager/screen/manager_car_screen/widget/car_filter_strip.dart';
import 'package:carenta/manager/screen/manager_car_screen/widget/car_list_view.dart';
import 'package:carenta/manager/screen/manager_car_screen/widget/car_search_bar.dart';
import 'package:carenta/manager/screen/manager_car_screen/widget/car_stats_overview.dart';
import 'package:flutter/material.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_add_car/mangaer_add_car_screen.dart';

class ManagerCarScreen extends StatefulWidget {
  final String? filterStatus;
  const ManagerCarScreen({super.key, this.filterStatus});

  @override
  State<ManagerCarScreen> createState() => _ManagerCarScreenState();
}

class _ManagerCarScreenState extends State<ManagerCarScreen> {
  final _svc = ManagerCarService();
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _filtered = [];
  String _activeFilter = 'all';
  bool _loading = true;
  Map<String, int> _stats = {
    'available': 0,
    'rented': 0,
    'maintenance': 0,
    'inactive': 0,
  };

  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    if (widget.filterStatus != null) _activeFilter = widget.filterStatus!;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCars());
  }

  @override
  void dispose() {
    _mounted = false;
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    if (!_mounted) return;
    setState(() => _loading = true);

    try {
      final data = await _svc.getCars();
      if (!_mounted) return;
      final stats = _svc.computeFleetStats(data);
      setState(() {
        _cars = data;
        _stats = stats;
        _filtered = _svc.filterByStatus(data, _activeFilter);
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Car load error: $e');
      if (!_mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter(String status) {
    if (!_mounted) return;
    setState(() {
      _activeFilter = status;
      _filtered = _svc.filterByStatus(_cars, status);
    });
  }

  void _searchCars(String query) {
    if (!_mounted) return;
    setState(() {
      _filtered = _svc.searchCars(_cars, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF0077B6);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ Scroll-safe Sliver layout
    return RefreshIndicator(
      onRefresh: _loadCars,
      color: themeColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  CarSearchBar(
                    controller: _search,
                    onChanged: _searchCars,
                    onAdd: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagerAddCarScreen(),
                        ),
                      );
                      _loadCars();
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6),
                      ],
                    ),
                    child: CarStatsOverview(
                      available: _stats['available'] ?? 0,
                      rented: _stats['rented'] ?? 0,
                      maintenance: _stats['maintenance'] ?? 0,
                      inactive: _stats['inactive'] ?? 0,
                      onFilterSelect: _applyFilter,
                    ),
                  ),
                  CarFilterStrip(
                    selected: _activeFilter,
                    onSelect: _applyFilter,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // ✅ Car list as SliverList
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= _filtered.length) return null;
              final car = _filtered[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: CarListView(cars: [car], onReload: _loadCars),
              );
            }, childCount: _filtered.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
