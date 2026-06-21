import 'package:flutter/material.dart';
import '../models/prediction.dart';
import 'tts_button.dart';

class PredictionResultScreen extends StatelessWidget {
  final PredictionModel prediction;

  const PredictionResultScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAF7),
        appBar: AppBar(
          title: const Text(
            'वैदिक सल्ला',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: primaryGreen,
          elevation: 0,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: accentGold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentGold,
            indicatorWeight: 3.5,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.wb_sunny_outlined),
                text: 'अल्पकालीन (३-दिवस)',
              ),
              Tab(
                icon: Icon(Icons.spa_outlined),
                text: 'वैदिक (३-महिने)',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // WEATHER METRICS BAR
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildParamInfo(
                    icon: Icons.thermostat,
                    label: 'तापमान',
                    value: prediction.liveTemp,
                    color: Colors.orangeAccent,
                  ),
                  _buildParamInfo(
                    icon: Icons.water_drop_outlined,
                    label: 'आद्रता',
                    value: prediction.liveHumidity ?? 'N/A',
                    color: Colors.blueAccent,
                  ),
                  _buildParamInfo(
                    icon: Icons.air,
                    label: 'वाऱ्याचा वेग',
                    value: prediction.liveWindSpeed ?? 'N/A',
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEAEAEA)),
            
            // TAB VIEW
            Expanded(
              child: TabBarView(
                children: [
                  _buildForecastContent(
                    context,
                    title: 'अल्पकालीन हवामान अंदाज',
                    subtitle: '३ दिवसांचे हवामान आणि शेतीचे नियोजन',
                    content: prediction.shortTermForecast,
                    icon: Icons.wb_sunny_rounded,
                    headerColor: primaryGreen,
                  ),
                  _buildForecastContent(
                    context,
                    title: 'कृषि पराशर अंदाज',
                    subtitle: '३ महिन्यांचे वैदिक नियोजन आणि विधी',
                    content: prediction.vedicLongTermForecast,
                    icon: Icons.spa_rounded,
                    headerColor: accentGold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
        ),
      ],
    );
  }

  Widget _buildForecastContent(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String content,
    required IconData icon,
    required Color headerColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: headerColor.withOpacity(0.2), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: headerColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: headerColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: headerColor == const Color(0xFFE5A93B)
                                    ? const Color(0xFF1E5631)
                                    : headerColor,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TtsButton(text: content, color: headerColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEAEAEA)),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Opacity(
                      opacity: 0.25,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.eco,
                            size: 18,
                            color: Color(0xFF1E5631),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 1.5,
                            width: 60,
                            color: const Color(0xFF1E5631),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E5631), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'मुख्य स्क्रीनवर जा',
                style: TextStyle(
                  color: Color(0xFF1E5631),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
