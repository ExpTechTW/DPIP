import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";

import "note.dart";

class ExpTechAboutPage extends StatelessWidget {
  const ExpTechAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/ExpTech.jpg", width: 120, height: 120),
                        const SizedBox(height: 32),
                        Text(
                          "ExpTech Studio",
                          style: context.theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.theme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "©2024 ExpTech Studio Ltd.",
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.theme.primaryColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.i18n.who_we_are,
                                  style: context.theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.i18n.exptech_studio_description,
                                  style: context.theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.i18n.our_mission,
                                  style: context.theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.i18n.founding_mission,
                                  style: context.theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("下一步"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
