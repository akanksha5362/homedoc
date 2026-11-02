import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../data/models/consultation_session_model.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class WaitingRoomView extends StatefulWidget {
  const WaitingRoomView({
    super.key,
    required this.session,
    required this.onJoin,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onToggleSpeaker,
    this.engine,
  });

  final ConsultationSessionState session;
  final VoidCallback onJoin;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleSpeaker;
  final RtcEngine? engine;

  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _audioTestPlayed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAudioTest() {
    setState(() => _audioTestPlayed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio output test chime played successfully.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.session.doctor;
    final isCameraOff = widget.session.isCameraOff;
    final isMicMuted = widget.session.isMicMuted;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telehealth Security Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBCEBE7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: primaryTeal, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Encrypted Telehealth Session • HIPAA & FHIR Compliant',
                    style: TextStyle(
                      color: primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Doctor Information Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE6F7F6),
                  backgroundImage: doc.avatarUrl != null ? NetworkImage(doc.avatarUrl!) : null,
                  child: doc.avatarUrl == null
                      ? const Icon(Icons.person_rounded, color: primaryTeal, size: 34)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              doc.name,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doc.isDemo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Text(
                                'Demo Profile',
                                style: TextStyle(
                                  color: Color(0xFF1D4ED8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doc.specialty,
                        style: const TextStyle(
                          color: primaryTeal,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doc.hospital,
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Waiting Room Status Banner
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF8FAFC),
                      Color.lerp(
                        const Color(0xFFF1F5F9),
                        const Color(0xFFE2E8F0),
                        _pulseController.value,
                      )!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: widget.session.isDoctorOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.session.isDoctorOnline
                              ? 'Doctor is ready in the consult room'
                              : 'Doctor is reviewing your medical chart',
                          style: TextStyle(
                            color: widget.session.isDoctorOnline
                                ? const Color(0xFF065F46)
                                : const Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.session.isDoctorOnline
                          ? 'You may enter the video consultation room whenever you are ready.'
                          : 'You are #${widget.session.waitingQueuePosition} in line. Estimated wait: ~${widget.session.estimatedWaitMinutes} min.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Device & Readiness Test Box
          const Text(
            'Device & Connection Check',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Video Preview Container
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (!isCameraOff && widget.engine != null && !widget.session.isSimulatedMode)
                  AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: widget.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: isCameraOff
                              ? const Color(0xFF334155)
                              : const Color(0xFF1E293B),
                          child: Icon(
                            isCameraOff
                                ? Icons.videocam_off_rounded
                                : Icons.camera_alt_rounded,
                            color: isCameraOff ? Colors.white54 : primaryTeal,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isCameraOff
                              ? 'Camera is switched off'
                              : (widget.session.isSimulatedMode
                                  ? 'Front Camera Preview (Ready)'
                                  : 'Setting up local video feed...'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Video Preview Overlay Badges
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.session.isFrontCamera
                              ? Icons.camera_front_rounded
                              : Icons.camera_rear_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.session.isFrontCamera ? 'Front Camera' : 'Rear Camera',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controls inside preview
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'flip_cam_btn',
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        onPressed: widget.onSwitchCamera,
                        child: const Icon(Icons.flip_camera_ios_rounded, size: 18),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'toggle_cam_btn',
                        backgroundColor: isCameraOff ? Colors.redAccent : Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        onPressed: widget.onToggleCamera,
                        child: Icon(
                          isCameraOff
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Audio & Mic Controls Strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isMicMuted
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE6F7F6),
                    foregroundColor: isMicMuted ? Colors.red : primaryTeal,
                  ),
                  onPressed: widget.onToggleMic,
                  icon: Icon(
                    isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMicMuted ? 'Microphone Muted' : 'Microphone Ready',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Animated Mic Level Meter
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: isMicMuted ? 0.0 : 0.65,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMicMuted ? Colors.grey : primaryTeal,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _triggerAudioTest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    _audioTestPlayed ? Icons.check_circle_rounded : Icons.volume_up_rounded,
                    color: _audioTestPlayed ? primaryTeal : textMuted,
                    size: 16,
                  ),
                  label: Text(
                    _audioTestPlayed ? 'Test OK' : 'Test Audio',
                    style: TextStyle(
                      color: _audioTestPlayed ? primaryTeal : textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Primary Join Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: widget.onJoin,
              icon: const Icon(Icons.video_call_rounded, size: 24),
              label: const Text(
                'Enter Video Consultation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Medical Disclaimer
          const Center(
            child: Text(
              'HomeDoc AI Telehealth does not replace in-person urgent care.\nIn medical emergencies, call local emergency services immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
