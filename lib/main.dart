import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main()
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenHome(),
    );
  }
}

class ScreenHome extends StatefulWidget
{
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome>
{
  final SpeechToText speechToText = SpeechToText();

  bool isListening = false;

  String screenText = "Habla en español";

  Future<void> _startListening() async
  {
    final available = await speechToText.initialize(
      onStatus: (status)
      {
        debugPrint("STATUS: $status");
      },

      onError: (error)
      {
        debugPrint("ERROR: ${error.errorMsg}");
      },
    );

    if (!available)
    {
      setState(()
      {
        screenText = "Speech To Text no disponible";
      });

      return;
    }

    setState(()
    {
      isListening = true;
      screenText = "Escuchando...";
    });

    await speechToText.listen(
      localeId: "es_CO",

      onResult: (result)
      {
        debugPrint("TEXTO: ${result.recognizedWords}");

        setState(()
        {
          if (result.recognizedWords.isNotEmpty)
          {
            screenText = result.recognizedWords;
          }
        });
      },
    );
  }

  Future<void> _stopListening() async
  {
    await speechToText.stop();

    setState(()
    {
      isListening = false;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Column(
          children:
          [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),

                  child: Text(
                    screenText,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 50),

              child: GestureDetector(
                onTap: () async
                {
                  if (!isListening)
                  {
                    await _startListening();
                  }
                  else
                  {
                    await _stopListening();
                  }
                },

                child: Container(
                  width: 160,
                  height: 160,

                  decoration: BoxDecoration(
                    color: isListening
                        ? Colors.red
                        : Colors.green,

                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    isListening
                        ? Icons.stop
                        : Icons.mic,

                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
