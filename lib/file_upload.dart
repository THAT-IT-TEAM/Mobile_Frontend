import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:math';
import 'package:it_team_app/api_service.dart';

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
  bool _isUploading = false;
  String? _uploadMessage;
  String? _uploadedFileUrl;
  String? _tripsErrorMessage;

  

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final ApiService _apiService = ApiService();

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

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

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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
      final List<Map<String, dynamic>>? trips = await _supabaseClient
          .from('trips')
          .select('*') as List<Map<String, dynamic>>?;

      setState(() {
        _trips = trips ?? [];
      });
    } catch (e) {
      setState(() {
        _tripsErrorMessage = 'Failed to load trips: \${e.toString()}';
        _trips = [];
      });
    } finally {
      setState(() {
        _isLoadingTrips = false;
      });
    }
  }

  Future<void> pickAndUploadFile() async {
    if (_selectedTripId == null) {
      setState(() {
        _uploadMessage = 'Please select a trip first.';
      });
      return;
    }

    final typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file == null) return;

    final fileSizeLimit = 5 * 1024 * 1024;
    if (await file.length() > fileSizeLimit) {
      setState(() {
        _uploadMessage = 'File size exceeds limit (\$fileSizeLimit bytes).';
        fileName = null;
      });
      return;
    }

    setState(() {
      fileName = file.name;
      _uploadMessage = null;
      _uploadedFileUrl = null;
      _isUploading = true;
    });

    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _uploadMessage = 'Error: User not logged in.';
        _isUploading = false;
      });
      return;
    }

    final filePath = '\$userId/\${_selectedTripId!}/\$fileName';
    const bucketName = 'images';

    final String? uploadedUrl =
        await uploadFile(File(file.path), bucketName, filePath);

    setState(() {
      _isUploading = false;
      if (uploadedUrl != null) {
        _uploadedFileUrl = uploadedUrl;
        _uploadMessage = 'Upload successful!';

        String? modifiedFileUrl = _uploadedFileUrl;
        if (modifiedFileUrl != null) {
          modifiedFileUrl =
              modifiedFileUrl.replaceFirst('/public/images/', '/public/');
        }

        if (modifiedFileUrl != null && _selectedTripId != null) {
          _apiService.callOcrApi(
            fileUrl: modifiedFileUrl,
            userId: userId,
            tripId: _selectedTripId!,
          );
        }
      } else {
        _uploadMessage = 'Upload failed.';
      }
    });
  }

  Future<String?> uploadFile(
      File file, String bucketName, String filePath) async {
    try {
      final String uploadedFilePath = await _supabaseClient.storage
          .from(bucketName)
          .upload(filePath, file,
              fileOptions: const FileOptions(cacheControl: '3600'));

      final String publicUrl =
          _supabaseClient.storage.from(bucketName).getPublicUrl(uploadedFilePath);

      return publicUrl;
    } catch (e) {
      return null;
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
                        Text('Selected file: \$fileName',
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
