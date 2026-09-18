import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/building_data_service.dart';
import '../engine/ecef_engine.dart';

class AdminMarkerConfigModal extends StatefulWidget {
  final Function(ReferenceMarker) onSaveMarker;

  const AdminMarkerConfigModal({super.key, required this.onSaveMarker});

  @override
  State<AdminMarkerConfigModal> createState() => _AdminMarkerConfigModalState();
}

class _AdminMarkerConfigModalState extends State<AdminMarkerConfigModal> {
  final _formKey = GlobalKey<FormState>();
  final _markerIdController = TextEditingController(text: 'REF-ENTRANCE-MARKER-01');
  final _nameController = TextEditingController(text: 'North Atrium Entrance');
  final _latController = TextEditingController(text: '25.197197');
  final _lngController = TextEditingController(text: '55.274376');
  final _heightController = TextEditingController(text: '1.65');
  int _selectedFloor = 1;
  final double _physicalWidth = 0.25;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.qrCode, color: Color(0xFF38BDF8), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Admin Reference Marker Config',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Marker ID', _markerIdController),
              const SizedBox(height: 8),
              _buildTextField('Marker Name / Location', _nameController),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField('Latitude', _latController)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('Longitude', _lngController)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField('Base Height (m)', _heightController)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Floor Level', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedFloor,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: List.generate(10, (idx) {
                            return DropdownMenuItem(value: idx + 1, child: Text('Floor ${idx + 1}'));
                          }),
                          onChanged: (val) => setState(() => _selectedFloor = val ?? 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final marker = ReferenceMarker(
                      markerId: _markerIdController.text,
                      name: _nameController.text,
                      floorNumber: _selectedFloor,
                      position: GeodeticCoords(
                        latitude: double.tryParse(_latController.text) ?? 25.197197,
                        longitude: double.tryParse(_lngController.text) ?? 55.274376,
                        height: double.tryParse(_heightController.text) ?? 1.65,
                      ),
                      physicalWidthMeters: _physicalWidth,
                      physicalHeightMeters: _physicalWidth,
                      qrCodeData: 'NAVCORE:${_markerIdController.text}',
                    );
                    widget.onSaveMarker(marker);
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'SAVE REFERENCE MARKER',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }
}
