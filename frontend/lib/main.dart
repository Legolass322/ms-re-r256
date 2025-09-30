import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'api/aria_api_client.dart';
import 'bloc/requirements_bloc.dart';

void main() {
  runApp(const AriaApp());
}

class AriaApp extends StatelessWidget {
  const AriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RequirementsBloc(apiClient: AriaApiClient()),
      child: MaterialApp(
        title: 'ARIA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
