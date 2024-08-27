import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class DPIPInfoPage extends StatelessWidget {
  const DPIPInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('開發者想說的話'),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 24),
            _buildInfoCard(
                context,
                '簡介',
                [
                  '首先感謝所有下載這個軟體的使用者,整個開發團隊在此獻上最誠摯的謝意。',
                  'DPIP 是一個以整合所有防災資訊為目標的軟體,希望能成為民眾生活中不可或缺的一部分。儘管目前完成度不高且困難重重,但我們仍會持續朝這個目標前進。',
                  '在開發軟體時,我們投入了大量的金錢、時間與精力,在人事成本、設備費用、雲端服務、網路費用等項目上,花費超過50萬新台幣。為此,我們希望獲得使用者的支持,在不依賴其他第三方公司的前提下,繼續維持營運。'
                ],
                Symbols.info_rounded),
            _buildInfoCard(
                context,
                '營利模式',
                [
                  '為了維持 App 的開發,團隊內部進行了多次激烈討論,思考如何才能營利？我們試圖在眾多方案中,找出一個適合的營利模式。我們發現,大多數同類型軟體採用植入廣告的方式來達到營利目的,這使得我們一度考慮採用該方式作為營利的方法。'
                ],
                Symbols.monetization_on_rounded),
            _buildInfoCard(
                context,
                '營利真的太難了',
                [
                  '我們調查了一般民眾的付費意願,發現大部分人普遍防災意識不足,更不會花錢在這件事情上。後台的數據能側面證實這個說法,據統計,熱心贊助的民眾大約是整體使用者的10萬分之1,這使得植入廣告似乎成為了最好的解決方法。'
                ],
                Symbols.trending_down_rounded),
            _buildInfoCard(
                context,
                '為什麼不採用廣告？',
                [
                  '當災害發生時,大家一定不會想要看廣告吧？這是我們不植入廣告的第一個理由。防災導向的軟體,快速正確地傳遞防災資訊是首要任務。如果因為廣告而導致無法正確掌握防災資訊,這反而和我們的理念相違背。況且,災害發生時通常通訊品質不佳,還要額外浪費網路流量在載入廣告,這件事太令人沮喪了。'
                ],
                Symbols.block_rounded),
            _buildInfoCard(
                context,
                '對大眾收費？',
                [
                  '如果植入廣告行不通,那對大眾收費呢？變成付費軟體？',
                  '首先,作為防災軟體,我們希望盡可能地將防災資訊傳遞給越多人越好。而且,或許真正需要的人沒辦法再多出額外的金費承擔這項支出,我們希望幫助更多的人。其次,作為開發人員,我們希望軟體可以有很多人使用,收費會直接導致大家使用意願降低。'
                ],
                Symbols.attach_money_rounded),
            _buildInfoCard(
                context, '如何營利？', ['總結上述,我們希望培養出對防災有興趣的人、重視防災的人,支持我們的軟體開發,一起往前發展。'], Symbols.lightbulb_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset(
              'assets/DPIP.png', // 替換為實際的 DPIP logo 資源路徑
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 16),
            Text(
              'DPIP 開發者的話',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '感謝您使用 DPIP，讓我們一起為防災盡一份心力',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<String> paragraphs, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...paragraphs
                .map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        paragraph,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
