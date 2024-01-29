import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Read More',
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExpandableSeeMore(
                    child: Text('Some Text. ' * 10),
                  ),
                  const Divider(height: 30, color: Colors.black, thickness: 1),
                  Builder(builder: (context) {
                    final imageLoadCompleter = Completer();
                    final child = CachedNetworkImage(
                      imageUrl: 'https://picsum.photos/800/600',
                      imageBuilder: (context, imageProvider) {
                        if (!imageLoadCompleter.isCompleted) {
                          imageLoadCompleter.complete();
                        }

                        return Image(
                          fit: BoxFit.fitWidth,
                          image: imageProvider,
                        );
                      },
                    );
                    return ExpandableSeeMore(
                      completer: imageLoadCompleter.future,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          child,
                          const Text('No Baseball, No Life.',
                              style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 30, color: Colors.black, thickness: 1),
                  ExpandableSeeMore(
                    child: Text('Some Text. ' * 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExpandableSeeMore extends HookWidget {
  final double collapsedHeight;
  final Widget child;
  final Future<void>? completer;

  const ExpandableSeeMore({
    super.key,
    required this.child,
    this.collapsedHeight = 100.0,
    this.completer,
  });

  @override
  Widget build(BuildContext context) {
    final contentKey = useMemoized(() => GlobalKey());

    final isExpandable = useState(true);
    final isExpanded = useState(false);

    useEffect(() {
      () async {
        if (completer != null) {
          await completer;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box =
              contentKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && box.size.height < collapsedHeight) {
            isExpandable.value = false;
          }
        });
      }();

      return null;
    }, [child]);

    final maxHeight = isExpandable.value
        ? (isExpanded.value ? double.infinity : collapsedHeight)
        : double.infinity;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ClipRect(
              child: Stack(
                children: [
                  Container(
                    key: contentKey,
                    child: child,
                  ),
                  if (isExpandable.value && !isExpanded.value)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Stack(
                        children: [
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.5),
                                  Colors.white.withOpacity(1.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isExpandable.value) _button(context, isExpanded),
      ],
    );
  }

  Widget _button(BuildContext context, ValueNotifier<bool> isExpanded) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => isExpanded.value = !isExpanded.value,
        child: Text(
          isExpanded.value ? 'Close' : 'See More',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.blue,
              ),
        ),
      ),
    );
  }
}
