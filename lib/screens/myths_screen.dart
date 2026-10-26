import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';

class MythsScreen extends StatefulWidget {
  const MythsScreen({super.key});
  @override
  State<MythsScreen> createState() => _MythsScreenState();
}

class _MythsScreenState extends State<MythsScreen> {
  String? _selectedMyth;
  bool _isProcessing = false;

  // Функция сканирования карты
  Future<void> _scanCard(GameState s) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // Сжимаем фото для скорости
    );

    if (photo == null) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      // Используем латиницу (она отлично распознает кириллицу)
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text.trim();

      // Берем только первую строку (обычно это название карты)
      if (extractedText.contains('\n')) {
        extractedText = extractedText.split('\n').first.trim();
      }

      if (extractedText.isNotEmpty) {
        s.addMyth(extractedText);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Распознано: $extractedText')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Текст не распознан. Попробуйте еще раз.')),
        );
      }
      textRecognizer.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка распознавания: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Сыгранные мифы')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownMenu<String>(
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Выберите карту'),
                    dropdownMenuEntries: s.availableMyths
                        .map((m) => DropdownMenuEntry(value: m, label: m))
                        .toList(),
                    onSelected: (val) {
                      setState(() => _selectedMyth = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedMyth == null
                      ? null
                      : () {
                    s.addMyth(_selectedMyth!);
                    setState(() => _selectedMyth = null);
                  },
                  child: const Text('Добавить'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _scanCard(s),
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt),
                label: Text(_isProcessing ? 'Распознавание...' : 'Добавить карту с камеры'),
              ),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: s.playedMyths.isEmpty
                ? const Center(child: Text('Список пуст'))
                : ListView.builder(
              itemCount: s.playedMyths.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(s.playedMyths[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => s.removeMyth(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}