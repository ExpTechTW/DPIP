import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';

class ImageViewerRoute extends StatefulWidget {
  final String heroTag;
  final String imageUrl;
  final String imageName;

  const ImageViewerRoute({super.key, required this.heroTag, required this.imageUrl, required this.imageName});

  @override
  State<ImageViewerRoute> createState() => _ImageViewerRouteState();
}

class _ImageViewerRouteState extends State<ImageViewerRoute> {
  final TransformationController _controller = TransformationController();
  bool isDownloading = false;
  bool isLoaded = false;
  bool isUiHidden = false;

  Future<void> saveImageToDownloads() async {
    try {
      final folder =
          Platform.isAndroid ? "/storage/emulated/0/Download" : (await getApplicationDocumentsDirectory()).path;
      final file = File("$folder/${widget.imageName}");
      final res = await get(Uri.parse(widget.imageUrl));
      await file.writeAsBytes(res.bodyBytes);
      Fluttertoast.showToast(msg: "已儲存圖片");
    } catch (e) {
      if (!mounted) return;

      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text(
                "儲存圖片時發生錯誤",
                style: TextStyle(fontSize: 16),
              ),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text("確定"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      } else {
        context.scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("儲存圖片時發生錯誤：${e.toString()}"),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: SizedBox.expand(
              child: InteractiveViewer(
                maxScale: 10,
                transformationController: _controller,
                onInteractionUpdate: (details) {
                  if (_controller.value.getMaxScaleOnAxis() == 1.0) {
                    if (isUiHidden) {
                      setState(() => isUiHidden = false);
                    }
                  } else {
                    if (!isUiHidden) {
                      setState(() => isUiHidden = true);
                    }
                  }
                },
                onInteractionEnd: (details) {
                  if (details.pointerCount == 0 && Velocity.zero == details.velocity) {
                    if (isUiHidden) {
                      setState(() => isUiHidden = false);
                    } else {
                      setState(() => isUiHidden = true);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Hero(
                    tag: widget.heroTag,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      progressIndicatorBuilder: (context, url, progress) {
                        return Center(
                          child: CircularProgressIndicator(value: progress.progress),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isUiHidden ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: SafeArea(
              child: Stack(children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filled(
                    icon: const Icon(Symbols.close_rounded),
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(context.colors.onSurfaceVariant),
                      backgroundColor: WidgetStateProperty.all(context.colors.surfaceVariant.withOpacity(0.8)),
                    ),
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: TextButton.icon(
                    icon: isDownloading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Icon(Symbols.save_rounded),
                    label: const Text("儲存"),
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(context.colors.onSurfaceVariant),
                      backgroundColor: MaterialStateProperty.all(context.colors.surfaceVariant.withOpacity(0.8)),
                    ),
                    onPressed: isDownloading
                        ? null
                        : () async {
                            setState(() => isDownloading = true);
                            await saveImageToDownloads();
                            setState(() => isDownloading = false);
                          },
                  ),
                )
              ]),
            ),
          )
        ],
      ),
    );
  }
}
