import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Owns [TextEditingController]s for a modal sheet’s lifetime so they are not
/// disposed while the route is still animating/rebuilding (keyboard insets).
class OwnedControllers extends StatefulWidget {
  const OwnedControllers({
    super.key,
    required this.count,
    required this.builder,
  });

  final int count;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  ) builder;

  @override
  State<OwnedControllers> createState() => _OwnedControllersState();
}

class _OwnedControllersState extends State<OwnedControllers> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.count, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}

/// Standard padded, keyboard-safe sheet body.
Widget sheetBody({
  required BuildContext context,
  required List<Widget> children,
}) {
  final bottom = MediaQuery.viewInsetsOf(context).bottom;
  return Padding(
    padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

Widget sheetHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
