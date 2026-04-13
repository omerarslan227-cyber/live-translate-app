import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String baseWsUrl = 'wss://live-translate-backed-production.up.railway.app';

void main() {
  runApp(const LiveTranslateApp());
}

class LiveTranslateApp extends StatelessWidget {
  const LiveTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Translate',
      theme: ThemeData.dark(),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController roomController =
      TextEditingController(text: 'oda1');

  String sourceLanguageName = 'Türkçe';
  String targetLanguageName = 'Rusça';

  final List<String> languages = const [
    'Türkçe',
    'Rusça',
    'Ukraynaca',
    'İngilizce',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 90,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Live Translate',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Görüntülü konuşma ve canlı altyazı çevirisi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: roomController,
                  decoration: InputDecoration(
                    labelText: 'Oda adı',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: sourceLanguageName,
                  dropdownColor: Colors.black87,
                  decoration: InputDecoration(
                    labelText: 'Kaynak dil',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        sourceLanguageName = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetLanguageName,
                  dropdownColor: Colors.black87,
                  decoration: InputDecoration(
                    labelText: 'Hedef dil',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        targetLanguageName = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (roomController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Oda adı boş olamaz')),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CallScreen(
                            roomName: roomController.text.trim(),
                            sourceLanguageName: sourceLanguageName,
                            targetLanguageName: targetLanguageName,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Çağrıya Gir',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CallScreen extends StatefulWidget {
  final String roomName;
  final String sourceLanguageName;
  final String targetLanguageName;

  const CallScreen({
    super.key,
    required this.roomName,
    required this.sourceLanguageName,
    required this.targetLanguageName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  WebSocketChannel? _signalChannel;
  WebSocketChannel? _translateChannel;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool micOn = true;
  bool camOn = true;
  bool subtitlesOn = true;
  bool cameraStarted = false;
  bool isRecording = false;
  bool _translateSocketReady = false;
  bool _translationInFlight = false;
  bool _isDisposed = false;

  String subtitleText = 'Canlı altyazı burada görünecek';
  String originalSubtitleText = '';
  String statusText = 'Hazır';

  late String sourceLanguageName;
  late String targetLanguageName;

  Timer? _subtitleLoopTimer;
  String _lastTranslatedText = '';
  String _lastOriginalText = '';

  static const Duration subtitleChunkDuration = Duration(milliseconds: 1200);
  static const Duration translateResponseTimeout = Duration(seconds: 6);

  final Map<String, String> sourceLanguages = {
    'Türkçe': 'TR',
    'Rusça': 'RU',
    'Ukraynaca': 'UK',
    'İngilizce': 'EN',
  };

  final Map<String, String> targetLanguages = {
    'Türkçe': 'TR',
    'Rusça': 'RU',
    'Ukraynaca': 'UK',
    'İngilizce': 'EN-US',
  };

  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    sourceLanguageName = widget.sourceLanguageName;
    targetLanguageName = widget.targetLanguageName;
    _initAll();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _recorder.openRecorder();

    _safeSetState(() {
      statusText = 'Hazır. Kamerayı başlat.';
    });
  }

  Future<void> _openCamera() async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 15},
        },
      };

      final stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      _localStream = stream;
      _localRenderer.srcObject = stream;

      _safeSetState(() {
        cameraStarted = true;
        statusText = 'Kamera açıldı';
      });
    } catch (e) {
      _safeSetState(() {
        statusText = 'Kamera hatası: $e';
      });
    }
  }

  Future<String> _tempWavPath() async {
    final dir = await getTemporaryDirectory();
    final millis = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/temp_audio_$millis.wav';
  }

  void _connectTranslateSocket() {
    if (_translateChannel != null) return;

    _safeSetState(() {
      statusText = 'Çeviri bağlantısı kuruluyor...';
    });

    _translateChannel = WebSocketChannel.connect(
      Uri.parse('$baseWsUrl/translate'),
    );

    _translateSocketReady = true;

    _translateChannel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);

          _translationInFlight = false;

          if (data['translated'] != null) {
            final translated = (data['translated'] ?? '').toString().trim();
            final original = (data['original'] ?? '').toString().trim();

            if (translated.isNotEmpty && translated != _lastTranslatedText) {
              _lastTranslatedText = translated;
              _lastOriginalText = original;

              _safeSetState(() {
                subtitleText = translated;
                originalSubtitleText = original;
                statusText = data['cached'] == true
                    ? 'Çeviri hazır (cache)'
                    : 'Çeviri hazır';
              });
            } else {
              _safeSetState(() {
                statusText = data['cached'] == true
                    ? 'Tekrar çeviri cache’den geldi'
                    : 'Aynı çeviri tekrarlandı';
              });
            }
          }

          if (data['error'] != null) {
            _safeSetState(() {
              statusText = 'Çeviri hatası: ${data['error']}';
            });
          }
        } catch (e) {
          _translationInFlight = false;
          _safeSetState(() {
            statusText = 'Çeviri veri hatası: $e';
          });
        }
      },
      onError: (error) {
        _translationInFlight = false;
        _translateSocketReady = false;
        _translateChannel = null;
        _safeSetState(() {
          statusText = 'Çeviri soketi hatası: $error';
        });
      },
      onDone: () {
        _translationInFlight = false;
        _translateSocketReady = false;
        _translateChannel = null;
        _safeSetState(() {
          statusText = 'Çeviri bağlantısı kapandı';
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _ensureTranslateSocketConnected() async {
    if (_translateChannel == null || !_translateSocketReady) {
      _connectTranslateSocket();
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _sendRecordedChunk() async {
    if (!isRecording || _translationInFlight) return;

    try {
      await _ensureTranslateSocketConnected();

      if (_translateChannel == null) {
        _safeSetState(() {
          statusText = 'Çeviri bağlantısı kurulamıyor';
        });
        return;
      }

      final path = await _tempWavPath();

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
      );

      await Future.delayed(subtitleChunkDuration);

      final savedPath = await _recorder.stopRecorder();

      if (!isRecording) return;

      if (savedPath != null) {
        final file = File(savedPath);

        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();

          if (fileBytes.isNotEmpty) {
            final audioBase64 = base64Encode(fileBytes);

            _translationInFlight = true;

            _translateChannel?.sink.add(jsonEncode({
              'audio': audioBase64,
              'sourceLang': sourceLanguages[sourceLanguageName],
              'targetLang': targetLanguages[targetLanguageName],
            }));

            _safeSetState(() {
              statusText = 'Çeviri işleniyor...';
            });

            Future.delayed(translateResponseTimeout, () {
              if (_translationInFlight && !_isDisposed) {
                _translationInFlight = false;
                _safeSetState(() {
                  statusText = 'Çeviri yanıtı gecikti, yeni parça bekleniyor';
                });
              }
            });
          }

          try {
            await file.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      _translationInFlight = false;
      _safeSetState(() {
        statusText = 'Kayıt hatası: $e';
      });
      await _stopSubtitleRecording();
    }
  }

  Future<void> _startSubtitleRecording() async {
    if (isRecording) return;

    if (sourceLanguageName == targetLanguageName) {
      _safeSetState(() {
        statusText = 'Kaynak ve hedef dil aynı olamaz';
      });
      return;
    }

    await _ensureTranslateSocketConnected();

    if (_translateChannel == null) {
      _safeSetState(() {
        statusText = 'Çeviri bağlantısı kurulamadı';
      });
      return;
    }

    isRecording = true;
    _translationInFlight = false;

    _subtitleLoopTimer?.cancel();
    _subtitleLoopTimer = Timer.periodic(
      subtitleChunkDuration + const Duration(milliseconds: 150),
      (_) async {
        if (!isRecording || _translationInFlight) return;
        await _sendRecordedChunk();
      },
    );

    _safeSetState(() {
      statusText = 'Canlı altyazı başladı';
    });

    await _sendRecordedChunk();
  }

  Future<void> _stopSubtitleRecording() async {
    isRecording = false;
    _translationInFlight = false;
    _subtitleLoopTimer?.cancel();
    _subtitleLoopTimer = null;

    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (_) {}

    _safeSetState(() {
      statusText = 'Canlı altyazı durduruldu';
    });
  }

  Future<void> _connectSignalSocket() async {
    if (_signalChannel != null) return;

    _signalChannel = WebSocketChannel.connect(
      Uri.parse('$baseWsUrl/signal'),
    );

    _signalChannel!.stream.listen(
      (message) async {
        await _handleSignal(message);
      },
      onError: (error) {
        _safeSetState(() {
          statusText = 'Signal hatası: $error';
        });
      },
      onDone: () {
        _signalChannel = null;
        _safeSetState(() {
          statusText = 'Signal bağlantısı kapandı';
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceConfig);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
        _safeSetState(() {
          statusText = 'Karşı taraf bağlandı';
        });
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _sendSignal({
          'type': 'candidate',
          'room': widget.roomName,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        });
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      _safeSetState(() {
        statusText = 'Bağlantı: $state';
      });
    };
  }

  Future<void> _joinRoom() async {
    if (!cameraStarted) {
      _safeSetState(() {
        statusText = 'Önce kamerayı aç';
      });
      return;
    }

    if (widget.roomName.isEmpty) {
      _safeSetState(() {
        statusText = 'Oda adı boş olamaz';
      });
      return;
    }

    await _connectSignalSocket();
    await _createPeerConnection();

    _sendSignal({
      'type': 'join',
      'room': widget.roomName,
    });

    _safeSetState(() {
      statusText = 'Odaya girildi: ${widget.roomName}';
    });
  }

  Future<void> _startCall() async {
    if (_peerConnection == null) {
      _safeSetState(() {
        statusText = 'Önce odaya gir';
      });
      return;
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _sendSignal({
      'type': 'offer',
      'room': widget.roomName,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });

    _safeSetState(() {
      statusText = 'Arama isteği gönderildi';
    });
  }

  Future<void> _handleSignal(dynamic rawMessage) async {
    final data = jsonDecode(rawMessage);

    if (data['room'] != widget.roomName) return;

    final type = data['type'];

    if (type == 'join') {
      _safeSetState(() {
        statusText = 'Bir kullanıcı daha odaya girdi';
      });
      return;
    }

    if (_peerConnection == null) return;

    if (type == 'offer') {
      final desc = RTCSessionDescription(
        data['sdp'],
        data['sdpType'],
      );
      await _peerConnection!.setRemoteDescription(desc);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _sendSignal({
        'type': 'answer',
        'room': widget.roomName,
        'sdp': answer.sdp,
        'sdpType': answer.type,
      });

      _safeSetState(() {
        statusText = 'Gelen arama kabul edildi';
      });
    } else if (type == 'answer') {
      final desc = RTCSessionDescription(
        data['sdp'],
        data['sdpType'],
      );
      await _peerConnection!.setRemoteDescription(desc);

      _safeSetState(() {
        statusText = 'Bağlantı tamamlandı';
      });
    } else if (type == 'candidate') {
      final c = data['candidate'];
      final candidate = RTCIceCandidate(
        c['candidate'],
        c['sdpMid'],
        c['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    }
  }

  void _sendSignal(Map<String, dynamic> message) {
    _signalChannel?.sink.add(jsonEncode(message));
  }

  Future<void> _toggleMic() async {
    if (_localStream == null) return;

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !track.enabled;
      micOn = track.enabled;
    }

    _safeSetState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_localStream == null) return;

    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !track.enabled;
      camOn = track.enabled;
    }

    _safeSetState(() {});
  }

  Future<void> _hangUp() async {
    await _stopSubtitleRecording();

    await _peerConnection?.close();
    _peerConnection = null;
    _remoteRenderer.srcObject = null;

    _safeSetState(() {
      statusText = 'Arama sonlandırıldı';
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    _subtitleLoopTimer?.cancel();
    _stopSubtitleRecording();

    _signalChannel?.sink.close();
    _translateChannel?.sink.close();
    _peerConnection?.close();

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();

    _recorder.closeRecorder();
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    super.dispose();
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF101522)),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2333),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _remoteRenderer.srcObject != null
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Text(
                          'Karşı taraf videosu burada görünecek',
                          style:
                              TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            width: 120,
            height: 170,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Colors.black,
                child: cameraStarted
                    ? RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Text(
                          'Kamera\nönizleme',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
              ),
            ),
          ),
          if (subtitlesOn)
            Positioned(
              left: 20,
              right: 20,
              bottom: 150,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (originalSubtitleText.isNotEmpty) ...[
                      Text(
                        originalSubtitleText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 90,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Oda: ${widget.roomName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _openCamera,
                  child: const Text('Kamera'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _joinRoom,
                  child: const Text('Odaya Gir'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _startCall,
                  child: const Text('Ara'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  icon: micOn ? Icons.mic : Icons.mic_off,
                  onTap: _toggleMic,
                  color: micOn ? Colors.blueGrey : Colors.grey,
                ),
                _controlButton(
                  icon: camOn ? Icons.videocam : Icons.videocam_off,
                  onTap: _toggleCamera,
                  color: camOn ? Colors.blueGrey : Colors.grey,
                ),
                _controlButton(
                  icon: subtitlesOn ? Icons.subtitles : Icons.subtitles_off,
                  onTap: () {
                    _safeSetState(() {
                      subtitlesOn = !subtitlesOn;
                    });
                  },
                  color: Colors.blueGrey,
                ),
                _controlButton(
                  icon: Icons.play_arrow,
                  onTap: () {
                    _startSubtitleRecording();
                  },
                  color: Colors.green,
                ),
                _controlButton(
                  icon: Icons.stop,
                  onTap: () {
                    _stopSubtitleRecording();
                  },
                  color: Colors.orange,
                ),
                _controlButton(
                  icon: Icons.call_end,
                  onTap: () {
                    _hangUp();
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}