import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(PerawatApp());
}

class PerawatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perawat - Monitoring',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PerawatHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PerawatHomePage extends StatefulWidget {
  @override
  _PerawatHomePageState createState() => _PerawatHomePageState();
}

class _PerawatHomePageState extends State<PerawatHomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Map<String, dynamic> pasienData = {
    "01": {"status": 0, "pesan": "", "frekuensi": 0},
    "02": {"status": 0, "pesan": "", "frekuensi": 0},
  };

  @override
  void initState() {
    super.initState();
    _listenToPasien("01");
    _listenToPasien("02");
  }

  void _listenToPasien(String id) {
    _dbRef.child("pasien/$id").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          pasienData[id] = data;
          pasienData[id]?['frekuensi'] ??= 0;
        });

        if (data['status'] == 1) {
          Fluttertoast.showToast(msg: "🔔 ${data['pesan']}");
        }
      }
    });
  }

  void _resetPasien(String id) {
    _dbRef
        .child("pasien/$id")
        .set({
          "status": 0,
          "pesan": "",
          "frekuensi": pasienData[id]?['frekuensi'] ?? 0,
        })
        .then((_) {
          Fluttertoast.showToast(msg: "Pasien $id telah direset");
        });
  }

  Widget _buildCard(String id) {
    int status = pasienData[id]?['status'] ?? 0;
    String pesan = pasienData[id]?['pesan'] ?? "";
    int frekuensi = pasienData[id]?['frekuensi'] ?? 0;

    Color cardColor = status == 1 ? Colors.red[100]! : Colors.green[100]!;
    IconData icon = status == 1 ? Icons.warning : Icons.check_circle;
    Color iconColor = status == 1 ? Colors.red : Colors.green;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: iconColor),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Pasien $id",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              pesan.isNotEmpty ? pesan : "Tidak ada permintaan",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Total Permintaan: $frekuensi",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _resetPasien(id),
              icon: Icon(Icons.refresh),
              label: Text("Reset"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalFrekuensi = pasienData.values
        .map((e) => (e['frekuensi'] ?? 0) as int)
        .fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard Perawat')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "🔢 Total Permintaan Semua Pasien: $totalFrekuensi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [_buildCard("01"), _buildCard("02")],
            ),
          ),
        ],
      ),
    );
  }
}
