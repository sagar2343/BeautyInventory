import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ActionHistoryScreen extends StatelessWidget {
  const ActionHistoryScreen({Key? key}) : super(key: key);

  Future<List<String>> _getUserActions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('user_actions') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action History'),
      ),
      body: FutureBuilder<List<String>>(
        future: _getUserActions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(snapshot.data![index]),
                );
              },
            );
          } else {
            return const Center(child: Text('No actions recorded.'));
          }
        },
      ),
    );
  }
}
