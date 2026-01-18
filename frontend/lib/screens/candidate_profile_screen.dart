import 'package:flutter/material.dart';

class CandidateProfileScreen extends StatelessWidget {
  final Map candidate;

  const CandidateProfileScreen({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final String rawName = (
      candidate['name'] ??
      candidate['studentName'] ??
      candidate['fullName'] ??
      ''
    ) as String;
    final String firstName = (candidate['firstName'] ?? '') as String;
    final String lastName = (candidate['lastName'] ?? '') as String;
    final String name = rawName.isNotEmpty
        ? rawName
        : '$firstName $lastName'.trim();
    final String university = (candidate['university'] ?? '') as String;
    final String major = (candidate['major'] ?? candidate['department'] ?? '') as String;
    final String description = (candidate['description'] ?? candidate['bio'] ?? '') as String;
    final String location = (candidate['location'] ?? '') as String;
    final String skills = (candidate['skills'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFD9F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
        title: Text(
          name.isNotEmpty ? name : 'Candidate',
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Trirong',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelValue('Name', name.isNotEmpty ? name : 'Student'),
            _labelValue('University', university.isNotEmpty ? university : 'Not provided'),
            _labelValue('Department / Major', major.isNotEmpty ? major : 'Not provided'),
            if (location.isNotEmpty) _labelValue('Location', location),
            _labelValue('Bio', description.isNotEmpty ? description : 'No bio provided'),
            if (skills.isNotEmpty) _labelValue('Skills', skills),
          ],
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontFamily: 'Trirong',
            ),
          ),
        ],
      ),
    );
  }
}
