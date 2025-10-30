import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivitySnackListener extends StatefulWidget {
  const ConnectivitySnackListener({super.key});

  @override
  State<ConnectivitySnackListener> createState() => _ConnectivitySnackListenerState();
}

class _ConnectivitySnackListenerState extends State<ConnectivitySnackListener> {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _controller;
  bool? _lastOnline;

  void _showSnack(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    _controller = messenger.showSnackBar(
      const SnackBar(
        content: Text('You are offline. Changes will sync when connection returns.'),
        backgroundColor: Color(0xFFB00020),
        duration: Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _hideSnack() {
    _controller?.close();
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.isOnlineStream,
      initialData: ConnectivityService.instance.isOnline,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_lastOnline == null) {
            // Initialize without showing
            _lastOnline = online;
            return;
          }
          // Only on transition online -> offline
          if (_lastOnline == true && online == false) {
            _showSnack(context);
          }
          // Hide on transition offline -> online
          if (_lastOnline == false && online == true) {
            _hideSnack();
          }
          _lastOnline = online;
        });
        return const SizedBox.shrink();
      },
    );
  }
}
