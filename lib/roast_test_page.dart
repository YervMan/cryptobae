import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:ui';

final locale = PlatformDispatcher.instance.locale;

final languageCode = locale.languageCode;
final countryCode = locale.countryCode ?? '';

class RoastTestPage extends StatefulWidget {
  const RoastTestPage({super.key});

  @override
  State<RoastTestPage> createState() => _RoastTestPageState();
}

class _RoastTestPageState extends State<RoastTestPage> {
  String resultText = "Press the button...";
  bool loading = false;

  Future<void> getRoast() async {
    setState(() => loading = true);

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      );

      final callable = functions.httpsCallable('getRoast');

      print("Locale: $languageCode");
      print("Country: $countryCode");

      final response =
          await callable.call({"portfolio": "I hold 1 BTC and 1000 DOGE",
            "locale": languageCode,
            "country": countryCode,
          });

      setState(() {
        resultText = response.data.toString();
      });
    } catch (e) {
      setState(() {
        resultText = "Error: $e";
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crypto Bae Test 💅")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: loading ? null : getRoast,
              child: const Text("Get Roasted 😈"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(resultText),
              ),
            )
          ],
        ),
      ),
    );
  }
}
