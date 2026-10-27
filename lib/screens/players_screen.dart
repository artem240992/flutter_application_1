import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  static const _roles = ['unknown', 'human', 'hybrid', 'cultist'];
  static const _roleNames = {
    'unknown': 'Не раскрыта',
    'human': 'Человек',
    'hybrid': 'Гибрид',
    'cultist': 'Культист',
  };

  static const _characters = [
    'Не выбран',
    'Агата Крейн',
    'Отец Матео',
    'Дэвид Марш',
    'Мин Тхи',
    'Карсон Синклер',
    'Кезия Мейсон',
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Игроки и персонажи')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: s.players.length,
        itemBuilder: (ctx, i) {
          final p = s.players[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Верхняя строка: Имя и кнопка удаления
                  Row(
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      if (s.players.length > 1) // Прячем корзину, если игрок один
                        IconButton(
                          tooltip: 'Удалить игрока',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => s.removePlayer(i),
                        ),
                    ],
                  ),

                  // Переключатели Капитан/Хранитель
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Капитан'),
                        selected: p.isCaptain,
                        onSelected: (_) => s.setCaptain(i),
                      ),
                      ChoiceChip(
                        label: const Text('Хранитель'),
                        selected: p.isKeeper,
                        onSelected: (_) => s.setKeeper(i),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Выбор персонажа
                  DropdownButtonFormField<String>(
                    value: p.characterName,
                    decoration: const InputDecoration(
                      labelText: 'Персонаж',
                      isDense: true,
                    ),
                    items: _characters
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) s.setCharacter(i, v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Характеристики (появляются, если выбран персонаж)
                  if (p.characterName != 'Не выбран') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Сила', p.strength),
                        _buildStat('Воля', p.will),
                        _buildStat('Знание', p.lore),
                        _buildStat('Влияние', p.influence),
                        _buildStat('Наблюд.', p.observation),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Тайная роль
                  DropdownButtonFormField<String>(
                    value: p.role,
                    decoration: const InputDecoration(
                      labelText: 'Тайная роль',
                      isDense: true,
                    ),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(_roleNames[r]!),
                    ))
                        .toList(),
                    onChanged: (v) => s.setRole(i, v ?? 'unknown'),
                  ),
                  const SizedBox(height: 8),

                  // Поле для заметок/способностей
                  TextFormField(
                    initialValue: p.specialAction,
                    decoration: const InputDecoration(
                      labelText: 'Способности и действия',
                      hintText: 'Например: +1 к проверке Воли',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      p.specialAction = val;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Кнопка добавления игрока (появляется, если игроков меньше 6)
      floatingActionButton: s.players.length < 6
          ? FloatingActionButton(
        tooltip: 'Добавить игрока',
        onPressed: () => s.addPlayer(),
        child: const Icon(Icons.person_add),
      )
          : null,
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}