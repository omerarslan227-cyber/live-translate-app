import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String baseWsUrl =
    'wss://live-translate-backed-production.up.railway.app';

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
  final TextEditingController codeController = TextEditingController();

  String sourceLanguageName = 'Türkçe';
  String targetLanguageName = 'Rusça';
  int selectedCapacity = 2;
  bool isOwner = true;

  final List<String> languages = const [
    'Türkçe',
    'Rusça',
    'Ukraynaca',
    'İngilizce',
  ];

  final List<int> capacities = const [2, 4, 6, 8];

  String generateRoomCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return now.substring(now.length - 6);
  }

  String buildRoomLink() {
    final room = roomController.text.trim();
    final code = codeController.text.trim();
    return 'livetranslate://join?room=$room&code=$code';
  }

  @override
  void initState() {
    super.initState();
    codeController.text = generateRoomCode();
  }

  @override
  void dispose() {
    roomController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomLink = buildRoomLink();

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
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
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Özel oda kodu',
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          codeController.text = generateRoomCode();
                        });
                      },
                      child: const Text('Yeni Kod Oluştur'),
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCapacity,
                    dropdownColor: Colors.black87,
                    decoration: InputDecoration(
                      labelText: 'Oda kapasitesi',
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: capacities.map((n) {
                      return DropdownMenuItem(
                        value: n,
                        child: Text('$n kişi'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCapacity = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: isOwner,
                    title: Text(isOwner ? 'Oda oluştur' : 'Odaya katıl'),
                    onChanged: (v) {
                      setState(() {
                        isOwner = v;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              roomName: roomController.text.trim(),
                              privateCode: codeController.text.trim(),
                              sourceLanguageName: sourceLanguageName,
                              targetLanguageName: targetLanguageName,
                              roomCapacity: selectedCapacity,
                              isOwner: isOwner,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isOwner ? 'Oda Oluştur' : 'Odaya Katıl',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: roomLink));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Oda linki kopyalandı'),
                            ),
                          );
                        }
                      },
                      child: const Text('Oda Linkini Kopyala'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Paylaşım linki:\n$roomLink',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CallScreen extends StatefulWidget {
  final String roomName;
  final String privateCode;
  final String sourceLanguageName;
  final String targetLanguageName;
  final int roomCapacity;
  final bool isOwner;

  const CallScreen({
    super.key,
    required this.roomName,
    required this.privateCode,
    required this.sourceLanguageName,
    required this.targetLanguageName,
    required this.roomCapacity,
    required this.isOwner,
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

  String subtitleText = 'Canlı altyazı burada görünecek';
  String statusText = 'Hazır';
  String? myClientId;

  late String sourceLanguageName;
  late String targetLanguageName;

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

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _recorder.openRecorder();

    setState(() {
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

      setState(() {
        cameraStarted = true;
        statusText = 'Kamera açıldı';
      });
    } catch (e) {
      setState(() {
        statusText = 'Kamera hatası: $e';
      });
    }
  }

  Future<String> _tempWavPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/temp_audio.wav';
  }

  void _connectTranslateSocket() {
    if (_translateChannel != null) return;

    _translateChannel = WebSocketChannel.connect(
      Uri.parse('$baseWsUrl/translate'),
    );

    _translateChannel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);

          if (data['translated'] != null) {
            setState(() {
              subtitleText = data['translated'];
            });
          }

          if (data['error'] != null) {
            setState(() {
              statusText = 'Çeviri hatası: ${data['error']}';
            });
          }
        } catch (e) {
          setState(() {
            statusText = 'Çeviri veri hatası: $e';
          });
        }
      },
      onError: (error) {
        setState(() {
          statusText = 'Çeviri soketi hatası: $error';
        });
      },
      onDone: () {
        setState(() {
          statusText = 'Çeviri bağlantısı kapandı';
        });
      },
    );
  }

  Future<void> _startSubtitleRecording() async {
    if (isRecording) return;

    _connectTranslateSocket();
    isRecording = true;

    while (isRecording) {
      try {
        final path = await _tempWavPath();

        await _recorder.startRecorder(
          toFile: path,
          codec: Codec.pcm16WAV,
          numChannels: 1,
          sampleRate: 16000,
        );

        await Future.delayed(const Duration(seconds: 2));

        final savedPath = await _recorder.stopRecorder();

        if (savedPath != null) {
          final file = File(savedPath);
          if (await file.exists()) {
            final fileBytes = await file.readAsBytes();
            final audioBase64 = base64Encode(fileBytes);

            _translateChannel?.sink.add(jsonEncode({
              'audio': audioBase64,
              'sourceLang': sourceLanguages[sourceLanguageName],
              'targetLang': targetLanguages[targetLanguageName],
            }));
          }
        }
      } catch (e) {
        setState(() {
          statusText = 'Kayıt hatası: $e';
        });
        isRecording = false;
      }
    }
  }

  Future<void> _stopSubtitleRecording() async {
    isRecording = false;
    try {
      await _recorder.stopRecorder();
    } catch (_) {}
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
        setState(() {
          statusText = 'Signal hatası: $error';
        });
      },
      onDone: () {
        setState(() {
          statusText = 'Signal bağlantısı kapandı';
        });
      },
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
        setState(() {
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
      setState(() {
        statusText = 'Bağlantı: $state';
      });
    };
  }

  Future<void> _joinRoom() async {
    if (!cameraStarted) {
      setState(() {
        statusText = 'Önce kamerayı aç';
      });
      return;
    }

    if (widget.roomName.isEmpty || widget.privateCode.isEmpty) {
      setState(() {
        statusText = 'Oda adı ve özel kod gerekli';
      });
      return;
    }

    await _connectSignalSocket();
    await _createPeerConnection();

    if (widget.isOwner) {
      _sendSignal({
        'type': 'create_room',
        'room': widget.roomName,
        'capacity': widget.roomCapacity,
        'privateCode': widget.privateCode,
      });

      setState(() {
        statusText = 'Oda oluşturuldu, katılım bekleniyor';
      });
    } else {
      _sendSignal({
        'type': 'request_join',
        'room': widget.roomName,
        'privateCode': widget.privateCode,
      });

      setState(() {
        statusText = 'Katılım isteği gönderildi';
      });
    }
  }

  Future<void> _startCall() async {
    if (_peerConnection == null) {
      setState(() {
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

    setState(() {
      statusText = 'Arama isteği gönderildi';
    });
  }

  Future<void> _handleSignal(dynamic rawMessage) async {
    final data = jsonDecode(rawMessage);
    final type = data['type'];

    if (type == 'welcome') {
      setState(() {
        myClientId = data['clientId'];
      });
      return;
    }

    if (data['room'] != null && data['room'] != widget.roomName) {
      return;
    }

    if (type == 'error') {
      setState(() {
        statusText = data['message'] ?? 'Bilinmeyen hata';
      });
      return;
    }

    if (type == 'room_created') {
      setState(() {
        statusText =
            'Oda hazır. Kapasite: ${widget.roomCapacity} - Kod: ${widget.privateCode}';
      });
      return;
    }

    if (type == 'join_request') {
      final requesterId = data['requesterId'];

      if (mounted) {
        final accept = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Katılma İsteği'),
            content: Text(
              'Yeni bir kullanıcı odaya katılmak istiyor.\nID: $requesterId',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Reddet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kabul Et'),
              ),
            ],
          ),
        );

        _sendSignal({
          'type': 'join_decision',
          'room': widget.roomName,
          'requesterId': requesterId,
          'accept': accept == true,
        });
      }
      return;
    }

    if (type == 'join_accepted') {
      setState(() {
        statusText = 'Odaya giriş onaylandı';
      });
      return;
    }

    if (type == 'join_rejected') {
      setState(() {
        statusText = 'Odaya giriş reddedildi';
      });
      return;
    }

    if (type == 'member_joined') {
      setState(() {
        statusText = 'Yeni bir kullanıcı katıldı';
      });
      return;
    }

    if (type == 'member_left') {
      setState(() {
        statusText = 'Bir kullanıcı odadan çıktı';
      });
      return;
    }

    if (type == 'room_closed') {
      setState(() {
        statusText = 'Oda sahibi çağrıyı kapattı';
      });
      if (mounted) Navigator.pop(context);
      return;
    }

    if (type == 'left_room') {
      setState(() {
        statusText = 'Odadan çıkıldı';
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

      setState(() {
        statusText = 'Gelen arama kabul edildi';
      });
    } else if (type == 'answer') {
      final desc = RTCSessionDescription(
        data['sdp'],
        data['sdpType'],
      );
      await _peerConnection!.setRemoteDescription(desc);

      setState(() {
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
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !track.enabled;
      camOn = track.enabled;
    }
    setState(() {});
  }

  Future<void> _hangUp() async {
    if (_signalChannel != null) {
      _signalChannel!.sink.add(jsonEncode({
        'type': 'leave_room',
      }));
    }

    await _peerConnection?.close();
    _peerConnection = null;
    _remoteRenderer.srcObject = null;

    await _stopSubtitleRecording();

    setState(() {
      statusText = 'Arama sonlandırıldı ve odadan çıkıldı';
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
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
                child: Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Oda: ${widget.roomName}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      widget.isOwner ? 'Sahip' : 'Katılımcı',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kod: ${widget.privateCode} | Kapasite: ${widget.roomCapacity}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openCamera,
                      child: const Text('Kamera'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _joinRoom,
                      child: Text(widget.isOwner ? 'Oluştur' : 'İstek Gönder'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _startCall,
                      child: const Text('Ara'),
                    ),
                  ],
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
                    setState(() {
                      subtitlesOn = !subtitlesOn;
                    });
                  },
                  color: Colors.blueGrey,
                ),
                _controlButton(
                  icon: Icons.play_arrow,
                  onTap: _startSubtitleRecording,
                  color: Colors.green,
                ),
                _controlButton(
                  icon: Icons.stop,
                  onTap: _stopSubtitleRecording,
                  color: Colors.orange,
                ),
                _controlButton(
                  icon: Icons.call_end,
                  onTap: _hangUp,
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