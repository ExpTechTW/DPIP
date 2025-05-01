import "package:flutter/material.dart";

import "package:dpip/utils/extensions/build_context.dart";

class UpdateCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onViewDetails;

  const UpdateCard({super.key, required this.title, required this.description, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.theme.primaryColor.withOpacity(0.1), context.theme.primaryColor.withOpacity(0.3)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.new_releases, size: 28, color: context.theme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: context.theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.update, size: 48, color: Colors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
