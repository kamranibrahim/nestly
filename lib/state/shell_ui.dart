import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active tab index for [AppShell]. Lives with the shell for the whole app
/// session — not autoDispose.
class ShellTabController extends StateNotifier<int> {
  ShellTabController() : super(0);

  void go(int index) {
    if (index == state) return;
    state = index;
  }
}

final shellTabProvider = StateNotifierProvider<ShellTabController, int>((ref) {
  return ShellTabController();
});
