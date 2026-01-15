import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Kontrolcü
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    // Başlangıç ayarları (İstersen değiştirebilirsin)
    // autoStart: true, 
  );

  bool _isScanned = false; // Çift okumayı önlemek için

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- DÜZELTME 1: Arka plan her zaman SİYAH ---
      // Böylece tema ne olursa olsun butonlar görünür
      backgroundColor: Colors.black, 
      
      appBar: AppBar(
        title: const Text("Barkodu Okut", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Geri butonu BEYAZ
        actions: [
          // --- DÜZELTME 2: ValueListenableBuilder ile State Dinleme ---
          // Yeni sürümde kontrolcünün kendisi bir ValueNotifier oldu.
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              // Flaş Durumu: state.torchState
              final isTorchOn = state.torchState == TorchState.on;
              
              // Kamera Yönü: state.cameraDirection
              final isFrontCamera = state.cameraDirection == CameraFacing.front;

              return Row(
                children: [
                  // FLAŞ BUTONU
                  IconButton(
                    color: Colors.white,
                    icon: Icon(
                      isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: isTorchOn ? Colors.yellow : Colors.grey,
                    ),
                    onPressed: () => cameraController.toggleTorch(),
                  ),

                  // KAMERA ÇEVİR BUTONU
                  IconButton(
                    color: Colors.white,
                    icon: Icon(
                      isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                    ),
                    onPressed: () => cameraController.switchCamera(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_isScanned) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              setState(() {
                _isScanned = true; 
              });
              final String code = barcode.rawValue!;
              debugPrint('Barkod bulundu: $code');
              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}