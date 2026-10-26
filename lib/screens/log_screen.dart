import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал'),
        actions: [
          IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.clear_all),
            onPressed: s.clearLog,
          ),
        ],
      ),
      body: s.log.isEmpty
          ? const Center(child: Text('Событий пока нет'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: s.log.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) => ListTile(
                dense: true,
                title: Text(s.log[i]),
              ),
            ),
    );
  }
}