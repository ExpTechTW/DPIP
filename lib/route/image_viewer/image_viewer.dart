import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:device_info_plus/device_info_plus.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:http/http.dart";
import "package:image_gallery_saver/image_gallery_saver.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:permission_handler/permission_handler.dart";

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
      PermissionStatus status;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          status = await Permission.storage.request();
        } else {
          status = await Permission.photos.request();
        }
      } else {
        status = await Permission.photos.request();
      }

      if (!mounted) return;

      if (status.isDenied || status.isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: const Icon(Symbols.error),
              title: Text(context.i18n.unable_to_obtain_permission),
              content: Text(
                "儲存圖片需要您允許 DPIP 使用相片和媒體權限才能正常運作。${status.isPermanentlyDenied ? "請您到應用程式設定中找到並允許「相片和媒體」權限後再試一次。" : ""}",
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  child: Text(context.i18n.cancel),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FilledButton(
                  child: Text(status.isPermanentlyDenied ? context.i18n.settings : context.i18n.again),
                  onPressed: () {
                    if (status.isPermanentlyDenied) {
                      openAppSettings();
                    } else {
                      saveImageToDownloads();
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      final res = await get(Uri.parse(widget.imageUrl));

      final result = await ImageGallerySaver.saveImage(
        res.bodyBytes,
        quality: 100,
        name: widget.imageName,
      );

      if (!mounted) return;

      if (!result["isSuccess"]) {
        throw Exception(result["errorMessage"]);
      }

      Fluttertoast.showToast(msg: context.i18n.image_saved);
    } catch (e) {
      if (!mounted) return;

      if (Platform.isIOS) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: const Icon(Symbols.error),
              title: Text(context.i18n.error_saving_image),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  child: Text(context.i18n.confirm),
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
                      backgroundColor: WidgetStateProperty.all(context.colors.surfaceContainerHighest.withOpacity(0.8)),
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
                    label: Text(context.i18n.image_save),
                    style: ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(context.colors.onSurfaceVariant),
                      backgroundColor: WidgetStatePropertyAll(context.colors.surfaceContainerHighest),
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
