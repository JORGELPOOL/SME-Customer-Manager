import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

void main() {
  // Must run before any plugin (SharedPreferences, etc.) is touched, or
  // platform channel calls on web/desktop can hang indefinitely.
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runApp(const SmeApp());
}

class SmeApp extends StatefulWidget {
  const SmeApp({super.key});
  @override
  State<SmeApp> createState() => _SmeAppState();
}

class _SmeAppState extends State<SmeApp> {
  final AppState appState = AppState();

  @override
  void initState() {
    super.initState();
    appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'SME Customer Manager',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (context, child) {
          // Catch widget-build errors anywhere in the tree and show a
          // recoverable message instead of a blank/frozen screen.
          ErrorWidget.builder = (FlutterErrorDetails details) => _CrashScreen(details: details);
          return child ?? const SizedBox.shrink();
        },
        home: const RootDecider(),
      ),
    );
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your workspace…', style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }

    final body = state.currentUser == null ? const LoginScreen() : const HomeShell();

    if (state.errorMessage == null) return body;

    return Stack(
      children: [
        body,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B2A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(state.errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      onPressed: () => state.dismissError(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrashScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const _CrashScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.brick, size: 32),
              const SizedBox(height: 12),
              const Text('Something went wrong displaying this screen.',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
