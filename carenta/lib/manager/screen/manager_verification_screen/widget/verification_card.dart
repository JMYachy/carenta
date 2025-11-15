import 'package:carenta/manager/screen/manager_verification_screen/widget/verification_image_model.dart';
import 'package:flutter/material.dart';

class VerificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(int userId, String decision, {String? notes}) onReview;

  const VerificationCard({
    super.key,
    required this.data,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final String idType = data['id_type'] ?? 'Unknown ID';
    final String status = data['status'] ?? 'pending';
    final String name =
        "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim();
    final String submittedAt = data['submitted_at'] ?? '';

    final String? idFront = data['id_front_url'];
    final String? idBack = data['id_back_url'];
    final String? barangay = data['barangay_doc_url'];
    final String email = data['email'] ?? 'N/A';
    final String contact = data['phone_number'] ?? 'N/A';
    final String address =
        "${data['street_address'] ?? ''}, ${data['city'] ?? ''}".trim();

    final Color badgeColor = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name.isNotEmpty ? name : "Unnamed User",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: badgeColor,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Basic Info ---
            Text("ID Type: $idType"),
            Text("Email: $email"),
            Text("Contact: $contact"),
            Text("Address: $address"),
            Text("Submitted: $submittedAt"),

            const SizedBox(height: 12),

            // --- ID Previews Row ---
            if (idFront != null || idBack != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (idFront != null)
                    _buildPreview(context, idFront, "Front ID"),
                  if (idBack != null) const SizedBox(width: 12),
                  if (idBack != null) _buildPreview(context, idBack, "Back ID"),
                ],
              ),

            const SizedBox(height: 12),

            // --- Barangay Document Preview ---
            if (barangay != null && barangay.isNotEmpty)
              _buildPreview(
                context,
                barangay,
                "Barangay Income/Tax Doc",
                isPdf: barangay.endsWith(".pdf"),
                fullWidth: true,
              ),

            const SizedBox(height: 16),

            // --- Action Buttons ---
            if (status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _confirmReview(context, 'approved'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _confirmReview(context, 'rejected'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --- Confirm Modal ---
  Future<void> _confirmReview(BuildContext context, String decision) async {
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
                      ? 'Are you sure you want to approve this verification?'
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

    if (confirm == true) {
      onReview(data['userid'], decision, notes: reasonController.text.trim());
    }
  }

  // --- Preview Builder (Safe, No Expanded) ---
  Widget _buildPreview(
    BuildContext context,
    String url,
    String label, {
    bool isPdf = false,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap:
          () => showDialog(
            context: context,
            builder:
                (_) => VerificationImageModal(
                  url: url,
                  label: label,
                  isPdf: isPdf,
                ),
          ),
      child: Container(
        width: fullWidth ? double.infinity : 120,
        margin: EdgeInsets.only(top: fullWidth ? 6 : 0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    isPdf
                        ? Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 48,
                          ),
                        )
                        : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
