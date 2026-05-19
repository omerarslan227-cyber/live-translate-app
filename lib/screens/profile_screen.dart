part of '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  String _source = 'Türkçe';
  String _target = 'İngilizce';
  bool _avatarMode = false;
  bool _loading = true;

  final List<String> languages = bridgeCallLanguageNames;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await AppStore.loadProfile();
    _nameController.text = profile.displayName;
    _aboutController.text = profile.about;
    _source = profile.preferredSourceLanguage;
    _target = profile.preferredTargetLanguage;
    _avatarMode = profile.avatarMode;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final profile = ProfileData(
      displayName: _nameController.text.trim(),
      about: _aboutController.text.trim(),
      preferredSourceLanguage: _source,
      preferredTargetLanguage: _target,
      avatarMode: _avatarMode,
    );
    await AppStore.saveProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil kaydedildi')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil Bilgileri',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _AppTextField(
                    controller: _nameController,
                    label: 'Görünen ad',
                  ),
                  const SizedBox(height: 14),
                  _AppTextField(
                    controller: _aboutController,
                    label: 'Hakkında',
                    hint: 'Kısa bir açıklama yaz',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _LanguageDropdown(
                    value: _source,
                    label: 'Tercih edilen kaynak dil',
                    items: languages,
                    onChanged: (v) => setState(() => _source = v ?? 'Türkçe'),
                  ),
                  const SizedBox(height: 14),
                  _LanguageDropdown(
                    value: _target,
                    label: 'Tercih edilen hedef dil',
                    items: languages,
                    onChanged: (v) =>
                        setState(() => _target = v ?? 'İngilizce'),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Avatar modu'),
                    subtitle: const Text(
                      'Şimdilik görünüm ayarı olarak saklanır',
                    ),
                    value: _avatarMode,
                    onChanged: (value) => setState(() => _avatarMode = value),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Profili Kaydet'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: AppColors.purple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gizlilik ve güvenlik',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BridgeCall kamera ve mikrofonu yalnızca görüşme için kullanır. Ses, canlı çeviri sağlamak amacıyla güvenli sunucuya gönderilebilir.',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://bridgecall.tech/privacy'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text(
                        'Privacy Policy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
