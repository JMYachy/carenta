import 'package:carenta/service/manager/manager_review_vertification_service.dart';
import 'package:flutter/material.dart';

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

    final res = await ManagerVerificationService.fetchPendingVerifications();
    if (!mounted) return;
    if (res["success"] == true && res["data"] is List) {
      setState(() {
        _verifications = List<Map<String, dynamic>>.from(res["data"] as List);
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _verifications = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Failed to load data")),
      );
    }
  }

  Future<void> _reviewVerification(int userId, String decision) async {
    if (!mounted) return;
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              decision == 'approved'
                  ? 'Approve Verification'
                  : 'Reject Verification',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  decision == 'approved'
                      ? 'Are you sure you want to approve this user verification?'
                      : 'Please provide a reason for rejection:',
                ),
                if (decision == 'rejected')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: 'Reason for rejection',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final res = await ManagerVerificationService.reviewVerification(
      userId: userId,
      action: decision,
      notes: reasonController.text.trim(),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res["message"] ?? "No response")));

    if (res["success"] == true) _fetchVerifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Verifications'),
        backgroundColor: const Color(0xFF0077B6),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: _filterStatus,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'all', child: Text('All')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _filterStatus = v);
                await _fetchVerifications();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _verifications.isEmpty
              ? const Center(
                child: Text(
                  "No verifications found.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchVerifications,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _verifications.length,
                  itemBuilder:
                      (context, i) => _buildVerificationCard(_verifications[i]),
                ),
              ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> item) {
    final String idType = item['id_type'] ?? 'Unknown ID';
    final String status = item['status'] ?? 'pending';
    final String name =
        "${item['first_name'] ?? ''} ${item['last_name'] ?? ''}".trim();
    final String? idFront = item['id_front_url'];
    final String? idBack = item['id_back_url'];
    final String submittedAt = item['submitted_at'] ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name.isNotEmpty ? name : "Unnamed User",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor:
                      status == 'pending'
                          ? Colors.orange
                          : status == 'approved'
                          ? Colors.green
                          : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("ID Type: $idType"),
            Text("Submitted: $submittedAt"),
            const SizedBox(height: 12),

            Row(
              children: [
                if (idFront != null)
                  _idImagePreview(context, idFront, "Front ID"),
                const SizedBox(width: 12),
                if (idBack != null) _idImagePreview(context, idBack, "Back ID"),
              ],
            ),
            const SizedBox(height: 16),

            if (status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                    ),
                    onPressed:
                        () => _reviewVerification(item['userid'], 'approved'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                    ),
                    onPressed:
                        () => _reviewVerification(item['userid'], 'rejected'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _idImagePreview(BuildContext context, String url, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: InteractiveViewer(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
          );
        },
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (ctx, _, __) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
