import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/daily_roast_service.dart';
import '../models/daily_roast.dart';

class DailyRoastPage extends StatefulWidget {
  const DailyRoastPage({super.key});

  @override
  State<DailyRoastPage> createState() => _DailyRoastPageState();
}

class _DailyRoastPageState extends State<DailyRoastPage> {
  final service = DailyRoastService();
  late Future<List<DailyRoast>> futureRoasts;

  @override
  void initState() {
    super.initState();
    futureRoasts = service.fetchTodayRoasts().then(
          (list) => list.map((e) => DailyRoast.fromMap(e)).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crypto Bae 💅"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            onPressed: () async {
              final functions = FirebaseFunctions.instanceFor(
                region: 'europe-west1',
              );

              final callable =
                  functions.httpsCallable('generateDailyRoastsNow');

              await callable();

              setState(() {
                futureRoasts = service.fetchTodayRoasts().then(
                      (list) => list.map((e) => DailyRoast.fromMap(e)).toList(),
                    );
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<DailyRoast>>(
        future: futureRoasts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final roasts = snapshot.data!;

          return ListView.builder(
            itemCount: roasts.length,
            itemBuilder: (context, index) {
              final roast = roasts[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roast.id.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(roast.roast),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: roast.vibeScore / 100,
                      ),
                      const SizedBox(height: 4),
                      Text("Vibe: ${roast.vibeScore}/100"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
