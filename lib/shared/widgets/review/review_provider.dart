import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../../features/appointments/data/models/doctor_review_model.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _teal = Color(0xFF007A8A);
const _amber = Color(0xFFF59E0B);
const _darkText = Color(0xFF1F2937);
const _muted = Color(0xFF6B7280);

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Reviews left BY the current patient, keyed by appointmentId.
final patientReviewsProvider =
StreamProvider<Map<String, DoctorReviewModel>>((ref) {
  final uid = ref.watch(authStateProvider).user?.id;
  if (uid == null || uid.isEmpty) return Stream.value({});

  final fs = ref.watch(firestoreProvider);
  return fs
      .collection('doctor_reviews')
      .where('patientId', isEqualTo: uid)
      .snapshots()
      .map((snap) => {
    for (final doc in snap.docs.map(DoctorReviewModel.fromFirestore))
      doc.appointmentId: doc,
  });
});

/// Reviews received BY a specific doctor.
final doctorReviewsProvider =
StreamProvider.family<List<DoctorReviewModel>, String>((ref, doctorId) {
  if (doctorId.isEmpty) return Stream.value([]);
  final fs = ref.watch(firestoreProvider);
  return fs
      .collection('doctor_reviews')
      .where('doctorId', isEqualTo: doctorId)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs.map(DoctorReviewModel.fromFirestore).toList());
});

/// Submit or update a review for a completed appointment.
Future<void> submitDoctorReview({
  required WidgetRef ref,
  required String doctorId,
  required String doctorName,
  required String appointmentId,
  required int rating,
  required String comment,
}) async {
  final auth = ref.read(authStateProvider);
  final patientId = auth.user?.id ?? '';
  final patientName = auth.user?.displayName ?? 'Patient';

  if (patientId.isEmpty) throw Exception('Not authenticated.');
  if (rating < 1 || rating > 5) throw Exception('Rating must be 1–5.');

  final fs = ref.read(firestoreProvider);

  // Check if a review already exists for this appointment
  final existing = await fs
      .collection('doctor_reviews')
      .where('appointmentId', isEqualTo: appointmentId)
      .where('patientId', isEqualTo: patientId)
      .limit(1)
      .get();

  final data = {
    'doctorId': doctorId,
    'patientId': patientId,
    'patientName': patientName,
    'appointmentId': appointmentId,
    'rating': rating,
    'comment': comment.trim(),
    'createdAt': FieldValue.serverTimestamp(),
    // updatedAt only on updates
  };

  if (existing.docs.isNotEmpty) {
    await existing.docs.first.reference.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  } else {
    await fs.collection('doctor_reviews').add(data);
  }

  // NOTE TO BACKEND TEAM: After write, update doctor_public_profiles/{doctorId}
  // with aggregated rating. See REVIEW_BACKEND_CONTRACT.md.
}

// ─── Review Dialog Widget ─────────────────────────────────────────────────────

/// Shows a review dialog for a completed appointment and submits it to
/// Firestore. Returns true if the review was submitted successfully.
Future<bool> showReviewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> appointment,
}) async {
  final doctorName =
  (appointment['doctor'] ?? appointment['doctorName'] ?? 'Doctor')
      .toString();
  final doctorId = (appointment['doctorId'] ?? '').toString();
  final appointmentId = (appointment['id'] ?? '').toString();
  final specialty = (appointment['specialty'] ?? '').toString();

  if (doctorId.isEmpty || appointmentId.isEmpty) return false;

  // Check if already reviewed
  final existingMap = ref.read(patientReviewsProvider).valueOrNull ?? {};
  final existing = existingMap[appointmentId];

  int selectedRating = existing?.rating ?? 0;
  final commentCtrl =
  TextEditingController(text: existing?.comment ?? '');
  bool submitting = false;
  bool submitted = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Column(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFE6F7F6),
                child: Icon(Icons.star_rounded, color: _teal, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                existing != null ? 'Update Your Review' : 'Rate Your Visit',
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$doctorName · $specialty',
                style: const TextStyle(color: _teal, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star picker
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: _amber,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              if (selectedRating > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _ratingLabel(selectedRating),
                  style: const TextStyle(
                      color: _amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
              const Text('Skip', style: TextStyle(color: _muted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (submitting || selectedRating == 0)
                  ? null
                  : () async {
                setState(() => submitting = true);
                try {
                  await submitDoctorReview(
                    ref: ref,
                    doctorId: doctorId,
                    doctorName: doctorName,
                    appointmentId: appointmentId,
                    rating: selectedRating,
                    comment: commentCtrl.text,
                  );
                  submitted = true;
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  setState(() => submitting = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: submitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : Text(
                existing != null ? 'Update' : 'Submit',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    ),
  );

  commentCtrl.dispose();
  return submitted;
}

String _ratingLabel(int r) {
  switch (r) {
    case 1:
      return 'Poor';
    case 2:
      return 'Fair';
    case 3:
      return 'Good';
    case 4:
      return 'Very Good';
    case 5:
      return 'Excellent!';
    default:
      return '';
  }
}

// ─── Star display widget (reusable) ──────────────────────────────────────────

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = _amber,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating >= i + 0.5;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: color,
          size: size,
        );
      }),
    );
  }
}
