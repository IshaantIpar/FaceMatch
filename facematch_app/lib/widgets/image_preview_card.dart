
import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewCard extends StatelessWidget {
  final String title;
  final File? image;
  final String emptyMessage;
  final VoidCallback? onTap;

  const ImagePreviewCard({
    super.key,
    required this.title,
    required this.image,
    required this.emptyMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Material(
            color: const Color(0xFF171D29),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: image == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_a_photo_outlined,
                              size: 32,
                              color: Color(0xFFB7C7FF),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              emptyMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Image.file(
                      image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Unable to display this image.'),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
