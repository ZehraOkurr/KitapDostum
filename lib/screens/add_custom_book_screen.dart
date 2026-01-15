import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; 
import '../models/book.dart';
import '../services/database_service.dart';
import '../services/books_api_service.dart'; 
import 'barcode_scanner_screen.dart'; 

class AddCustomBookScreen extends StatefulWidget {
  const AddCustomBookScreen({super.key});

  @override
  State<AddCustomBookScreen> createState() => _AddCustomBookScreenState();
}

class _AddCustomBookScreenState extends State<AddCustomBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  
  final DatabaseService _dbService = DatabaseService();
  final BookService _apiService = BookService(); 

  File? _selectedImage;
  String? _base64Image;
  bool _isLoading = false;

  // --- 1. BARKOD TARAMA VE OTOMATİK DOLDURMA ---
  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (result != null && result is String) {
      setState(() => _isLoading = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kitap aranıyor... 🔎")));

      final book = await _apiService.searchBookByIsbn(result);

      if (book != null) {
        _titleController.text = book.title;
        _authorController.text = book.author;
        _pageController.text = book.pageCount.toString();

        if (book.thumbnailUrl.isNotEmpty) {
          try {
            final response = await http.get(Uri.parse(book.thumbnailUrl));
            if (response.statusCode == 200) {
               setState(() {
                 _base64Image = base64Encode(response.bodyBytes);
                 _selectedImage = null; // API'den geldiyse dosya seçimini temizle
               });
            }
          } catch (e) {
            print("Resim indirme hatası: $e");
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kitap bulundu! 🎉"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Books'ta bulunamadı, manuel devam et ✍️"), backgroundColor: Colors.orange));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _saveCustomBook() async {
    if (!_formKey.currentState!.validate()) return;
    
    String finalImage = _base64Image ?? ""; 

    setState(() => _isLoading = true);

    final newBook = Book(
      id: "custom_${_generateId()}",
      title: _titleController.text,
      author: _authorController.text,
      description: "Kullanıcı tarafından eklendi.",
      thumbnailUrl: finalImage, 
      pageCount: int.tryParse(_pageController.text) ?? 100,
      currentPage: 0,
      status: 'reading',
    );

    await _dbService.saveBook(newBook);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kitap başarıyla eklendi! 🎉"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    final inputColor = isDark ? const Color(0xFF2C2623) : Colors.grey[100]; // Değişken burada tanımlı

    ImageProvider? displayImage;
    if (_selectedImage != null) {
      displayImage = FileImage(_selectedImage!);
    } else if (_base64Image != null) {
      displayImage = MemoryImage(base64Decode(_base64Image!));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Kitap Ekle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BARKOD TARA BUTONU
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _scanBarcode,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC69C82)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFC69C82)),
                  label: Text("Barkod Tara & Otomatik Doldur", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFC69C82))),
                ),
              ),
              const SizedBox(height: 20),
              
              const Divider(),
              const SizedBox(height: 20),
              Center(child: Text("veya bilgileri elle gir", style: TextStyle(color: Colors.grey[500], fontSize: 12))),
              const SizedBox(height: 20),

              // RESİM ALANI
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: inputColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      image: displayImage != null 
                        ? DecorationImage(image: displayImage, fit: BoxFit.cover)
                        : null
                    ),
                    child: displayImage == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text("Kapak (Opsiyonel)", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                            ],
                          ) 
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // FORM ALANLARI
              _buildLabel("Kitap Adı", textColor),
              // Burada inputColor parametre olarak gönderiliyor
              _buildTextField(_titleController, "Örn: Kendi Notlarım", inputColor, textColor),
              const SizedBox(height: 20),

              _buildLabel("Yazar", textColor),
              _buildTextField(_authorController, "Örn: Zehra", inputColor, textColor),
              const SizedBox(height: 20),

              _buildLabel("Sayfa Sayısı", textColor),
              _buildTextField(_pageController, "Örn: 150", inputColor, textColor, isNumber: true),
              const SizedBox(height: 40),

              // KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC69C82),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Kütüphaneme Ekle", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color)),
    );
  }

  // GÜNCELLENDİ: fillColor (inputColor) parametresi eklendi ve nullable (?) değil.
  Widget _buildTextField(TextEditingController controller, String hint, Color? fillColor, Color textColor, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textColor),
      validator: (value) => value!.isEmpty ? "Bu alan boş kalamaz" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: fillColor, // Parametreden gelen rengi kullan
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}