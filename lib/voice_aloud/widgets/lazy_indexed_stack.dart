import 'package:flutter/widgets.dart';

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<WidgetBuilder> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _built;

  @override
  void initState() {
    super.initState();
    _built = List<bool>.filled(widget.children.length, false);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _built = List<bool>.filled(widget.children.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.index.clamp(0, widget.children.length - 1);
    _built[idx] = true;

    return IndexedStack(
      index: idx,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _built[i] ? widget.children[i](context) : const SizedBox.shrink(),
      ],
    );
  }
}
