import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/chat_message_model.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class ChatAttachmentSheet extends StatelessWidget {
  const ChatAttachmentSheet({
    super.key,
    required this.onAttachmentSelected,
  });

  final void Function({
    required String filePath,
    required String fileName,
    required MessageType type,
    int? sizeBytes,
    String? caption,
  }) onAttachmentSelected;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (picked != null) {
        final length = await picked.length();
        onAttachmentSelected(
          filePath: picked.path,
          fileName: picked.name,
          type: MessageType.image,
          sizeBytes: length,
          caption: 'Patient medical image attachment',
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _shareSamplePdf(BuildContext context) {
    Navigator.of(context).pop();
    onAttachmentSelected(
      filePath: 'documents/diagnostic_report.pdf',
      fileName: 'Blood_Report_Comprehensive.pdf',
      type: MessageType.pdf,
      sizeBytes: 245000,
      caption: 'Attached diagnostic blood report for review',
    );
  }

  void _sharePrescription(BuildContext context) {
    Navigator.of(context).pop();
    onAttachmentSelected(
      filePath: 'prescriptions/rx_followup.pdf',
      fileName: 'Digital_Prescription_Cardio.pdf',
      type: MessageType.prescription,
      sizeBytes: 180000,
      caption: 'Shared verified digital prescription from Health Records vault',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Medical Information',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Only encrypted, clinical documents permitted in doctor consultation threads.',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFF0284C7),
                  backgroundColor: const Color(0xFFE0F2FE),
                  onTap: () => _pickImage(context, ImageSource.camera),
                ),
                _buildOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF7C3AED),
                  backgroundColor: const Color(0xFFF3E8FF),
                  onTap: () => _pickImage(context, ImageSource.gallery),
                ),
                _buildOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Medical PDF',
                  color: const Color(0xFFDC2626),
                  backgroundColor: const Color(0xFFFEE2E2),
                  onTap: () => _shareSamplePdf(context),
                ),
                _buildOption(
                  icon: Icons.receipt_long_rounded,
                  label: 'Prescription',
                  color: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFD1FAE5),
                  onTap: () => _sharePrescription(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
