import 'package:carenta/Admin/sections/managers/widget/manager_model.dart';
import 'package:flutter/material.dart';
import 'package:carenta/Admin/widget/manager_card.dart';
import 'package:carenta/Admin/sections/managers/service/manager_service.dart';
import 'package:carenta/Admin/sections/managers/widget/add_manager_dialog.dart';
import 'package:carenta/Admin/sections/managers/widget/edit_manager_dialog.dart';

class ManagersSection extends StatefulWidget {
  const ManagersSection({super.key});

  @override
  State<ManagersSection> createState() => _ManagersSectionState();
}

class _ManagersSectionState extends State<ManagersSection> {
  final _svc = ManagerService();

  bool _loading = true;
  int _total = 0;
  List<ManagerModel> _rows = [];
  List<ManagerModel> _filtered = [];
  String _q = '';
  String _status = 'All';

  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _svc.list(q: _q, status: _status);
      setState(() {
        _total = res.total;
        _rows = res.rows;
        _filtered = res.rows;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    }
  }

  void _applyLocalFilter() {
    setState(() {
      _filtered =
          _rows.where((m) {
            final inSearch =
                m.fullName.toLowerCase().contains(_q.toLowerCase()) ||
                m.email.toLowerCase().contains(_q.toLowerCase());
            final inStatus =
                _status == 'All' || m.status == _status.toLowerCase();
            return inSearch && inStatus;
          }).toList();
    });
  }

  Future<void> _openAdd() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddManagerDialog(),
    );
    if (result == null) return;

    try {
      final created = await _svc.create(
        username: result['username'] ?? '',
        email: result['email'] ?? '',
        password: result['password'] ?? '',
        firstName: result['first_name'] ?? '',
        lastName: result['last_name'] ?? '',
        phoneNumber: result['phone_number'] as String?,
        status: 'active',
      );
      setState(() {
        _rows.insert(0, created);
        _applyLocalFilter();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager account created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    }
  }

  Future<void> _openEdit(ManagerModel m) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (_) => EditManagerDialog(
            manager: {
              'adminid': m.adminid,
              'username': m.username,
              'email': m.email,
              'first_name': m.firstName,
              'last_name': m.lastName,
              'phone_number': m.phoneNumber,
            },
          ),
    );
    if (result == null) return;

    try {
      final updated = await _svc.update(
        adminid: m.adminid,
        username: result['username'] ?? '',
        email: result['email'] ?? '',
        password: result['password'] ?? '',
        firstName: result['first_name'] ?? '',
        lastName: result['last_name'] ?? '',
        phoneNumber: result['phone_number'] as String?,
      );
      final idx = _rows.indexWhere((x) => x.adminid == m.adminid);
      if (idx >= 0) setState(() => _rows[idx] = updated);
      _applyLocalFilter();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Manager updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _toggle(ManagerModel m) async {
    final newActive = m.status != 'active';
    try {
      await _svc.toggleStatus(adminid: m.adminid, active: newActive);
      final idx = _rows.indexWhere((x) => x.adminid == m.adminid);
      if (idx >= 0) {
        final updated = ManagerModel(
          adminid: m.adminid,
          username: m.username,
          email: m.email,
          firstName: m.firstName,
          lastName: m.lastName,
          status: newActive ? 'active' : 'inactive',
          phoneNumber: m.phoneNumber,
          profilePicture: m.profilePicture,
          lastLogin: m.lastLogin,
          createdAt: m.createdAt,
        );
        setState(() => _rows[idx] = updated);
        _applyLocalFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Toggle failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2196F3);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 🔍 search + filter
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtl,
                            onChanged: (v) {
                              _q = v;
                              _applyLocalFilter();
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: "Search by name or email...",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _status,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'All',
                                      child: Text('All Managers'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'active',
                                      child: Text('Active'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'inactive',
                                      child: Text('Inactive'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pending',
                                      child: Text('Pending'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      _status = v;
                                      _applyLocalFilter();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _openAdd,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Add Manager'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  minimumSize: const Size(150, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🧑‍💼 list
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No managers found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._filtered.map(
                        (m) => ManagerCard(
                          name: m.fullName.isNotEmpty ? m.fullName : m.username,
                          email: m.email,
                          avatarUrl: m.profilePicture ?? '',
                          lastLogin: m.lastLogin ?? '',
                          isActive: m.status == 'active',
                          onToggle: () => _toggle(m),
                          onEdit: () => _openEdit(m),
                          onDelete: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Delete not implemented (soft delete recommended)',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
