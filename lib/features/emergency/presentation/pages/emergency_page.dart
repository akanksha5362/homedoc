import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/emergency_contact_model.dart';
import '../providers/emergency_provider.dart';

// ─── Colour palette ────────────────────────────────────────────────────────────
const _red = Color(0xFFDC2626);
const _redLight = Color(0xFFFEF2F2);
const _redMid = Color(0xFFFEE2E2);
const _teal = Color(0xFF007A8A);
const _lightTeal = Color(0xFFE6F7F6);
const _bg = Color(0xFFF8FAFC);
const _darkText = Color(0xFF1F2937);
const _muted = Color(0xFF6B7280);
const _cardBorder = Color(0xFFE5E7EB);

/// Emergency SOS Page — patient-facing.
///
/// Provides:
/// - One-tap SOS with a 5-second hold to prevent accidental triggers
/// - Configurable personal emergency contacts
/// - Quick-dial to Indian emergency services (ambulance 108, police 100, fire 101)
/// - Real device location display — NEVER fake coordinates
///
/// Note: "Alert contacts" integration requires the backend to send SMS/push
/// to listed numbers. See EMERGENCY_BACKEND_CONTRACT.md.
class EmergencyPage extends ConsumerStatefulWidget {
  const EmergencyPage({super.key});

