import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'profile_setup_screen.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                '安全のための同意事項',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'プランシェ習得には高い身体負荷が伴います。怪我を防ぎ、効率的に成長するために、以下の事項に同意してください。',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _DisclaimerItem(
                          icon: Icons.medical_services_outlined,
                          title: '医療アドバイスではありません',
                          description: '本アプリの提供する情報は医師の診断に代わるものではありません。',
                        ),
                        _DisclaimerItem(
                          icon: Icons.warning_amber_rounded,
                          title: '痛みを感じたら中止する',
                          description: '鋭い痛みやしびれを感じた場合は、直ちに練習を中止してください。',
                        ),
                        _DisclaimerItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'データの取り扱い',
                          description: '怪我歴などの配慮が必要な情報は、原則として端末内にのみ保存されます。',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (val) =>
                        setState(() => _isAgreed = val ?? false),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Expanded(
                    child: Text(
                      '上記の内容を確認し、自身の責任でトレーニングを行うことに同意します。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAgreed
                      ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileSetupScreen(),
                            ),
                          );
                        }
                      : null,
                  child: const Text('同意して始める'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DisclaimerItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
