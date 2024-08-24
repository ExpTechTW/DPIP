import 'package:dpip/route/welcome/exptech.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                        Image.asset('assets/DPIP.png', width: 120, height: 120),
                        const SizedBox(height: 32),
                        Text(
                          '歡迎使用 DPIP',
                          style: context.theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.theme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Disaster Prevention Information Platform',
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.theme.primaryColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '防災資訊平台',
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
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'DPIP 是一款由臺灣本土團隊設計的 App，整合 TREM-Net (臺灣即時地震觀測網) 之資訊，以及中央氣象署資料，提供一個整合、單一且便利的防災資訊應用程式。',
                              style: context.theme.textTheme.bodyMedium,
                              textAlign: TextAlign.left,
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
                      MaterialPageRoute(builder: (context) => const ExpTechAboutPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('下一步'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
