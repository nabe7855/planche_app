import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/agreement_screen.dart';
import 'features/onboarding/models/user_profile.dart';
import 'features/training/models/training_session.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(TrainingSessionAdapter());

  // Open boxes
  await Hive.openBox<UserProfile>('user_profile_box');

  runApp(const ProviderScope(child: PlancheApp()));
}

class PlancheApp extends ConsumerWidget {
  const PlancheApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Planche Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          } else {
            // プロフィールがHiveにあるかチェック
            final profileBox = Hive.box<UserProfile>('user_profile_box');
            final profile = profileBox.isNotEmpty ? profileBox.getAt(0) : null;

            if (profile == null) {
              return const AgreementScreen();
            } else {
              return const HomeScreen();
            }
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, stack) => Scaffold(body: Center(child: Text('認証エラー: $e'))),
      ),
    );
  }
}
