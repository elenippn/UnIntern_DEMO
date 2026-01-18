import 'package:flutter/material.dart';

class CameraCompanyScreen extends StatefulWidget {
  const CameraCompanyScreen({super.key});

  @override
  State<CameraCompanyScreen> createState() => _CameraCompanyScreenState();
}

class _CameraCompanyScreenState extends State<CameraCompanyScreen> {
  bool _isVideo = false;

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
                  color: const Color(0xFFC9D3C9),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20), size: 28),
                      ),
                      const Text(
                        'Camera',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                          fontFamily: 'Trirong',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: Toggle flash
                          print('Flash toggle');
                        },
                        child: const Icon(Icons.flash_on, color: Color(0xFF1B5E20), size: 24),
                      ),
                    ],
                  ),
                ),
              ),

              // Camera preview area
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Color(0xFFC9D3C9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Controls section
              Container(
                color: const Color(0xFFC9D3C9),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo/Video tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVideo = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _isVideo ? Colors.grey : const Color(0xFF1B5E20),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              'PHOTO',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isVideo ? Colors.grey : const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVideo = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_isVideo ? Colors.grey : const Color(0xFF1B5E20),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              'VIDEO',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: !_isVideo ? Colors.grey : const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Camera controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Gallery
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                          ),
                          child: const Icon(Icons.photo, color: Color(0xFF1B5E20), size: 28),
                        ),

                        // Capture button
                        GestureDetector(
                          onTap: () {
                            // TODO: Capture photo/video
                            print('Capture pressed');
                            _showCaptureAnimation();
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1B5E20),
                                width: 3,
                              ),
                              color: const Color(0xFFFAFD9F),
                            ),
                            child: Center(
                              child: Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Switch camera
                        GestureDetector(
                          onTap: () {
                            // TODO: Switch between front/back camera
                            print('Switch camera');
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cameraswitch, color: Color(0xFF1B5E20), size: 28),
                          ),
                        ),
                      ],
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

  void _showCaptureAnimation() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.8),
          ),
          child: const Center(
            child: Icon(Icons.check, color: Color(0xFF1B5E20), size: 60),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context);
    });
  }
}
