import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/consultation_session_model.dart';
import '../providers/video_consultation_provider.dart';
import '../widgets/active_call_view.dart';
import '../widgets/consultation_completed_view.dart';
import '../widgets/waiting_room_view.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class VideoConsultationPage extends ConsumerStatefulWidget {
  const VideoConsultationPage({
    super.key,
    this.appointment,
  });

  final Map<String, dynamic>? appointment;

  @override
  ConsumerState<VideoConsultationPage> createState() => _VideoConsultationPageState();
}

class _VideoConsultationPageState extends ConsumerState<VideoConsultationPage> {
  late final String _appointmentId;
  late final String _channelId;
  late final DoctorConsultationInfo _doctor;

  @override
  void initState() {
    super.initState();
    final apt = widget.appointment ?? const <String, dynamic>{};

    _appointmentId = (apt['id'] ?? 'demo_apt_video_101').toString();
    _channelId = 'consultation_${_appointmentId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';

    _doctor = DoctorConsultationInfo(
      doctorId: (apt['doctorId'] ?? apt['id'] ?? 'doc_demo_1').toString(),
      name: (apt['doctor'] ?? apt['doctorName'] ?? 'Dr. Sarah Mitchell').toString(),
      specialty: (apt['specialty'] ?? 'Cardiologist').toString(),
      hospital: (apt['hospital'] ?? apt['clinic'] ?? 'HomeDoc Telehealth Center').toString(),
      avatarUrl: apt['avatarUrl'] as String?,
      isDemo: apt['isDemo'] as bool? ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionArgs = (
      appointmentId: _appointmentId,
      channelId: _channelId,
      doctor: _doctor,
    );

    final session = ref.watch(videoConsultationProvider(sessionArgs));
    final notifier = ref.read(videoConsultationProvider(sessionArgs).notifier);

    // If call is completed, show completion summary
    if (session.status == ConsultationSessionStatus.completed) {
      return ConsultationCompletedView(session: session);
    }

    // If in active call or reconnecting
    if (session.status == ConsultationSessionStatus.inCall ||
        session.status == ConsultationSessionStatus.reconnecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: ActiveCallView(
          session: session,
          engine: notifier.engine,
          onToggleMic: notifier.toggleMic,
          onToggleCamera: notifier.toggleCamera,
          onSwitchCamera: notifier.switchCamera,
          onToggleSpeaker: notifier.toggleSpeaker,
          onEndCall: notifier.endCall,
        ),
      );
    }

    // If connecting state
    if (session.status == ConsultationSessionStatus.connecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: primaryTeal,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connecting to Secure Telehealth Room...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Joining Dr. ${_doctor.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Default: Waiting Room Interface
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Telehealth Waiting Room',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, color: primaryTeal, size: 14),
                SizedBox(width: 4),
                Text(
                  'Secure',
                  style: TextStyle(
                    color: primaryTeal,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: WaitingRoomView(
        session: session,
        engine: notifier.engine,
        onJoin: notifier.admitToCall,
        onToggleMic: notifier.toggleMic,
        onToggleCamera: notifier.toggleCamera,
        onSwitchCamera: notifier.switchCamera,
        onToggleSpeaker: notifier.toggleSpeaker,
      ),
    );
  }
}
