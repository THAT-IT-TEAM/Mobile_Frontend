import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:it_team_app/api_service.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  String? fileName;
  int? fileSize;
  List<Map<String, dynamic>> _trips = [];
  String? _selectedTripId;
  bool _isLoadingTrips = true;
  bool _isUploading = false;
  String? _uploadMessage;
  String? _uploadedFileUrl;
  String? _tripsErrorMessage;

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchTrips();
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
      print('Error fetching trips: $e');
      setState(() {
        _tripsErrorMessage = 'Failed to load trips: ${e.toString()}';
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

    if (file == null) {
      // User canceled
      return;
    }

    final fileSizeLimit = 5 * 1024 * 1024; // 5MB
    if (await file.length() > fileSizeLimit) {
      setState(() {
        _uploadMessage = 'File size exceeds limit ($fileSizeLimit bytes).';
        fileName = null;
        fileSize = null;
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
    final filePath = '$userId/${_selectedTripId!}/$fileName';
    const bucketName = 'images'; // Your Supabase storage bucket name

    final String? uploadedUrl = await uploadFile(File(file.path), bucketName, filePath);

    setState(() {
      _isUploading = false;
      if (uploadedUrl != null) {
        _uploadedFileUrl = uploadedUrl;
        _uploadMessage = 'Upload successful!';
        
        // Modify the uploaded file URL to remove '/images/' after '/public/'
        String? modifiedFileUrl = _uploadedFileUrl;
        if (modifiedFileUrl != null) {
          modifiedFileUrl = modifiedFileUrl.replaceFirst('/public/images/', '/public/');
          print('Modified file URL: $modifiedFileUrl'); // Print the modified URL for verification
        }

        // Call the OCR API after successful upload
        if (modifiedFileUrl != null && userId != null && _selectedTripId != null) {
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

    // TODO: Upload `fileBytes` and `fileName` to backend/Cloudinary/etc.
    // print('File name: $fileName');
    // print('File size: $fileSize bytes');
  }

  Future<String?> uploadFile(File file, String bucketName, String filePath) async {
    try {
      final String uploadedFilePath = await _supabaseClient.storage
          .from(bucketName)
          .upload(filePath, file, fileOptions: const FileOptions(cacheControl: '3600'));

      final String publicUrl = _supabaseClient.storage
          .from(bucketName)
          .getPublicUrl(uploadedFilePath);

      print('Successfully uploaded file to $bucketName/$uploadedFilePath. Public URL: $publicUrl');
      return publicUrl;

    } catch (e) {
      print('Error uploading file or getting public URL: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Dispose controllers if any were used here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('File Upload'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoadingTrips
              ? const CircularProgressIndicator()
              : _tripsErrorMessage != null
                  ? Text(
                      _tripsErrorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    if (_trips.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select a Trip',
                        ),
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
                    ] else ...[
                      const Text('No trips available. Please create a trip first.'),
                      const SizedBox(height: 24),
                    ],

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_selectedTripId != null && !_isUploading) ? pickAndUploadFile : null,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white,)
                          : const Text('Pick & Upload Image', style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),),
                    ),
                    const SizedBox(height: 24),

                    if (fileName != null) ...[
                      Text('Selected file: $fileName'),
                    ],

                    if (_uploadMessage != null) ...[
                      Text(_uploadMessage!),
                    ],

                    if (_uploadedFileUrl != null) ...[
                      Text('Uploaded URL:'),
                      SelectableText(_uploadedFileUrl!),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
