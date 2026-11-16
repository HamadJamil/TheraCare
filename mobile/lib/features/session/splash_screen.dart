import 'package:flutter/material.dart';

import '../../core/widgets/state_views.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: LoadingView()));
}
