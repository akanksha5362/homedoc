import 'dart:math' as math;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../data/models/consultation_session_model.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class ActiveCallView extends StatefulWidget {
  const ActiveCallView({
    super.key,
    required this.session,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onToggleSpeaker,
    required this.onEndCall,
    this.engine,
  });

  final ConsultationSessionState session;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;
  final RtcEngine? engine;

  @override
  State<ActiveCallView> createState() => _ActiveCallViewState();
}

class _ActiveCallViewState extends State<ActiveCallView>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveformController;
  Offset _pipPosition = const Offset(20, 80);

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  void _showEndCallConfirmation() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.call_end_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 14),
                const Text(
                  'End Consultation?',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to end your video appointment with ${widget.session.doctor.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textMuted, fontSize: 13.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Stay in Call', style: TextStyle(color: textDark)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          widget.onEndCall();
                        },
                        child: const Text('End Call', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClinicalNotesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.35,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.description_rounded, color: primaryTeal, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Live Clinical Consultation Notes',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded, color: textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFE6F7F6),
                                child: Icon(Icons.medical_services_rounded, color: primaryTeal, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.session.doctor.name,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    widget.session.doctor.specialty,
                                    style: const TextStyle(color: textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          const Text(
                            'Preliminary Observations:',
                            style: TextStyle(
                              color: textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• Patient reports seasonal allergies and mild rhinitis symptoms.\n• Vitals reviewed: Normotensive, resting pulse regular.\n• Clinician advice: Avoid known dust allergens, stay well hydrated.',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Prescription & diagnostic orders will be automatically deposited into your Health Records vault at call conclusion.',
                                    style: TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.session.doctor;
    final isMicMuted = widget.session.isMicMuted;
    final isCameraOff = widget.session.isCameraOff;
    final isSpeakerOn = widget.session.isSpeakerOn;
    final isReconnecting = widget.session.status == ConsultationSessionStatus.reconnecting;
    final remoteUid = widget.session.remoteUid;
    final isSimulated = widget.session.isSimulatedMode;

    return Stack(
      children: [
        // -----------------------------------------------------------
        // 1. REMOTE DOCTOR FULLSCREEN VIEW
        // -----------------------------------------------------------
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0F172A),
            child: (widget.engine != null && !isSimulated && remoteUid != null)
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: widget.engine!,
                      canvas: VideoCanvas(uid: remoteUid),
                      connection: RtcConnection(channelId: widget.session.channelId),
                    ),
                  )
                : _buildSimulatedDoctorFeed(doc),
          ),
        ),

        // -----------------------------------------------------------
        // 2. TOP TELEMETRY & STATUS OVERLAY
        // -----------------------------------------------------------
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Row(
              children: [
                // Doctor chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryTeal,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Live Timer Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.session.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Clinical Notes Button
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: 'View Clinical Notes',
                  onPressed: _showClinicalNotesSheet,
                  icon: const Icon(Icons.note_alt_outlined, size: 18),
                ),
              ],
            ),
          ),
        ),

        // -----------------------------------------------------------
        // 3. RECONNECTION / POOR NETWORK BANNER
        // -----------------------------------------------------------
        if (isReconnecting)
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unstable connection. Re-synchronizing telehealth stream...',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // -----------------------------------------------------------
        // 4. FLOATING PATIENT PiP (Picture-in-Picture)
        // -----------------------------------------------------------
        Positioned(
          top: _pipPosition.dy,
          right: _pipPosition.dx,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _pipPosition = Offset(
                  math.max(10, math.min(MediaQuery.of(context).size.width - 130, _pipPosition.dx - details.delta.dx)),
                  math.max(70, math.min(MediaQuery.of(context).size.height - 250, _pipPosition.dy + details.delta.dy)),
                );
              });
            },
            child: Container(
              width: 110,
              height: 155,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white30, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (!isCameraOff && widget.engine != null && !isSimulated)
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
                          Icon(
                            isCameraOff ? Icons.videocam_off_rounded : Icons.person_rounded,
                            color: Colors.white54,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCameraOff ? 'Camera Off' : 'You',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                  // Mic indicator badge in PiP
                  if (isMicMuted)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_off_rounded, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // -----------------------------------------------------------
        // 5. BOTTOM TELEHEALTH CONTROLS DOCK
        // -----------------------------------------------------------
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Microphone Mute / Unmute
                _buildControlButton(
                  icon: isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: isMicMuted ? 'Unmute' : 'Mute',
                  isActive: !isMicMuted,
                  isDestructive: isMicMuted,
                  onTap: widget.onToggleMic,
                ),

                // Camera On / Off
                _buildControlButton(
                  icon: isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                  label: isCameraOff ? 'Start Video' : 'Stop Video',
                  isActive: !isCameraOff,
                  isDestructive: isCameraOff,
                  onTap: widget.onToggleCamera,
                ),

                // Flip Camera
                _buildControlButton(
                  icon: Icons.flip_camera_ios_rounded,
                  label: 'Flip',
                  isActive: true,
                  onTap: widget.onSwitchCamera,
                ),

                // Speaker Output
                _buildControlButton(
                  icon: isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  label: isSpeakerOn ? 'Speaker' : 'Earpiece',
                  isActive: isSpeakerOn,
                  onTap: widget.onToggleSpeaker,
                ),

                // End Call Button
                _buildControlButton(
                  icon: Icons.call_end_rounded,
                  label: 'End',
                  isActive: false,
                  isEndCall: true,
                  onTap: _showEndCallConfirmation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatedDoctorFeed(DoctorConsultationInfo doc) {
    return Stack(
      children: [
        // Subtle background gradient for clinical presence
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
        ),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Pulse Avatar
              AnimatedBuilder(
                animation: _waveformController,
                builder: (context, child) {
                  final scale = 1.0 + (_waveformController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryTeal.withValues(alpha: 0.5 + (_waveformController.value * 0.5)),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF334155),
                        backgroundImage:
                            doc.avatarUrl != null ? NetworkImage(doc.avatarUrl!) : null,
                        child: doc.avatarUrl == null
                            ? const Icon(Icons.person_rounded, color: primaryTeal, size: 58)
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                doc.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                doc.specialty,
                style: const TextStyle(
                  color: primaryTeal,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Animated Speaking Waveform Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return AnimatedBuilder(
                    animation: _waveformController,
                    builder: (context, child) {
                      final waveHeight = 8.0 +
                          (18.0 * math.sin((_waveformController.value * math.pi) + (index * 0.7)).abs());
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 4,
                        height: waveHeight,
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              const Text(
                'Audio feed live • Doctor speaking',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
            ],
          ),
        ),

        // Quality and HD Overlay Watermark
        Positioned(
          bottom: 120,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.hd_rounded, color: Colors.greenAccent, size: 14),
                SizedBox(width: 4),
                Text(
                  '1080p • 60 FPS • 24ms Latency',
                  style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    bool isDestructive = false,
    bool isEndCall = false,
    required VoidCallback onTap,
  }) {
    Color btnColor;
    Color iconColor;

    if (isEndCall) {
      btnColor = Colors.red.shade600;
      iconColor = Colors.white;
    } else if (isDestructive) {
      btnColor = Colors.red.shade900.withValues(alpha: 0.8);
      iconColor = Colors.white;
    } else if (isActive) {
      btnColor = Colors.white.withValues(alpha: 0.2);
      iconColor = Colors.white;
    } else {
      btnColor = Colors.white.withValues(alpha: 0.1);
      iconColor = Colors.white54;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            width: isEndCall ? 58 : 48,
            height: isEndCall ? 58 : 48,
            decoration: BoxDecoration(
              color: btnColor,
              shape: BoxShape.circle,
              boxShadow: isEndCall
                  ? [
                      BoxShadow(
                        color: Colors.red.shade600.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: isEndCall ? 28 : 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isEndCall ? Colors.redAccent : Colors.white70,
            fontSize: 11,
            fontWeight: isEndCall ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
