import 'package:flutter/material.dart';

class StylesPage extends StatelessWidget {
  const StylesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview UI'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── TEXTOS ─────────────────────────────
          const Text('Títulos', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Title Large', style: Theme.of(context).textTheme.titleLarge),
          Text('Body Large', style: Theme.of(context).textTheme.bodyLarge),
          Text('Body Medium', style: Theme.of(context).textTheme.bodyMedium),

          const SizedBox(height: 24),

          // ─── BOTONES ────────────────────────────
          const Text('Botones'),
          const SizedBox(height: 8),

          ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
          ElevatedButton(onPressed: null, child: const Text('Disabled')),

          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),

          TextButton(onPressed: () {}, child: const Text('Text Button')),

          FilledButton(onPressed: () {}, child: const Text('Filled')),

          const SizedBox(height: 24),

          // ─── INPUTS ─────────────────────────────
          const Text('Inputs'),
          const SizedBox(height: 8),

          const TextField(
            decoration: InputDecoration(labelText: 'Email', hintText: 'ejemplo@mail.com'),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(labelText: 'Password', errorText: 'Campo requerido'),
          ),

          const SizedBox(height: 24),

          // ─── SWITCH / CHECK ─────────────────────
          const Text('Controles'),
          const SizedBox(height: 8),

          Row(
            children: [
              Switch(value: true, onChanged: (_) {}),
              const SizedBox(width: 8),
              Checkbox(value: true, onChanged: (_) {}),
              const SizedBox(width: 8),
              Radio(value: 1, groupValue: 1, onChanged: (_) {}),
            ],
          ),

          const SizedBox(height: 24),

          // ─── CHIPS ──────────────────────────────
          const Text('Chips'),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('Default')),
              Chip(label: Text('Tag')),
            ],
          ),

          const SizedBox(height: 24),

          // ─── CARD ───────────────────────────────
          const Text('Card'),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              title: const Text('Título'),
              subtitle: const Text('Descripción secundaria'),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),

          const SizedBox(height: 24),

          // ─── LIST TILE ──────────────────────────
          const Text('ListTile'),
          const SizedBox(height: 8),

          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Usuario'),
            subtitle: Text('Descripción'),
          ),

          const Divider(),

          const SizedBox(height: 24),

          // ─── SNACKBAR ───────────────────────────
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Esto es un SnackBar')));
            },
            child: const Text('Mostrar SnackBar'),
          ),

          const SizedBox(height: 24),

          // ─── DIALOG ─────────────────────────────
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Diálogo'),
                  content: const Text('Este es un ejemplo de diálogo'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Mostrar Dialog'),
          ),
        ],
      ),

      // ─── NAVBAR ────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
