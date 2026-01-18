import 'package:flutter/material.dart';

class AddFileScreen extends StatefulWidget {
  const AddFileScreen({super.key});

  @override
  State<AddFileScreen> createState() => _AddFileScreenState();
}

class _AddFileScreenState extends State<AddFileScreen> {
  final List<String> _uploadedFiles = [
    'file 1',
    'file 2',
    'file 3',
    'file 4',
    'file 5',
    'file 6',
    'file 7',
    'file 8',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Container(
                  color: const Color(0xFFFAFD9F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20), size: 28),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'UnIntern',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                  fontFamily: 'Trirong',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '@Username1',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B5E20),
                          fontFamily: 'Trirong',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Files list
              Expanded(
                child: Container(
                  color: const Color(0xFF1B5E20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Your uploaded files in UnIntern:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Trirong',
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _uploadedFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  // Cuando seleccionas un archivo
                                  Navigator.pop(context, _uploadedFiles[index]);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF1B5E20), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.description,
                                        color: Color(0xFF1B5E20),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _uploadedFiles[index],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1B5E20),
                                          fontFamily: 'Trirong',
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          // Download file
                                          print('Download ${_uploadedFiles[index]}');
                                        },
                                        child: const Icon(
                                          Icons.download,
                                          color: Color(0xFF1B5E20),
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Input bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Open file picker
                        print('Add new file');
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                          color: const Color(0xFFFAFD9F),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF1B5E20)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFD9F),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                        ),
                        child: const Center(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Write here...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        // Send message
                        print('Send message');
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                          color: const Color(0xFFFAFD9F),
                        ),
                        child: const Icon(Icons.send, color: Color(0xFF1B5E20), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
