import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Variabel global untuk menyimpan daftar kamera yang terdeteksi
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Pastikan bindings terinisialisasi jika menggunakan async di fungsi main()
  WidgetsFlutterBinding.ensureInitialized();

  // Dapatkan daftar kamera yang tersedia di perangkat
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error mendapatkan kamera: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugas Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    // Inisialisasi kamera jika kamera tersedia (kita pilih kamera pertama/belakang)
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller!.initialize();
    }
  }

  @override
  void dispose() {
    // Ingat untuk membebaskan memory saat controller tidak digunakan lagi
    _controller?.dispose();
    super.dispose();
  }

  // Fungsi untuk menangkap/capture gambar
  Future<void> _takePicture() async {
    if (_controller == null || _initializeControllerFuture == null) return;

    try {
      // Tunggu hingga kamera siap
      await _initializeControllerFuture;

      // Ambil gambar lalu kembalikan file gambarnya (format XFile)
      final image = await _controller!.takePicture();

      // Perbarui tampilan / state agar gambar ter-load di layar
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      debugPrint('Error saat menjepret gambar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Kamera'),
        actions: [
          // Tambahkan tombol untuk mengulang foto jika gambar sudah ditangkap
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Ambil ulang foto',
              onPressed: () {
                setState(() {
                  _capturedImage = null; // Reset nilai objeknya untuk membuka layar bidik (preview)
                });
              },
            )
        ],
      ),

      // Logika di mana bila gambar belum diambil kita tampilkan viewfinder,
      // tapi bila sudah diambil kita tampilkan _capturedImage-nya
      body: cameras.isEmpty
          ? const Center(child: Text('Maaf, tidak terdeteksi kamera pada perangkat Anda.'))
          : _capturedImage == null
              ? FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // Bila inisialisasi selesai, tampilkan pratinjau bidikan
                      return Center(child: CameraPreview(_controller!));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      // Bila masih loading
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                )
              : Center(
                  // Menampilkan gambar yang telah diambil
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Foto berhasil ditangkap!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 480,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        // Menampilkan objek file dari memori XFile
                        child: Image.file(
                          File(_capturedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

      // Tombol Camera di Bawah
      floatingActionButton: _capturedImage == null
          ? FloatingActionButton(
              onPressed: _takePicture, // Eksekusi fungsi ambil foto
              tooltip: 'Ambil Foto',
              child: const Icon(Icons.camera),
            )
          : null, // Sembunyikan kalau gambar sudah terambil
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
