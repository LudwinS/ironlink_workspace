import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CameraHelper {
  /// Captura una foto desde la cámara web o del dispositivo de forma multiplataforma.
  static Future<Uint8List?> capturePhoto() async {
    // 1. En macOS nativo, image_picker_macos no tiene UI de cámara nativa.
    // Usamos captura nativa por AVFoundation / imagesnap.
    if (!kIsWeb && Platform.isMacOS) {
      final bytes = await _captureMacOSCamera();
      if (bytes != null && bytes.isNotEmpty) {
        return bytes;
      }
    }

    // 2. En iOS, Android, Web o fallback:
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        return await picked.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error en ImagePicker camera: $e');
    }

    return null;
  }

  static Future<Uint8List?> _captureMacOSCamera() async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ironlink_camera_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Buscar binario imagesnap
      final imagesnapPaths = [
        '/opt/homebrew/bin/imagesnap',
        '/usr/local/bin/imagesnap',
        'imagesnap',
      ];

      String? validBinary;
      for (final p in imagesnapPaths) {
        if (p == 'imagesnap' || File(p).existsSync()) {
          validBinary = p;
          break;
        }
      }

      if (validBinary != null) {
        final result = await Process.run(validBinary, ['-w', '0.5', '-q', tempFile.path]);
        if (result.exitCode == 0 && tempFile.existsSync()) {
          final bytes = await tempFile.readAsBytes();
          try {
            await tempFile.delete();
          } catch (_) {}
          return bytes;
        }
      }

      // Fallback script swift AVFoundation
      final swiftScript = '''
import AVFoundation
import CoreMedia
import Foundation

class QuickSnap: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    var imageData: Data?
    let semaphore = DispatchSemaphore(value: 0)

    func takePhoto() -> Data? {
        guard let device = AVCaptureDevice.default(for: .video) else { return nil }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return nil }
        session.sessionPreset = .photo
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.startRunning()
        usleep(400000)
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
        _ = semaphore.wait(timeout: .now() + 3.0)
        session.stopRunning()
        return imageData
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            self.imageData = data
        }
        semaphore.signal()
    }
}

if let data = QuickSnap().takePhoto() {
    let dest = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "${tempFile.path}"
    try? data.write(to: URL(fileURLWithPath: dest))
}
''';
      final scriptFile = File('${tempDir.path}/snap_${DateTime.now().millisecondsSinceEpoch}.swift');
      await scriptFile.writeAsString(swiftScript);

      final swiftResult = await Process.run('swift', [scriptFile.path, tempFile.path]);
      try {
        await scriptFile.delete();
      } catch (_) {}

      if (swiftResult.exitCode == 0 && tempFile.existsSync()) {
        final bytes = await tempFile.readAsBytes();
        try {
          await tempFile.delete();
        } catch (_) {}
        return bytes;
      }
    } catch (e) {
      debugPrint('Error capturando cámara en macOS: $e');
    }
    return null;
  }
}