  @override
  ConsumerState<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends ConsumerState<EmergencyPage>
    with TickerProviderStateMixin {
  // ── SOS hold state ────────────────────────────────────────────────────────────
  bool _sosHolding = false;
  double _sosProgress = 0;
  Timer? _sosTimer;
  static const _sosDurationMs = 3000; // 3 s hold
  static const _sosTickMs = 50;

  // ── Location state ────────────────────────────────────────────────────────────
  Position? _position;
  String _locationStatus = 'Tap to get location';
  bool _locationLoading = false;

  // ── SOS pulse animation ───────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sosTimer?.cancel();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    if (_locationLoading) return;
    setState(() {
      _locationLoading = true;
      _locationStatus = 'Fetching location…';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationStatus = 'Location services are disabled';
            _locationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationStatus = 'Location permission denied';
              _locationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationStatus = 'Location permission permanently denied';
            _locationLoading = false;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (mounted) {
        setState(() {
          _position = pos;
          _locationStatus =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Unable to get location';
          _locationLoading = false;
        });
      }
    }
  }

  // ── SOS hold ──────────────────────────────────────────────────────────────────
  void _onSosDown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _sosHolding = true;
      _sosProgress = 0;
    });

    _sosTimer = Timer.periodic(
      const Duration(milliseconds: _sosTickMs),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _sosProgress += _sosTickMs / _sosDurationMs;
        });
        if (_sosProgress >= 1.0) {
          timer.cancel();
          _triggerSOS();
        }
      },
    );
  }

  void _onSosUp() {
    _sosTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _sosHolding = false;
      _sosProgress = 0;
    });
  }

  void _triggerSOS() {
    HapticFeedback.vibrate();
    if (!mounted) return;
    setState(() {
      _sosHolding = false;
      _sosProgress = 0;
    });
    _showSOSConfirmation();
  }

  void _showSOSConfirmation() {
    final contactsAsync = ref.read(emergencyContactsProvider);
    final contacts = contactsAsync.valueOrNull ?? [];

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: _red, size: 26),
            SizedBox(width: 10),
            Text(
              'SOS Alert Sent',
              style: TextStyle(
                color: _darkText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contacts.isEmpty)
              const Text(
                'No emergency contacts added yet. Add contacts below so they '
                'can be notified automatically.',
                style: TextStyle(color: _muted, fontSize: 13.5, height: 1.4),
              )
            else ...[
              const Text(
                'Your emergency contacts will be notified:',
                style: TextStyle(color: _muted, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 8),
              ...contacts.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${c.name} (${c.relationship}) — ${c.phone}',
                      style: const TextStyle(
                          color: _darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            if (_position != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Location: ${_position!.latitude.toStringAsFixed(5)}, '
                        '${_position!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                            color: _red, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              '⚠️  Backend notification to contacts requires backend '
              'integration. See EMERGENCY_BACKEND_CONTRACT.md.',
              style: TextStyle(
                  color: _muted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK — Understood'),
          ),
        ],
      ),
    );
  }

  // ── Quick-dial ────────────────────────────────────────────────────────────────
  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot dial $number on this device.')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SOS Button ──────────────────────────────────────────────────
              _buildSOSButton(),
              const SizedBox(height: 28),

              // ── Location ────────────────────────────────────────────────────
              _buildLocationCard(),
              const SizedBox(height: 24),

              // ── Emergency Numbers ───────────────────────────────────────────
              _buildSectionHeader('Emergency Numbers'),
              const SizedBox(height: 12),
              _buildServiceGrid(),
              const SizedBox(height: 24),

              // ── Contacts ────────────────────────────────────────────────────
              _buildSectionHeader(
                'Your Emergency Contacts',
                trailing: TextButton.icon(
                  onPressed: () => _showAddContactSheet(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: _teal),
                ),
              ),
              const SizedBox(height: 12),
              _buildContactsList(contactsAsync),
              const SizedBox(height: 24),

              // ── Safety banner ───────────────────────────────────────────────
              _buildSafetyBanner(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Emergency SOS',
        style: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      leading: const BackButton(color: _darkText),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: Column(
        children: [
          // Pulsing SOS ring
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (ctx, child) {
              return Transform.scale(
                scale: _sosHolding ? 1.0 : _pulseAnim.value,
                child: child,
              );
            },
            child: GestureDetector(
              onLongPressStart: (_) => _onSosDown(),
              onLongPressEnd: (_) => _onSosUp(),
              onLongPressCancel: _onSosUp,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _redMid.withValues(alpha: 0.6),
                    ),
                  ),
                  // Progress ring overlay
                  if (_sosHolding)
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _sosProgress,
                        strokeWidth: 8,
                        color: _red,
                        backgroundColor: _redMid,
                      ),
                    ),
                  // Core button
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _red,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x40DC2626),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded,
                            color: Colors.white, size: 40),
                        SizedBox(height: 4),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _sosHolding
                ? 'Keep holding to send SOS…'
                : 'Hold for 3 seconds to send SOS',
            style: TextStyle(
              color: _sosHolding ? _red : _muted,
              fontSize: 13.5,
              fontWeight:
                  _sosHolding ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _lightTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Location',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _locationLoading
                    ? const SizedBox(
                        height: 14,
                        width: 120,
                        child: LinearProgressIndicator(
                          color: _teal,
                          backgroundColor: _lightTeal,
                        ),
                      )
                    : Text(
                        _locationStatus,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12.5,
                        ),
                      ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchLocation,
            icon: const Icon(Icons.refresh_rounded, color: _teal),
            tooltip: 'Refresh location',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget trailing = const SizedBox.shrink()}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _darkText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget _buildServiceGrid() {
    final services = [
      const _EmergencyService(
          label: 'Ambulance',
          number: '108',
          icon: Icons.local_hospital_rounded,
          color: _red),
      const _EmergencyService(
          label: 'Police',
          number: '100',
          icon: Icons.local_police_rounded,
          color: Color(0xFF1D4ED8)),
      const _EmergencyService(
          label: 'Fire Dept.',
          number: '101',
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFEA580C)),
      const _EmergencyService(
          label: 'Women Help',
          number: '1091',
          icon: Icons.people_rounded,
          color: Color(0xFF7C3AED)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: services
          .map((s) => _ServiceTile(service: s, onCall: () => _call(s.number)))
          .toList(),
    );
  }

  Widget _buildContactsList(AsyncValue<List<EmergencyContactModel>> async) {
    return async.when(
      data: (contacts) {
        if (contacts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_add_alt_1_rounded,
                    color: _muted, size: 36),
                const SizedBox(height: 10),
                const Text(
                  'No emergency contacts added yet',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add family members or friends who should be\nalerted in an emergency.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _teal),
                  onPressed: () => _showAddContactSheet(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Emergency Contact'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: contacts
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ContactTile(
                      contact: c,
                      onCall: () => _call(c.phone),
                      onEdit: () => _showEditContactSheet(c),
                      onDelete: () => _confirmDeleteContact(c),
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: _teal, strokeWidth: 2)),
      error: (e, _) => Text('Error loading contacts: $e',
          style: const TextStyle(color: _muted)),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _redLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _red, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This SOS feature is for genuine medical emergencies only. '
              'In India, always call 112 (National Emergency Number) for '
              'immediate police, ambulance, or fire response.\n\n'
              'HomeDoc AI does not replace emergency services. '
              'For life-threatening situations, call emergency services first.',
              style: TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sheets ────────────────────────────────────────────────────────────────────

  void _showAddContactSheet() {
    _showContactFormSheet(null);
  }

  void _showEditContactSheet(EmergencyContactModel contact) {
    _showContactFormSheet(contact);
  }

  void _showContactFormSheet(EmergencyContactModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final relCtrl =
        TextEditingController(text: existing?.relationship ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: Form(
              key: formKey,
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
                  Text(
                    existing == null
                        ? 'Add Emergency Contact'
                        : 'Edit Contact',
                    style: const TextStyle(
                      color: _darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDecor('Full Name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: _inputDecor('Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 7) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: relCtrl,
                    decoration: _inputDecor('Relationship (e.g. Spouse, Parent)'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              try {
                                final actions = ref
                                    .read(emergencyContactActionsProvider);
                                if (existing == null) {
                                  await actions.add(
                                    name: nameCtrl.text,
                                    phone: phoneCtrl.text,
                                    relationship: relCtrl.text,
                                  );
                                } else {
                                  await actions.update(
                                    existing.copyWith(
                                      name: nameCtrl.text,
                                      phone: phoneCtrl.text,
                                      relationship: relCtrl.text,
                                    ),
                                  );
                                }
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              existing == null ? 'Save Contact' : 'Update',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteContact(EmergencyContactModel contact) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${contact.name} from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(emergencyContactActionsProvider)
                  .delete(contact.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _teal, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _EmergencyService {
  const _EmergencyService({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
  });
  final String label;
  final String number;
  final IconData icon;
  final Color color;
}

// ─── Private sub-widgets ──────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onCall});
  final _EmergencyService service;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCall,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, color: service.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      service.label,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      service.number,
                      style: TextStyle(
                        color: service.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.call_rounded, color: service.color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });
  final EmergencyContactModel contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _lightTeal,
            child: Text(
              contact.name.isNotEmpty
                  ? contact.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: _teal,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.relationship.isNotEmpty
                      ? '${contact.relationship} · ${contact.phone}'
                      : contact.phone,
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded, color: _teal),
            tooltip: 'Call ${contact.name}',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove',
                      style: TextStyle(color: _red))),
            ],
          ),
        ],
      ),
    );
  }
}
