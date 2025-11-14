import 'dart:io';

import 'package:dpip/utils/toast.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';
import 'package:gal/gal.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';

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
        if (androidInfo.version.sdkInt <= 28) {
          status = await Permission.storage.request();
        } else {
          status = PermissionStatus.granted;
        }
      } else {
        status = await Permission.photosAddOnly.request();
      }

      if (!mounted) return;

      if (status.isDenied || status.isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: const Icon(Symbols.error),
              title: Text('無法取得權限'.i18n),
              content: Text(
                "儲存圖片需要您允許 DPIP 使用相片和媒體權限才能正常運作。${status.isPermanentlyDenied ? '請您到應用程式設定中找到並允許「相片和媒體」權限後再試一次。'.i18n : ""}",
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  child: Text('取消'.i18n),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FilledButton(
                  child: Text(status.isPermanentlyDenied ? '設定'.i18n : '再試一次'.i18n),
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

      // 保存图片到临时目录
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.imageName}');
      await tempFile.writeAsBytes(res.bodyBytes);

      try {
        // 保存到相册
        if (Platform.isAndroid) {
          await Gal.putImage(tempFile.path, album: 'DPIP');
        } else {
          await Permission.photosAddOnly.request();
          try {
            await Gal.putImage(tempFile.path);
          } catch (_) {
            final upgrade = await Permission.photos.request();
            if (upgrade.isGranted) {
              await Gal.putImage(tempFile.path, album: 'DPIP');
            }
          }
        }
        showToast(context, ToastWidget.text('已儲存圖片'.i18n, icon: const Icon(Symbols.check_rounded)));
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (Platform.isIOS) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: const Icon(Symbols.error),
              title: Text('儲存圖片時發生錯誤'.i18n),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  child: Text('確定'.i18n),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      } else {
        context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('儲存圖片時發生錯誤: $e'.i18n)));
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
                        return Center(child: CircularProgressIndicator(value: progress.progress));
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
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton.filled(
                      icon: const Icon(Symbols.close_rounded),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(context.colors.onSurfaceVariant),
                        backgroundColor: WidgetStateProperty.all(
                          context.colors.surfaceContainerHighest.withValues(alpha: 0.8),
                        ),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Symbols.save_rounded),
                      label: Text('儲存'.i18n),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
