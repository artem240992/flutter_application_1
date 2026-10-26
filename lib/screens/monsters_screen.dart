import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../widgets/common.dart';

class MonstersScreen extends StatelessWidget {
  const MonstersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Монстры')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Глубоководные',
            child: Column(children: [
              StatCounter(
                label: 'На палубе',
                icon: Icons.directions_walk,
                value: s.deepOnDeck,
                onDelta: (d) => s.adjustMonsters('deck', d),
              ),
              StatCounter(
                label: 'В океане',
                icon: Icons.waves,
                value: s.deepInOcean,
                onDelta: (d) => s.adjustMonsters('ocean', d),
              ),
            ]),
          ),
          SectionCard(
            title: 'Древние',
            child: Column(children: [
              SwitchListTile(
                title: const Text('Отец Дагон'),
                value: s.fatherDagon,
                onChanged: (_) => s.toggleBoss('dagon'),
              ),
              SwitchListTile(
                title: const Text('Мать Гидра'),
                value: s.motherHydra,
                onChanged: (_) => s.toggleBoss('hydra'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}