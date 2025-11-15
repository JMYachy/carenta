import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carenta/user/profile_screen/service/user_verification_service.dart';

const Color colorBlue = Color(0xFF1D84B5);
const Color colorLightBlue = Color(0xFFE9F1F7);
const Color colorEmerald = Color(0xFF1F7895);

class UserVertificationScreen extends StatefulWidget {
  final int userId;
  const UserVertificationScreen({super.key, required this.userId});

  @override
  State<UserVertificationScreen> createState() =>
      _UserVertificationScreenState();
}

class _UserVertificationScreenState extends State<UserVertificationScreen> {
  String _idType = 'National ID';
  File? _frontImage;
  File? _backImage;
  File? _barangayDoc;
  bool _uploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _pickBarangayDoc() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _barangayDoc = File(picked.path);
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_frontImage == null || _backImage == null || _barangayDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload all required documents (Front, Back, Barangay Doc)',
          ),
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    final res = await UserVerificationService.submitVerificationV2(
      userId: widget.userId,
      idType: _idType,
      idNumber: '', // optional field
      idFront: _frontImage!,
      idBack: _backImage,
      barangayDoc: _barangayDoc!,
    );

    setState(() => _uploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Upload complete')),
    );

    if (res['success'] == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: colorLightBlue,
      appBar: AppBar(
        title: const Text('Submit Verification'),
        centerTitle: true,
        backgroundColor: colorBlue,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, color: colorEmerald, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "ID Verification",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please upload your valid ID and Barangay Income/Tax Document for account verification. "
                    "Your submission will be reviewed by our manager.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- ID TYPE DROPDOWN ---
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _idType,
                  decoration: const InputDecoration(
                    labelText: "Select ID Type",
                    prefixIcon: Icon(Icons.badge_rounded, color: colorBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'National ID',
                      child: Text('National ID'),
                    ),
                    DropdownMenuItem(
                      value: 'Driver License',
                      child: Text('Driver’s License'),
                    ),
                    DropdownMenuItem(
                      value: 'Passport',
                      child: Text('Passport'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _idType = v!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- FRONT IMAGE ---
            _buildImageUploader(
              title: "Front Side of ID *",
              file: _frontImage,
              onTap: () => _pickImage(true),
            ),
            const SizedBox(height: 16),

            // --- BACK IMAGE ---
            _buildImageUploader(
              title: "Back Side of ID *",
              file: _backImage,
              onTap: () => _pickImage(false),
            ),
            const SizedBox(height: 16),

            // --- BARANGAY DOC ---
            _buildImageUploader(
              title: "Barangay Income/Tax Document *",
              file: _barangayDoc,
              onTap: _pickBarangayDoc,
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.green,
            ),

            const SizedBox(height: 30),

            // --- SUBMIT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon:
                    _uploading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.cloud_upload_rounded),
                label: Text(_uploading ? "Submitting..." : "Submit for Review"),
                style: FilledButton.styleFrom(
                  backgroundColor: colorEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _uploading ? null : _submitVerification,
              ),
            ),
            const SizedBox(height: 10),

            if (_uploading)
              const Text(
                "Please wait while we upload your documents...",
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // --- CUSTOM UPLOADER CARD ---
  Widget _buildImageUploader({
    required String title,
    required File? file,
    required VoidCallback onTap,
    IconData icon = Icons.add_a_photo_rounded,
    Color color = colorBlue,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: colorLightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child:
                    file == null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 40, color: color),
                              const SizedBox(height: 8),
                              const Text(
                                "Tap to upload",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
