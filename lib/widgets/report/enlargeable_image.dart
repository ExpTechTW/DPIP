import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpip/route/image_viewer/image_viewer.dart';
import 'package:flutter/material.dart';

class EnlargeableImage extends StatelessWidget {
  final double aspectRatio;
  final String heroTag;
  final String imageUrl;
  final String imageName;

  const EnlargeableImage({
    super.key,
    required this.aspectRatio,
    required this.heroTag,
    required this.imageUrl,
    required this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Hero(tag: heroTag, child: CachedNetworkImage(imageUrl: imageUrl)),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ImageViewerRoute(heroTag: heroTag, imageUrl: imageUrl, imageName: imageName);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
