import 'package:flutter/material.dart';
import 'pest_advisor_screen.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final DiseaseModel disease;

  const DiseaseDetailScreen({
    super.key,
    required this.disease,
  });

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final primaryGreen = const Color(0xFF1E5631);
  final accentGold = const Color(0xFFE5A93B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disease = widget.disease;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: Text(
          disease.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Disease Photo Header
            if (disease.photoUrl.isNotEmpty)
              Image.network(
                disease.photoUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey[400],
                        size: 64,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                      ),
                    ),
                  );
                },
              ),

            // Basic Info Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'पीक: ${disease.crop}',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    disease.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),

            // Custom Tab Selector (सेंद्रिय vs रासायनिक)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: '🍀 सेंद्रिय उपाय'),
                  Tab(text: '🧪 रासायनिक उपाय'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Content
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  return IndexedStack(
                    index: _tabController.index,
                    children: [
                      // Tab 1: Organic Remedy
                      _buildOrganicTab(disease),
                      
                      // Tab 2: Chemical Remedy
                      _buildChemicalTab(disease),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicTab(DiseaseModel disease) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symptoms
        _buildInfoCard(
          title: 'लक्षणे (Symptoms):',
          content: disease.symptoms,
          icon: Icons.remove_red_eye_outlined,
          color: Colors.red[700]!,
        ),
        const SizedBox(height: 12),

        // Organic Remedy
        _buildInfoCard(
          title: 'सेंद्रिय उपाय (Organic Remedy):',
          content: disease.organicRemedy,
          icon: Icons.eco_outlined,
          color: primaryGreen,
        ),
        const SizedBox(height: 12),

        // Recipe Card
        if (disease.recipe.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50]!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.amber[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'कसे तयार करावे व फवारणी पद्धत:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  disease.recipe,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey[850],
                  ),
                ),
              ],
            ),
          ),

        // Vedic Quote
        if (disease.vedicQuote.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryGreen.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, color: accentGold, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disease.vedicQuote,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5,
                      color: primaryGreen,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChemicalTab(DiseaseModel disease) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symptoms
        _buildInfoCard(
          title: 'लक्षणे (Symptoms):',
          content: disease.symptoms,
          icon: Icons.remove_red_eye_outlined,
          color: Colors.red[700]!,
        ),
        const SizedBox(height: 12),

        // Chemical Remedy
        _buildInfoCard(
          title: 'रासायनिक उपाय (Chemical Remedy):',
          content: disease.chemicalRemedy,
          icon: Icons.science_outlined,
          color: Colors.blue[800]!,
        ),
        const SizedBox(height: 16),

        // Safety Caution Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50]!.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[100]!.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[800], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'सुरक्षितता व सावधगिरी (Caution):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '१. रासायनिक कीटकनाशके फवारताना तोंडावर मास्क आणि हातामध्ये रबरी हातमोजे नक्की वापरा.\n'
                '२. फवारणी करताना वारे वाहत असलेल्या दिशेने फवारणी करा (वाऱ्याच्या विरुद्ध दिशेने नको).\n'
                '३. रिकाम्या डब्या किंवा पाकिटे जमिनीत खोल पुरून टाका.\n'
                '४. हे औषध लहान मुले आणि पाळीव प्राण्यांच्या संपर्कापासून दूर ठेवा.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: Colors.red[950],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.grey[850],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
