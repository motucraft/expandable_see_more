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
                  ExpandableWidget(
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
                    return ExpandableWidget(
                      completer: imageLoadCompleter.future,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            child,
                            const Text('No Baseball, No Life.',
                                style: TextStyle(fontSize: 24)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 30, color: Colors.black, thickness: 1),
                  ExpandableWidget(
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

class ExpandableWidget extends HookWidget {
  final double collapsedHeight;
  final Widget child;
  final Future<void>? completer;

  const ExpandableWidget({
    super.key,
    required this.child,
    this.collapsedHeight = 150.0,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 100),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: isExpandable.value
                    ? (isExpanded.value ? double.infinity : collapsedHeight)
                    : double.infinity),
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
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.6),
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(1.0),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isExpandable.value)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                isExpanded.value = !isExpanded.value;
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isExpanded.value ? 'See Less' : 'See More',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
