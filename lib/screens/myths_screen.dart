import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';

class MythsScreen extends StatefulWidget {
  const MythsScreen({super.key});
  @override
  State<MythsScreen> createState() => _MythsScreenState();
}

class _MythsScreenState extends State<MythsScreen> {
  String? _selectedMyth;

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
                  // Используем DropdownMenu вместо текстового поля
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
          const Divider(height: 1),
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