import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'package:it_team_app/api_service.dart';
import 'package:it_team_app/auth_service.dart';
import 'package:it_team_app/ocr_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:it_team_app/camera_guide_screen.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class FileUploadError extends Error {
  final String message;
  FileUploadError(this.message);
  @override
  String toString() => message;
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
  String? _ocrError;
  bool _fileUploaded = false;

  final ApiService _apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _fetchTrips();

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

  Future<void> _processUploadedFile(XFile file) async {
    if (_fileUploaded) return;

    setState(() {
      fileName = file.name;
      _uploadMessage = 'Processing...';
      _ocrError = null;
      _uploadedFileUrl = null;
    });

    try {
      final uploadedUrl = await _apiService.uploadFile(File(file.path));
      
      if (uploadedUrl != null) {
        setState(() {
          _uploadedFileUrl = uploadedUrl;
          _uploadMessage = 'Processing receipt...';
        });

        final authService = AuthService();
        final email = await authService.getCurrentUserEmail();
        if (email != null) {
          final userId = await _apiService.getUserIdByEmail(email);
          if (userId != null) {
            try {
              await OcrService().callOcrApi(
                fileUrl: uploadedUrl,
                userId: userId,
                tripId: _selectedTripId!,
              );

              setState(() {
                _uploadMessage = 'Receipt processed successfully!';
                _ocrError = null;
                _fileUploaded = true;
              });

              // Wait a moment to show the success message, then pop back
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                Navigator.of(context).pop(); // Go back to dashboard
              }
            } catch (e) {
              setState(() {
                _ocrError = e.toString();
                _uploadMessage = 'Upload successful, but OCR processing failed';
                _fileUploaded = false;
              });
            }
          } else {
            throw FileUploadError('Could not find user ID');
          }
        } else {
          throw FileUploadError('No user email found. Please log in again.');
        }
      } else {
        setState(() {
          _uploadMessage = 'Upload failed';
          _fileUploaded = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadMessage = 'Upload failed: ${e.toString()}';
        _fileUploaded = false;
      });
    }
  }

  Future<void> pickAndUploadFile() async {
    if (_fileUploaded) {
      setState(() {
        _uploadMessage = 'A file has already been uploaded. Please wait.';
      });
      return;
    }

    if (_selectedTripId == null) {
      setState(() {
        _uploadMessage = 'Please select a trip first.';
      });
      return;
    }

    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take a Picture',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (option == null) return;

    XFile? file;
    if (option == 'camera') {
      // Use the camera guide screen for guided photo capture
      file = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(builder: (context) => const CameraGuideScreen()),
      );
    } else {
      final typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'gif'],
      );
      final result = await openFile(acceptedTypeGroups: [typeGroup]);
      if (result != null) {
        file = XFile(result.path);
      }
    }
    
    if (file == null) return;

    final fileSizeLimit = 5 * 1024 * 1024; // 5MB
    if (await file.length() > fileSizeLimit) {
      setState(() {
        _uploadMessage = 'File size exceeds 5MB limit';
        fileName = null;
      });
      return;
    }

    await _processUploadedFile(file);
  }
  @override
  Widget build(BuildContext context) {
    final darkBackground = const Color(0xFF121212);
    final placeholderColor = const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('File Upload'),
        backgroundColor: Colors.black,
        elevation: 4,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
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
                  children: [                    if (_isLoadingTrips)
                      const Center(child: CircularProgressIndicator())
                    else if (_tripsErrorMessage != null)
                      Center(
                        child: Text(
                          _tripsErrorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (_ocrError != null)
                      Center(
                        child: Text(
                          _ocrError!,
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
                            _fileUploaded = false;
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
            const SizedBox(height: 480),
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
                    child: const Icon(Icons.keyboard_arrow_up, size: 48, color: Colors.white),
                  ),
                  Text(
                    _fileUploaded ? 'File uploaded' : 'Swipe up to upload',
                    style: TextStyle(
                      color: _fileUploaded ? Colors.white38 : Colors.white70,
                      fontSize: 16,
                    ),
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