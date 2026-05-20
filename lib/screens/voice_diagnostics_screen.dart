part of '../main.dart';

class VoiceDiagnosticsScreen extends StatefulWidget {
  const VoiceDiagnosticsScreen({super.key});

  @override
  State<VoiceDiagnosticsScreen> createState() => _VoiceDiagnosticsScreenState();
}

class _VoiceDiagnosticsScreenState extends State<VoiceDiagnosticsScreen> {
  final FlutterSoundRecorder _diagnosticRecorder = FlutterSoundRecorder();
  final FlutterTts _diagnosticTts = FlutterTts();

  bool _running = false;
  bool _recorderReady = false;
  String _summary = 'Test başlatılmadı';
  final Map<String, String> _results = {
    'Mikrofon izni': 'Bekliyor',
    'Kayıt': 'Bekliyor',
    'Audio format': 'Bekliyor',
    'Backend': 'Bekliyor',
    'STT': 'Bekliyor',
    'Çeviri': 'Bekliyor',
    'TTS': 'Bekliyor',
    'Toplam süre': 'Bekliyor',
  };
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      if (!_recorderReady) {
        await _diagnosticRecorder.openRecorder();
      }
      await configureCallTts(_diagnosticTts);
      if (mounted) setState(() => _recorderReady = true);
    } catch (e) {
      debugPrint('[BridgeCallVoiceDiag] Recorder prepare failed: $e');
      if (mounted) setState(() => _recorderReady = false);
    }
  }

  @override
  void dispose() {
    _diagnosticRecorder.closeRecorder();
    _diagnosticTts.stop();
    super.dispose();
  }

  void _setResult(String key, String value) {
    setState(() {
      _results[key] = value;
      _logs.insert(
        0,
        '${DateTime.now().toIso8601String().substring(11, 19)}  $key: $value',
      );
    });
    debugPrint('[BridgeCallVoiceDiag] $key: $value');
  }

  Future<void> _runDiagnostics() async {
    if (_running) return;
    setState(() {
      _running = true;
      _summary = 'Tanılama çalışıyor...';
      _logs.clear();
      for (final key in _results.keys.toList()) {
        _results[key] = 'Bekliyor';
      }
    });

    final started = DateTime.now();
    try {
      final permissionReady = await _requestMicrophoneForDiagnostics();
      if (!permissionReady) return;

      final health = await _fetchBackendHealth();
      _setResult(
        'Backend',
        health == null
            ? 'Başarısız: health cevabı yok'
            : 'Başarılı: model=${health['whisper_model']} beam=${health['whisper_beam_size']}',
      );
      if (health == null) return;

      if (!_recorderReady) {
        await _prepare();
      }
      if (!_recorderReady) {
        _setResult('Kayıt', 'Başarısız: recorder açılamadı');
        setState(
          () => _summary =
              'Mikrofon izni açık görünüyor ama kayıt motoru başlatılamadı. Uygulamayı tamamen kapatıp yeni build ile tekrar dene.',
        );
        return;
      }

      final path = await _diagnosticPath();
      _setResult('Kayıt', '2 saniye konuş...');
      await _diagnosticRecorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
        audioSource: AudioSource.voice_communication,
        enableVoiceProcessing: true,
        enableNoiseSuppression: true,
        enableEchoCancellation: true,
      );
      await Future.delayed(const Duration(seconds: 2));
      final savedPath = await _diagnosticRecorder.stopRecorder();
      if (savedPath == null) {
        _setResult('Kayıt', 'Başarısız: dosya yolu boş');
        return;
      }

      final file = File(savedPath);
      if (!await file.exists()) {
        _setResult('Kayıt', 'Başarısız: dosya oluşmadı');
        return;
      }

      final bytes = await file.readAsBytes();
      final rms = calculateWavRms(bytes);
      _setResult(
        'Kayıt',
        'Başarılı: ${bytes.length} byte, RMS ${rms.toStringAsFixed(0)}',
      );
      _setResult('Audio format', 'pcm16wav, 16kHz, mono');
      if (bytes.length < 12000 || rms < 60) {
        _setResult('STT', 'Atlandı: ses çok düşük veya kısa');
        setState(
          () =>
              _summary = 'Mikrofon çalışıyor ama ses seviyesi düşük görünüyor.',
        );
        return;
      }

      final response = await _sendAudioToBackend(bytes);
      if (response == null) {
        _setResult('STT', 'Başarısız: backend cevap vermedi');
        return;
      }
      if (response['noSpeech'] == true) {
        _setResult('STT', 'Başarısız: backend ses algılamadı');
        _setResult('Toplam süre', '${response['timingMs'] ?? '-'}');
        return;
      }
      if (response['error'] != null) {
        _setResult('STT', 'Başarısız: ${response['error']}');
        return;
      }

      final original = (response['original'] ?? '').toString();
      final translated = (response['translated'] ?? '').toString();
      _setResult(
        'STT',
        original.isEmpty ? 'Başarısız: boş metin' : 'Başarılı: $original',
      );
      _setResult(
        'Çeviri',
        translated.isEmpty ? 'Başarısız: boş çeviri' : 'Başarılı: $translated',
      );
      _setResult('Toplam süre', '${response['timingMs'] ?? '-'}');

      if (translated.isNotEmpty) {
        await _diagnosticRecorder.closeRecorder();
        _recorderReady = false;
        await Future.delayed(const Duration(milliseconds: 350));
        await _diagnosticTts.stop();
        await configureSpeakerTts(_diagnosticTts);
        await _diagnosticTts.awaitSpeakCompletion(true);
        await _diagnosticTts.setLanguage('en-US');
        await _diagnosticTts.speak(translated);
        _setResult('TTS', 'Başarılı: cihaz TTS başlatıldı');
      } else {
        _setResult('TTS', 'Atlandı: çeviri yok');
      }

      final elapsed = DateTime.now().difference(started).inMilliseconds;
      setState(() => _summary = 'Tanılama tamamlandı (${elapsed}ms).');
    } catch (e) {
      setState(() => _summary = 'Tanılama hatası: $e');
      _logs.insert(0, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<String> _diagnosticPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/bridgecall_voice_diagnostic.wav';
  }

  Future<bool> _requestMicrophoneForDiagnostics() async {
    final status = await Permission.microphone.status;
    debugPrint(
      '[BridgeCallVoiceDiag] Microphone permission status: ${status.name}',
    );
    if (status.isGranted) {
      _setResult('Mikrofon izni', 'Başarılı');
      return true;
    }

    final requested = await Permission.microphone.request();
    debugPrint(
      '[BridgeCallVoiceDiag] Microphone permission requested: ${requested.name}',
    );
    if (requested.isGranted) {
      _setResult('Mikrofon izni', 'Başarılı');
      return true;
    }

    final probed = await _probeMicrophoneAccess();
    if (probed) {
      _setResult('Mikrofon izni', 'Başarılı: iOS ayarı açık, WebRTC doğruladı');
      return true;
    }

    final message = requested.isPermanentlyDenied || requested.isRestricted
        ? 'Başarısız: iOS Ayarlar > BridgeCall > Mikrofon açılmalı'
        : 'Başarısız: ${requested.name}';
    _setResult('Mikrofon izni', message);
    setState(
      () => _summary =
          'Mikrofon izni açık görünse bile uygulama gerçek mikrofon erişimi alamadı. Uygulamayı kapatıp aç veya yeni buildi tekrar kur.',
    );
    return false;
  }

  Future<bool> _probeMicrophoneAccess() async {
    MediaStream? stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      return stream.getAudioTracks().isNotEmpty;
    } catch (e) {
      debugPrint('[BridgeCallVoiceDiag] Microphone probe failed: $e');
      return false;
    } finally {
      for (final track in stream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchBackendHealth() async {
    final healthUri = AppConfig.healthUri;
    if (healthUri == null) {
      _logs.insert(0, 'Backend config eksik: WS_URL verilmedi');
      return null;
    }
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(healthUri)
          .timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      _logs.insert(0, 'Backend health hatası: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>?> _sendAudioToBackend(Uint8List bytes) async {
    final translateUri = AppConfig.wsEndpoint(
      '/ws/translate/diagnostics/voice-diagnostics',
    );
    if (translateUri == null) {
      _logs.insert(0, 'Backend config eksik: WS_URL verilmedi');
      return null;
    }
    final channel = WebSocketChannel.connect(translateUri);
    try {
      channel.sink.add(
        jsonEncode({
          'type': 'config',
          'source_language': 'TR',
          'target_language': 'EN-US',
          'sample_rate': 16000,
          'channels': 1,
          'audio_format': 'pcm16',
        }),
      );
      await Future.delayed(const Duration(milliseconds: 80));
      channel.sink.add(bytes.length > 44 ? bytes.sublist(44) : bytes);
      final raw = await channel.stream.first.timeout(
        const Duration(seconds: 5),
      );
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'caption') {
        return {
          'stage': data['is_final'] == false ? 'partial' : 'final',
          'original': data['text'],
          'translated': data['translation'],
          'timingMs': data['timing_ms'],
        };
      }
      return data;
    } catch (e) {
      _logs.insert(0, 'Backend upload/STT hatası: $e');
      return null;
    } finally {
      channel.sink.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Ses Tanılama'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ses Sistemi Kontrolü',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(_summary, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: _running ? null : _runDiagnostics,
                  icon: Icon(
                    _running ? Icons.hourglass_top_rounded : Icons.mic_rounded,
                  ),
                  label: Text(
                    _running
                        ? 'Test çalışıyor'
                        : '2 Saniyelik Ses Testi Başlat',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: _results.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            entry.value.startsWith('Başarılı')
                                ? Icons.check_circle_rounded
                                : entry.value.startsWith('Başarısız')
                                ? Icons.error_rounded
                                : Icons.info_outline_rounded,
                            color: entry.value.startsWith('Başarılı')
                                ? AppColors.green
                                : entry.value.startsWith('Başarısız')
                                ? AppColors.red
                                : AppColors.yellow,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entry.value,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Canlı Log',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_logs.isEmpty)
                  const Text(
                    'Henüz log yok',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  ..._logs
                      .take(8)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

double calculateWavRms(Uint8List bytes) {
  if (bytes.length <= 44) return 0;
  final data = ByteData.sublistView(bytes);
  double sumSquares = 0;
  var count = 0;
  for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
    final sample = data.getInt16(offset, Endian.little);
    sumSquares += sample * sample;
    count += 1;
  }
  if (count == 0) return 0;
  return math.sqrt(sumSquares / count);
}
