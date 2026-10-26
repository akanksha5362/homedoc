import 'package:flutter/material.dart';

class CarePage extends StatefulWidget {
const CarePage({super.key});

@override
State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> {
final TextEditingController _searchController =
TextEditingController();

String _selectedSpecialty = 'All';
String _sortBy = 'Recommended';

static const Color primaryTeal = Color(0xFF14B8A6);
static const Color darkTeal = Color(0xFF007A8A);
static const Color lightTeal = Color(0xFFE6F7F6);
static const Color darkText = Color(0xFF1F2937);
static const Color mutedText = Color(0xFF6B7280);

final List<Map<String, dynamic>> _doctors = [
{
'name': 'Dr. Ananya Sharma',
'specialty': 'General Physician',
'qualification': 'MBBS, MD',
'experience': 8,
'rating': 4.9,
'reviews': 124,
'fee': 499,
'available': true,
'initials': 'AS',
'color': 0xFFDBEAFE,
},
{
'name': 'Dr. Rahul Verma',
'specialty': 'Cardiologist',
'qualification': 'MBBS, DM Cardiology',
'experience': 12,
'rating': 4.8,
'reviews': 98,
'fee': 799,
'available': true,
'initials': 'RV',
'color': 0xFFFCE7F3,
},
{
'name': 'Dr. Priya Mehta',
'specialty': 'Dermatologist',
'qualification': 'MBBS, MD Dermatology',
'experience': 6,
'rating': 4.7,
'reviews': 86,
'fee': 599,
'available': false,
'initials': 'PM',
'color': 0xFFD1FAE5,
},
{
'name': 'Dr. Arjun Patel',
'specialty': 'Pediatrician',
'qualification': 'MBBS, MD Pediatrics',
'experience': 10,
'rating': 4.9,
'reviews': 156,
'fee': 649,
'available': true,
'initials': 'AP',
'color': 0xFFFEF3C7,
},
{
'name': 'Dr. Neha Gupta',
'specialty': 'Gynecologist',
'qualification': 'MBBS, MS Obstetrics',
'experience': 9,
'rating': 4.8,
'reviews': 112,
'fee': 699,
'available': true,
'initials': 'NG',
'color': 0xFFEDE9FE,
},
];

final List<String> _specialties = [
'All',
'General Physician',
'Cardiologist',
'Dermatologist',
'Pediatrician',
'Gynecologist',
];

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

List<Map<String, dynamic>> get _filteredDoctors {
final query = _searchController.text.trim().toLowerCase();

final results = _doctors.where((doctor) {
final matchesSpecialty = _selectedSpecialty == 'All' ||
doctor['specialty'] == _selectedSpecialty;

final matchesSearch =
(doctor['name'] as String).toLowerCase().contains(query) ||
(doctor['specialty'] as String)
    .toLowerCase()
    .contains(query) ||
(doctor['qualification'] as String)
    .toLowerCase()
    .contains(query);

return matchesSpecialty && matchesSearch;
}).toList();

if (_sortBy == 'Highest rated') {
results.sort(
(a, b) => (b['rating'] as double)
    .compareTo(a['rating'] as double),
);
} else if (_sortBy == 'Lowest fee') {
results.sort(
(a, b) => (a['fee'] as int).compareTo(b['fee'] as int),
);
} else if (_sortBy == 'Most experienced') {
results.sort(
(a, b) =>
(b['experience'] as int).compareTo(a['experience'] as int),
);
}

return results;
}

@override
Widget build(BuildContext context) {
final doctors = _filteredDoctors;

return Scaffold(
backgroundColor: const Color(0xFFF8FAFC),
appBar: AppBar(
backgroundColor: Colors.white,
surfaceTintColor: Colors.transparent,
elevation: 0,
title: const Text(
'Find Doctors',
style: TextStyle(
color: darkText,
fontWeight: FontWeight.bold,
),
),
centerTitle: false,
),
body: SafeArea(
child: Column(
children: [
Expanded(
child: ListView(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
children: [
const Text(
'Find the right care for you',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 6),
const Text(
'Search specialists and explore healthcare options.',
style: TextStyle(
fontSize: 14,
color: mutedText,
height: 1.5,
),
),
const SizedBox(height: 22),

// Search field
TextField(
controller: _searchController,
onChanged: (_) => setState(() {}),
decoration: InputDecoration(
hintText: 'Doctor name or specialty',
hintStyle: const TextStyle(
color: mutedText,
fontSize: 14,
),
prefixIcon: const Icon(
Icons.search_rounded,
color: darkTeal,
),
suffixIcon: _searchController.text.isNotEmpty
? IconButton(
onPressed: () {
_searchController.clear();
setState(() {});
},
icon: const Icon(Icons.close_rounded),
tooltip: 'Clear search',
)
    : null,
filled: true,
fillColor: Colors.white,
contentPadding: const EdgeInsets.symmetric(
vertical: 17,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Color(0xFFE5E7EB),
),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Color(0xFFE5E7EB),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: primaryTeal,
width: 1.5,
),
),
),
),

const SizedBox(height: 24),

// Specialty filters
const Text(
'Specialties',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 12),
SizedBox(
height: 42,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _specialties.length,
separatorBuilder: (_, __) =>
const SizedBox(width: 8),
itemBuilder: (context, index) {
final specialty = _specialties[index];
final selected =
_selectedSpecialty == specialty;

return ChoiceChip(
label: Text(specialty),
selected: selected,
showCheckmark: false,
selectedColor: darkTeal,
backgroundColor: Colors.white,
side: BorderSide(
color: selected
? darkTeal
    : const Color(0xFFE5E7EB),
),
labelStyle: TextStyle(
color: selected ? Colors.white : darkText,
fontSize: 12,
fontWeight: selected
? FontWeight.w600
    : FontWeight.normal,
),
onSelected: (_) {
setState(() {
_selectedSpecialty = specialty;
});
},
);
},
),
),

const SizedBox(height: 24),

// Results header and sorting
Row(
children: [
Expanded(
child: Text(
'Available doctors (${doctors.length})',
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
color: darkText,
),
),
),
PopupMenuButton<String>(
tooltip: 'Sort doctors',
initialValue: _sortBy,
onSelected: (value) {
setState(() {
_sortBy = value;
});
},
itemBuilder: (context) => const [
PopupMenuItem(
value: 'Recommended',
child: Text('Recommended'),
),
PopupMenuItem(
value: 'Highest rated',
child: Text('Highest rated'),
),
PopupMenuItem(
value: 'Lowest fee',
child: Text('Lowest fee'),
),
PopupMenuItem(
value: 'Most experienced',
child: Text('Most experienced'),
),
],
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(10),
border: Border.all(
color: const Color(0xFFE5E7EB),
),
),
child: const Row(
children: [
Icon(
Icons.tune_rounded,
size: 17,
color: darkTeal,
),
SizedBox(width: 5),
Text(
'Sort',
style: TextStyle(
fontSize: 12,
color: darkText,
),
),
],
),
),
),
],
),

const SizedBox(height: 14),

if (doctors.isEmpty)
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 24,
vertical: 36,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: const Color(0xFFE5E7EB),
),
),
child: const Column(
children: [
Icon(
Icons.search_off_rounded,
size: 48,
color: mutedText,
),
SizedBox(height: 12),
Text(
'No doctors found',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 17,
color: darkText,
),
),
SizedBox(height: 6),
Text(
'Try another name or specialty.',
textAlign: TextAlign.center,
style: TextStyle(
color: mutedText,
fontSize: 13,
),
),
],
),
)
else
...doctors.map(
(doctor) => Padding(
padding: const EdgeInsets.only(bottom: 14),
child: _DoctorCard(
doctor: doctor,
onViewProfile: () =>
_showDoctorDetails(context, doctor),
onBook: () => _showBookingMessage(
context,
doctor,
),
),
),
),

