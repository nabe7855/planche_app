import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';
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

class PlancheApp extends StatelessWidget {
  const PlancheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planche Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AgreementScreen(),
    );
  }
}
