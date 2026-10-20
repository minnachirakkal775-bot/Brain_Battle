import 'package:flutter/material.dart';

import 'database_helper.dart';

class DatabaseTestScreen extends StatefulWidget {
const DatabaseTestScreen({super.key});

@override
State<DatabaseTestScreen> createState() =>
_DatabaseTestScreenState();
}

class _DatabaseTestScreenState
extends State<DatabaseTestScreen> {
bool _loading = true;
bool _success = false;

String _message = 'Testing database...';
String _databasePath = '';
List<String> _tables = [];

@override
void initState() {
super.initState();
_testDatabase();
}

Future<void> _testDatabase() async {
setState(() {
_loading = true;
_success = false;
_message = 'Opening SQLite database...';
});

try {
final db =
await DatabaseHelper.instance.database;

final path =
await DatabaseHelper.instance.getDatabasePath();

final tables = await db.rawQuery(
'''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
        ORDER BY name
        ''',
);

final tableNames = tables
    .map((table) => table['name'].toString())
    .toList();

if (!mounted) return;

setState(() {
_loading = false;
_success = true;
_message =
'SQLite database created successfully!';
_databasePath = path;
_tables = tableNames;
});
} catch (error) {
if (!mounted) return;

setState(() {
_loading = false;
_success = false;
_message = 'Database test failed.';
_databasePath = '';
_tables = [];
});

debugPrint(
'SQLite database error: $error',
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('SQLite Database Test'),
),
body: RefreshIndicator(
onRefresh: _testDatabase,
child: ListView(
padding: const EdgeInsets.all(20),
children: [
const SizedBox(height: 20),

// Status icon
Icon(
_loading
? Icons.storage
    : _success
? Icons.check_circle
    : Icons.error,
size: 80,
color: _loading
? Colors.blue
    : _success
? Colors.green
    : Colors.red,
),

const SizedBox(height: 20),

// Status
Text(
_message,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 30),

if (_loading)
const Center(
child: CircularProgressIndicator(),
),

if (!_loading && _success) ...[
_buildInfoCard(
title: 'Database Status',
value: 'CONNECTED',
icon: Icons.check_circle,
iconColor: Colors.green,
),

const SizedBox(height: 15),

_buildInfoCard(
title: 'Database Name',
value: 'brain_battle.db',
icon: Icons.storage,
iconColor: Colors.blue,
),

const SizedBox(height: 15),

_buildInfoCard(
title: 'Tables Created',
value: '${_tables.length}',
icon: Icons.table_chart,
iconColor: Colors.deepPurple,
),

const SizedBox(height: 25),

const Text(
'SQLite Tables',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 10),

..._tables.map(
(table) => Card(
child: ListTile(
leading: const Icon(
Icons.table_chart,
),
title: Text(table),
trailing: const Icon(
Icons.check,
color: Colors.green,
),
),
),
),

const SizedBox(height: 20),

const Text(
'Database Location',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

SelectableText(
_databasePath,
style: const TextStyle(
fontSize: 13,
),
),
],

if (!_loading && !_success) ...[
Card(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
const Icon(
Icons.warning,
color: Colors.red,
size: 40,
),
const SizedBox(height: 10),
const Text(
'Could not open the SQLite database.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 16,
),
),
const SizedBox(height: 15),
ElevatedButton.icon(
onPressed: _testDatabase,
icon: const Icon(Icons.refresh),
label: const Text('Try Again'),
),
],
),
),
),
],
],
),
),
);
}

Widget _buildInfoCard({
required String title,
required String value,
required IconData icon,
required Color iconColor,
}) {
return Card(
child: ListTile(
leading: Icon(
icon,
color: iconColor,
size: 32,
),
title: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
subtitle: Text(value),
),
);
}
}