const SizedBox(height: 8),
const Center(
child: Text(
'Demo doctors · Sample information only',
style: TextStyle(
color: mutedText,
fontSize: 11,
),
),
),
],
),
),
],
),
),
);
}

void _showDoctorDetails(
BuildContext context,
Map<String, dynamic> doctor,
) {
showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
backgroundColor: Colors.white,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(24),
),
),
builder: (context) {
return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 42,
height: 4,
decoration: BoxDecoration(
color: const Color(0xFFD1D5DB),
borderRadius: BorderRadius.circular(4),
),
),
),
const SizedBox(height: 24),
Row(
children: [
_DoctorAvatar(doctor: doctor, size: 72),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
doctor['name'] as String,
style: const TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 5),
Text(
doctor['specialty'] as String,
style: const TextStyle(
color: darkTeal,
fontSize: 14,
),
),
const SizedBox(height: 5),
Text(
'${doctor['rating']} ★ · '
'${doctor['reviews']} reviews',
style: const TextStyle(
color: mutedText,
fontSize: 12,
),
),
],
),
),
],
),
const SizedBox(height: 24),
_DetailRow(
icon: Icons.school_outlined,
label: 'Qualification',
value: doctor['qualification'] as String,
),
_DetailRow(
icon: Icons.work_outline_rounded,
label: 'Experience',
value: '${doctor['experience']} years',
),
_DetailRow(
icon: Icons.currency_rupee_rounded,
label: 'Consultation fee',
value: '₹${doctor['fee']}',
),
_DetailRow(
icon: Icons.circle,
label: 'Availability',
value: doctor['available'] as bool
? 'Available for booking'
    : 'Currently unavailable',
),
const SizedBox(height: 20),
SizedBox(
width: double.infinity,
height: 52,
child: ElevatedButton(
onPressed: doctor['available'] as bool
? () {
Navigator.pop(context);
_showBookingMessage(context, doctor);
}
    : null,
style: ElevatedButton.styleFrom(
backgroundColor: darkTeal,
foregroundColor: Colors.white,
disabledBackgroundColor:
const Color(0xFFE5E7EB),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text('Book Appointment'),
),
),
],
),
),
);
},
);
}

