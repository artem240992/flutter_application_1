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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Игроки и роли')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: s.players.length,
        itemBuilder: (ctx, i) {
          final p = s.players[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: p.role,
                    decoration: const InputDecoration(labelText: 'Роль'),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(_roleNames[r]!),
                            ))
                        .toList(),
                    onChanged: (v) => s.setRole(i, v ?? 'unknown'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}