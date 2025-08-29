import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_model.dart';

class StudentLocationScreen extends StatefulWidget {
  final String studentId;

  const StudentLocationScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentLocationScreen> createState() => _StudentLocationScreenState();
}

class _StudentLocationScreenState extends State<StudentLocationScreen> {
  GoogleMapController? _mapController;
  StudentModel? _student;
  Marker? _studentMarker;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  void _fetchStudentData() {
    FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return StudentModel.fromMap(snapshot.data()!);
      }
      return null;
    }).listen((student) {
      if (mounted && student != null) {
        setState(() {
          _student = student;
          _updateMarker(student);
        });
      }
    });
  }

  void _updateMarker(StudentModel student) {
    if (student.location != null) {
      final position = LatLng(
        student.location!.latitude,
        student.location!.longitude,
      );
      setState(() {
        _studentMarker = Marker(
          markerId: MarkerId(student.id),
          position: position,
          infoWindow: InfoWindow(
            title: student.name,
            snippet: 'Current Location',
          ),
        );
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_student?.name ?? 'Student Location'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: _student == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _studentMarker?.position ?? const LatLng(24.7136, 46.6753), // Default to Riyadh
                zoom: 15,
              ),
              markers: _studentMarker != null ? {_studentMarker!} : {},
            ),
    );
  }
}