void _showBookingMessage(
BuildContext context,
Map<String, dynamic> doctor,
) {
if (!(doctor['available'] as bool)) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('This doctor is currently unavailable.'),
behavior: SnackBarBehavior.floating,
),
);
return;
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Booking with ${doctor['name']} will be available '
'after appointment integration.',
),
behavior: SnackBarBehavior.floating,
),
);
}
}

class _DoctorCard extends StatelessWidget {
const _DoctorCard({
required this.doctor,
required this.onViewProfile,
required this.onBook,
});

final Map<String, dynamic> doctor;
final VoidCallback onViewProfile;
final VoidCallback onBook;

static const Color darkTeal = Color(0xFF007A8A);
static const Color darkText = Color(0xFF1F2937);
static const Color mutedText = Color(0xFF6B7280);

@override
Widget build(BuildContext context) {
final available = doctor['available'] as bool;

return Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: const Color(0xFFE5E7EB),
),
),
child: Column(
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_DoctorAvatar(doctor: doctor, size: 66),
const SizedBox(width: 13),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
doctor['name'] as String,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 5),
Text(
doctor['specialty'] as String,
style: const TextStyle(
fontSize: 12,
color: darkTeal,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
doctor['qualification'] as String,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 11,
color: mutedText,
),
),
const SizedBox(height: 7),
Wrap(
crossAxisAlignment: WrapCrossAlignment.center,
spacing: 5,
runSpacing: 4,
children: [
const Icon(
Icons.star_rounded,
size: 16,
color: Color(0xFFF59E0B),
),
Text(
'${doctor['rating']}',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 12,
color: darkText,
),
),
Text(
'(${doctor['reviews']} reviews)',
style: const TextStyle(
color: mutedText,
fontSize: 11,
),
),
],
),
],
),
),
],
),
const SizedBox(height: 14),
const Divider(height: 1, color: Color(0xFFE5E7EB)),
const SizedBox(height: 12),
Row(
children: [
const Icon(
Icons.work_outline_rounded,
color: mutedText,
size: 17,
),
const SizedBox(width: 5),
Text(
'${doctor['experience']} yrs exp.',
style: const TextStyle(
color: mutedText,
fontSize: 11,
),
),
const Spacer(),
Text(
'₹${doctor['fee']}',
style: const TextStyle(
color: darkText,
fontWeight: FontWeight.bold,
fontSize: 17,
),
),
const Text(
' / visit',
style: TextStyle(
color: mutedText,
fontSize: 10,
),
),
],
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: onViewProfile,
style: OutlinedButton.styleFrom(
foregroundColor: darkTeal,
side: const BorderSide(color: darkTeal),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(11),
),
padding: const EdgeInsets.symmetric(vertical: 12),
),
child: const Text(
'View Profile',
style: TextStyle(fontSize: 12),
),
),
),
const SizedBox(width: 10),
Expanded(
child: ElevatedButton(
onPressed: available ? onBook : null,
style: ElevatedButton.styleFrom(
backgroundColor: darkTeal,
foregroundColor: Colors.white,
disabledBackgroundColor:
const Color(0xFFE5E7EB),
disabledForegroundColor: mutedText,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(11),
),
padding: const EdgeInsets.symmetric(vertical: 12),
),
child: Text(
available ? 'Book Visit' : 'Unavailable',
style: const TextStyle(fontSize: 12),
),
),
),
],
),
],
),
);
}
}

class _DoctorAvatar extends StatelessWidget {
const _DoctorAvatar({
required this.doctor,
required this.size,
});

final Map<String, dynamic> doctor;
final double size;

@override
Widget build(BuildContext context) {
return CircleAvatar(
radius: size / 2,
backgroundColor: Color(doctor['color'] as int),
child: Text(
doctor['initials'] as String,
style: const TextStyle(
fontWeight: FontWeight.bold,
color: Color(0xFF1F2937),
fontSize: 19,
),
),
);
}
}

class _DetailRow extends StatelessWidget {
const _DetailRow({
required this.icon,
required this.label,
required this.value,
});

final IconData icon;
final String label;
final String value;

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.only(bottom: 16),
child: Row(
children: [
Icon(icon, color: const Color(0xFF007A8A), size: 21),
const SizedBox(width: 12),
Expanded(
child: Text(
label,
style: const TextStyle(
color: Color(0xFF6B7280),
fontSize: 13,
),
),
),
Flexible(
child: Text(
value,
textAlign: TextAlign.end,
style: const TextStyle(
color: Color(0xFF1F2937),
fontWeight: FontWeight.w600,
fontSize: 13,
),
),
),
],
),
);
}
}
