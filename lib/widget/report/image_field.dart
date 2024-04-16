import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/view/image_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImageField extends StatelessWidget {
  final String title;
  final String heroTag;
  final double aspectRatio;
  final String imageUrl;
  final String imageName;

  const ImageField({
    super.key,
    required this.title,
    required this.heroTag,
    required this.aspectRatio,
    required this.imageUrl,
    required this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      imageBuilder: (context, imageProvider) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: imageProvider,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return ImageViewer(
                                heroTag: heroTag,
                                imageUrl: imageUrl,
                                imageName: imageName,
                              );
                            },
                          ));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
