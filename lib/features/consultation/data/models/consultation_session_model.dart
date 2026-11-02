import 'package:equatable/equatable.dart';

enum ConsultationSessionStatus {
  waitingRoom,
  connecting,
  inCall,
  reconnecting,
  completed,
  error,
}

enum CallNetworkQuality {
  excellent,
  good,
  poor,
  disconnected,
}

class DoctorConsultationInfo extends Equatable {
  const DoctorConsultationInfo({
    required this.doctorId,
    required this.name,
    required this.specialty,
    this.hospital = 'HomeDoc Medical Center',
    this.avatarUrl,
    this.isDemo = false,
  });

  final String doctorId;
  final String name;
  final String specialty;
  final String hospital;
  final String? avatarUrl;
  final bool isDemo;

  factory DoctorConsultationInfo.fromMap(Map<String, dynamic> map) {
    return DoctorConsultationInfo(
      doctorId: (map['doctorId'] ?? map['id'] ?? '').toString(),
      name: (map['doctorName'] ?? map['doctor'] ?? map['name'] ?? 'Doctor').toString(),
      specialty: (map['specialty'] ?? 'General Medicine').toString(),
      hospital: (map['hospital'] ?? map['clinic'] ?? 'HomeDoc Medical Network').toString(),
      avatarUrl: map['avatarUrl'] as String?,
      isDemo: map['isDemo'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [doctorId, name, specialty, hospital, avatarUrl, isDemo];
}

class ConsultationSessionState extends Equatable {
  const ConsultationSessionState({
    required this.appointmentId,
    required this.channelId,
    required this.doctor,
    this.status = ConsultationSessionStatus.waitingRoom,
    this.isMicMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = true,
    this.isFrontCamera = true,
    this.remoteUid,
    this.isDoctorOnline = false,
    this.callDuration = Duration.zero,
    this.networkQuality = CallNetworkQuality.excellent,
    this.waitingQueuePosition = 1,
    this.estimatedWaitMinutes = 2,
    this.isSimulatedMode = false,
    this.errorMessage,
    this.sessionNotes,
  });

  final String appointmentId;
  final String channelId;
  final DoctorConsultationInfo doctor;
  final ConsultationSessionStatus status;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final int? remoteUid;
  final bool isDoctorOnline;
  final Duration callDuration;
  final CallNetworkQuality networkQuality;
  final int waitingQueuePosition;
  final int estimatedWaitMinutes;
  final bool isSimulatedMode;
  final String? errorMessage;
  final String? sessionNotes;

  String get formattedDuration {
    final minutes = callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = callDuration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  ConsultationSessionState copyWith({
    String? appointmentId,
    String? channelId,
    DoctorConsultationInfo? doctor,
    ConsultationSessionStatus? status,
    bool? isMicMuted,
    bool? isCameraOff,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    int? remoteUid,
    bool? isDoctorOnline,
    Duration? callDuration,
    CallNetworkQuality? networkQuality,
    int? waitingQueuePosition,
    int? estimatedWaitMinutes,
    bool? isSimulatedMode,
    String? errorMessage,
    String? sessionNotes,
  }) {
    return ConsultationSessionState(
      appointmentId: appointmentId ?? this.appointmentId,
      channelId: channelId ?? this.channelId,
      doctor: doctor ?? this.doctor,
      status: status ?? this.status,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      remoteUid: remoteUid ?? this.remoteUid,
      isDoctorOnline: isDoctorOnline ?? this.isDoctorOnline,
      callDuration: callDuration ?? this.callDuration,
      networkQuality: networkQuality ?? this.networkQuality,
      waitingQueuePosition: waitingQueuePosition ?? this.waitingQueuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      isSimulatedMode: isSimulatedMode ?? this.isSimulatedMode,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionNotes: sessionNotes ?? this.sessionNotes,
    );
  }

  @override
  List<Object?> get props => [
    appointmentId,
    channelId,
    doctor,
    status,
    isMicMuted,
    isCameraOff,
    isSpeakerOn,
    isFrontCamera,
    remoteUid,
    isDoctorOnline,
    callDuration,
    networkQuality,
    waitingQueuePosition,
    estimatedWaitMinutes,
    isSimulatedMode,
    errorMessage,
    sessionNotes,
  ];
}
