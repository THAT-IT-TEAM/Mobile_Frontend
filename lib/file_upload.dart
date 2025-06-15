import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'dart:math';
import 'package:it_team_app/api_service.dart';
import 'package:it_team_app/auth_service.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

late AnimationController _arrowController;
late Animation<Offset> _arrowAnimation;
late Offset _dragStartOffset;
late bool _isDragging = false;

class _FileUploadPageState extends State<FileUploadPage>
    with TickerProviderStateMixin {
  String? fileName;
  List<Map<String, dynamic>> _trips = [];
  String? _selectedTripId;
  bool _isLoadingTrips = true;
  String? _uploadMessage;
  String? _uploadedFileUrl;
  String? _tripsErrorMessage;

  final ApiService _apiService = ApiService();

  late AnimationController _animationController;

  final PageController _pageController = PageController(viewportFraction: 0.5);
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchTrips();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animationController.forward();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoadingTrips = true;
      _tripsErrorMessage = null;
    });
    try {
      final authService = AuthService();
      final email = await authService.getCurrentUserEmail();
      if (email == null) {
        setState(() {
          _tripsErrorMessage = 'No user email found. Please log in again.';
          _trips = [];
        });
        return;
      }
      final userId = await _apiService.getUserIdByEmail(email);
      if (userId == null) {
        setState(() {
          _tripsErrorMessage = 'User ID not found for email.';
          _trips = [];
        });
        return;
      }
      final trips = await _apiService.getTripsByUser(userId);
      setState(() {
        _trips = trips;
      });
    } catch (e) {
      setState(() {
        _tripsErrorMessage = 'Failed to load trips: [${e.toString()}';
        _trips = [];
      });
    } finally {
      setState(() {
        _isLoadingTrips = false;
      });
    }
  }

  Future<void> pickAndUploadFile() async {
    final typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final fileSizeLimit = 5 * 1024 * 1024;
    if (await file.length() > fileSizeLimit) {
      setState(() {
        _uploadMessage = 'File size exceeds limit ($fileSizeLimit bytes).';
        fileName = null;
      });
      return;
    }

    setState(() {
      fileName = file.name;
      _uploadMessage = null;
      _uploadedFileUrl = null;
    });

    try {
      final String? uploadedUrl = await _apiService.uploadFile(File(file.path));
      setState(() {
        if (uploadedUrl != null) {
          _uploadedFileUrl = uploadedUrl;
          _uploadMessage = 'Upload successful!';
        } else {
          _uploadMessage = 'Upload failed.';
        }
      });
    } catch (e) {
      setState(() {
        _uploadMessage = 'Upload failed: ${e.toString()}';
      });
    }
  }

  void _handleCarouselTap(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(details.globalPosition);
    final dx = localOffset.dx;
    final screenWidth = MediaQuery.of(context).size.width;

    if (dx < screenWidth / 2) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkBackground = const Color(0xFF121212);
    final placeholderColor = const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.black,
        elevation: 4,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTapUp: _handleCarouselTap,
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    double offset = (_currentPage - index);
                    double scale = max(0.9, 1 - offset.abs() * 0.3);
                    double opacity = max(0.5, 1 - offset.abs() * 0.5);
                    double translate = offset * -20;

                    return Transform.translate(
                      offset: Offset(translate, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: placeholderColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.image, size: 48, color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: placeholderColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoadingTrips)
                      const Center(child: CircularProgressIndicator())
                    else if (_tripsErrorMessage != null)
                      Center(
                        child: Text(
                          _tripsErrorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF1E1E1E),
                          labelText: 'Select a Trip',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        value: _selectedTripId,
                        items: _trips.map((trip) {
                          return DropdownMenuItem<String>(
                            value: trip['id'] as String,
                            child: Text(trip['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTripId = value;
                            fileName = null;
                            _uploadMessage = null;
                            _uploadedFileUrl = null;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      if (fileName != null)
                        Text('Selected file: $fileName',
                            style: const TextStyle(color: Colors.white)),
                      if (_uploadMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _uploadMessage!,
                            style: TextStyle(
                              color: _uploadMessage!.contains('success')
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                      if (_uploadedFileUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Column(
                            children: [
                              const Text('Uploaded URL:',
                                  style: TextStyle(color: Colors.white)),
                              SelectableText(
                                _uploadedFileUrl!,
                                style: const TextStyle(
                                    color: Colors.blueAccent, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 240),
            GestureDetector(
              onVerticalDragStart: (details) {
                _dragStartOffset = details.globalPosition;
                _isDragging = true;
              },
              onVerticalDragUpdate: (details) {
                final dragDistance = _dragStartOffset.dy - details.globalPosition.dy;
                if (_isDragging && dragDistance > 80) { // Threshold
                  _isDragging = false;
                  pickAndUploadFile();
                }
              },
              onTap: () {
                pickAndUploadFile(); // Fallback tap
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SlideTransition(
                    position: _arrowAnimation,
                    child: Icon(Icons.keyboard_arrow_up, size: 48, color: Colors.white),
                  ),
                  const Text(
                    'Swipe up to upload',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
