import 'package:carenta/manager/screen/manager_verification_screen/service/manager_review_vertification_service.dart';
import 'package:flutter/material.dart';
import 'widget/verification_card.dart';

class ManagerUserVerificationScreen extends StatefulWidget {
  const ManagerUserVerificationScreen({super.key});

  @override
  State<ManagerUserVerificationScreen> createState() =>
      _ManagerUserVerificationScreenState();
}

class _ManagerUserVerificationScreenState
    extends State<ManagerUserVerificationScreen> {
  bool _loading = true;
  String _filterStatus = 'pending';
  List<Map<String, dynamic>> _verifications = [];

  @override
  void initState() {
    super.initState();
    _fetchVerifications();
  }

  Future<void> _fetchVerifications() async {
    setState(() => _loading = true);
    final res = await ManagerVerificationService.fetchVerifications(
      _filterStatus,
    );

    if (!mounted) return;
    if (res["success"] == true && res["data"] is List) {
      setState(() {
        _verifications = List<Map<String, dynamic>>.from(res["data"]);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Failed to load data")),
      );
    }
  }

  Future<void> _onReview(int userId, String action, {String? notes}) async {
    final res = await ManagerVerificationService.reviewVerification(
      userId: userId,
      action: action,
      notes: notes ?? '',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res["message"] ?? "No response")));

    if (res["success"] == true) _fetchVerifications();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0077B6);
    final surface = Theme.of(context).cardColor;

    return SafeArea(
      child: Column(
        children: [
          // 🧩 Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "User Verifications",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.black87,
                      ),
                      dropdownColor: surface,
                      borderRadius: BorderRadius.circular(12),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approved'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Rejected'),
                        ),
                        DropdownMenuItem(value: 'all', child: Text('All')),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _filterStatus = v);
                        await _fetchVerifications();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 🧱 Content Section
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _verifications.isEmpty
                      ? const Center(
                        key: ValueKey('empty'),
                        child: Text(
                          "No verifications found.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      : RefreshIndicator(
                        key: const ValueKey('list'),
                        onRefresh: _fetchVerifications,
                        color: primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _verifications.length,
                          itemBuilder:
                              (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: VerificationCard(
                                  data: _verifications[i],
                                  onReview: _onReview,
                                ),
                              ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
