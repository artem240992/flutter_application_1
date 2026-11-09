import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../widgets/common.dart';

class SkillCheckScreen extends StatefulWidget {
  const SkillCheckScreen({super.key});

  @override
  State<SkillCheckScreen> createState() => _SkillCheckScreenState();
}

class _SkillCheckScreenState extends State<SkillCheckScreen> {
  final _playerController = TextEditingController();
  final _difficultyController = TextEditingController(text: '4');

  String _selectedSkill = 'Воля';
  int _chaosCard1 = 0;
  int _chaosCard2 = 0;
  bool _isRolled = false;

  // Текущие характеристики (можно менять вручную)
  int _strength = 0;
  int _will = 0;
  int _lore = 0;
  int _influence = 0;
  int _observation = 0;

  final Map<String, int> _skills = {
    'Сила': 0,
    'Воля': 0,
    'Знание': 0,
    'Влияние': 0,
    'Наблюдательность': 0,
  };

  @override
  void initState() {
    super.initState();
    // Инициализируем нулями, но пользователь может ввести свои значения
  }

  int get _baseValue {
    switch (_selectedSkill) {
      case 'Сила': return _strength;
      case 'Воля': return _will;
      case 'Знание': return _lore;
      case 'Влияние': return _influence;
      case 'Наблюдательность': return _observation;
      default: return 0;
    }
  }

  void _rollCards() {
    final random = Random();
    setState(() {
      _chaosCard1 = random.nextInt(5) - 2; // от -2 до 2
      _chaosCard2 = random.nextInt(5) - 2; // от -2 до 2
      _isRolled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _baseValue + _chaosCard1 + _chaosCard2;
    final difficulty = int.tryParse(_difficultyController.text) ?? 4;
    final isSuccess = total >= difficulty;

    return Scaffold(
      appBar: AppBar(title: const Text('Проверка навыка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ввод характеристик (базовое значение)
          TextField(
            decoration: const InputDecoration(
              labelText: 'Значение выбранного навыка',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final v = int.tryParse(val) ?? 0;
              setState(() {
                switch (_selectedSkill) {
                  case 'Сила': _strength = v; break;
                  case 'Воля': _will = v; break;
                  case 'Знание': _lore = v; break;
                  case 'Влияние': _influence = v; break;
                  case 'Наблюдательность': _observation = v; break;
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // Выбор навыка
          DropdownButtonFormField<String>(
            value: _selectedSkill,
            decoration: const InputDecoration(labelText: 'Навык', border: OutlineInputBorder()),
            items: _skills.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSkill = val!;
                _isRolled = false;
              });
            },
          ),
          const SizedBox(height: 16),

          // Сложность проверки
          TextField(
            controller: _difficultyController,
            decoration: const InputDecoration(
              labelText: 'Сложность проверки',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Кнопка броска
          FilledButton.icon(
            onPressed: _rollCards,
            icon: const Icon(Icons.casino),
            label: const Text('Сделать проверку (бросить 2 карты хаоса)'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 24),

          // Результат
          if (_isRolled) ...[
            SectionCard(
              title: 'Результат проверки',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Базовое значение: $_baseValue'),
                  Text('Карта хаоса 1: ${_chaosCard1 > 0 ? '+' : ''}$_chaosCard1'),
                  Text('Карта хаоса 2: ${_chaosCard2 > 0 ? '+' : ''}$_chaosCard2'),
                  const Divider(),
                  Text(
                    'ИТОГО: $total (Сложность: $difficulty)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        border: Border.all(color: isSuccess ? Colors.green : Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSuccess ? 'УСПЕХ' : 'ПРОВАЛ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}