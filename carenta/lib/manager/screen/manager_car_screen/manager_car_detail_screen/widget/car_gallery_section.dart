import 'dart:io';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_detail_screen/service/manager_car_detail_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CarGallerySection extends StatefulWidget {
  final int carId;
  final List<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  const CarGallerySection({
    super.key,
    required this.carId,
    required this.items,
    required this.onChanged,
  });

  @override
  State<CarGallerySection> createState() => _CarGallerySectionState();
}

class _CarGallerySectionState extends State<CarGallerySection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Media Gallery',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _busy
                    ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : const SizedBox.shrink(),
                FilledButton.icon(
                  onPressed: _busy ? null : _pickAndUpload,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Media'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final crossAxisCount = maxW >= 1000 ? 4 : (maxW >= 700 ? 3 : 2);
                final tileW =
                    (maxW - (16 * (crossAxisCount - 1))) / crossAxisCount;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final m in items)
                      _MediaTile(
                        media: m,
                        width: tileW,
                        onDelete: _delete,
                        onTap: _preview,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'mkv'],
        allowMultiple: true,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;

      for (final f in res.files) {
        final path = f.path;
        if (path == null) continue;
        final ext = path.split('.').last.toLowerCase();
        final mediaType =
            ['mp4', 'mov', 'mkv'].contains(ext) ? 'video' : 'image';

        final ok = await ManagerCarDetailService.uploadMedia(
          carId: widget.carId,
          filePath: path,
          mediaType: mediaType,
        );
        if (!ok && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload ${f.name}')));
        }
      }
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> media) async {
    final id = media['mediaid'];
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove media?'),
            content: Text(
              'This will permanently delete this media item (ID $id). Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    final ok = await ManagerCarDetailService.deleteMedia(mediaId: id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Media deleted')));
      widget.onChanged();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete media')));
    }
  }

  void _preview(Map<String, dynamic> media) {
    final isVideo = '${media['media_type']}' == 'video';
    final url = '${media['media_url']}';
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isVideo ? 'Video' : 'Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVideo)
                  const Icon(Icons.videocam, size: 64)
                else
                  Image.network(url, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(url, style: Theme.of(ctx).textTheme.bodySmall),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final Map<String, dynamic> media;
  final double width;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onTap;

  const _MediaTile({
    required this.media,
    required this.width,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = '${media['media_type']}' == 'video';
    final mediaUrl = '${media['media_url']}';
    final thumb = '${media['thumbnail_url'] ?? ''}';

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => onTap(media),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child:
                    isVideo
                        ? (thumb.isNotEmpty
                            ? Image.network(thumb, fit: BoxFit.cover)
                            : Container(
                              alignment: Alignment.center,
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              child: const Icon(Icons.videocam, size: 48),
                            ))
                        : Image.network(mediaUrl, fit: BoxFit.cover),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: () => onDelete(media),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              if (isVideo)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Video', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
