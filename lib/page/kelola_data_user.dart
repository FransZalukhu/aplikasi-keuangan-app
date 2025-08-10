import 'package:flutter/material.dart';

class KelolaDataUserPage extends StatelessWidget {
  const KelolaDataUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data User'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.teal),
              title: Text('Nama User $index'),
              subtitle: const Text('Level: Admin'),
              trailing: const Icon(Icons.edit, color: Colors.orange),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
