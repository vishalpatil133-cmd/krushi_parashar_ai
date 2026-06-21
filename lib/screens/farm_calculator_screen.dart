import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/translation_service.dart';
import '../main.dart';

class FarmCalculatorScreen extends StatefulWidget {
  const FarmCalculatorScreen({super.key});

  @override
  State<FarmCalculatorScreen> createState() => _FarmCalculatorScreenState();
}

class _FarmCalculatorScreenState extends State<FarmCalculatorScreen> {
  final _seedController = TextEditingController();
  final _fertPestController = TextEditingController();
  final _laborController = TextEditingController();
  final _ploughController = TextEditingController();
  final _waterController = TextEditingController();
  final _otherController = TextEditingController();
  
  final _yieldController = TextEditingController();
  final _priceController = TextEditingController();

  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;
  double _netResult = 0.0;

  @override
  void initState() {
    super.initState();
    // Add listeners to calculate in real-time
    _seedController.addListener(_calculate);
    _fertPestController.addListener(_calculate);
    _laborController.addListener(_calculate);
    _ploughController.addListener(_calculate);
    _waterController.addListener(_calculate);
    _otherController.addListener(_calculate);
    _yieldController.addListener(_calculate);
    _priceController.addListener(_calculate);
  }

  @override
  void dispose() {
    _seedController.dispose();
    _fertPestController.dispose();
    _laborController.dispose();
    _ploughController.dispose();
    _waterController.dispose();
    _otherController.dispose();
    _yieldController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final seed = double.tryParse(_seedController.text) ?? 0.0;
    final fert = double.tryParse(_fertPestController.text) ?? 0.0;
    final labor = double.tryParse(_laborController.text) ?? 0.0;
    final plough = double.tryParse(_ploughController.text) ?? 0.0;
    final water = double.tryParse(_waterController.text) ?? 0.0;
    final other = double.tryParse(_otherController.text) ?? 0.0;

    final yieldVal = double.tryParse(_yieldController.text) ?? 0.0;
    final priceVal = double.tryParse(_priceController.text) ?? 0.0;

    setState(() {
      _totalExpenses = seed + fert + labor + plough + water + other;
      _totalIncome = yieldVal * priceVal;
      _netResult = _totalIncome - _totalExpenses;
    });
  }

  void _clearAll() {
    _seedController.clear();
    _fertPestController.clear();
    _laborController.clear();
    _ploughController.clear();
    _waterController.clear();
    _otherController.clear();
    _yieldController.clear();
    _priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softBg = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: Text(
          tr('farm_calculator_card_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: tr('calc_clear'),
            onPressed: _clearAll,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EXPENSE SECTION CARD
              Card(
                color: cardColor,
                elevation: 0,
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
                          const Icon(Icons.trending_down, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            MyApp.selectedLanguage.value == 'en' ? 'Farming Expenses' : 'शेतीवरील खर्च (Expenses)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInputField(_seedController, tr('calc_seed_cost'), Icons.eco),
                      _buildInputField(_fertPestController, tr('calc_fert_pest_cost'), Icons.science),
                      _buildInputField(_laborController, tr('calc_labor_cost'), Icons.people),
                      _buildInputField(_ploughController, tr('calc_plough_cost'), Icons.agriculture),
                      _buildInputField(_waterController, tr('calc_water_cost'), Icons.water),
                      _buildInputField(_otherController, tr('calc_other_cost'), Icons.more_horiz),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // RETURNS SECTION CARD
              Card(
                color: cardColor,
                elevation: 0,
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
                          const Icon(Icons.trending_up, color: primaryGreen, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            MyApp.selectedLanguage.value == 'en' ? 'Expected Returns' : 'अपेक्षित उत्पन्न (Returns)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInputField(_yieldController, tr('calc_yield'), Icons.shopping_basket),
                      _buildInputField(_priceController, tr('calc_price'), Icons.sell),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // RESULTS SUMMARY CARD
              _buildResultCard(primaryGreen, accentGold, currencyFormatter),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    const primaryGreen = Color(0xFF1E5631);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen.withOpacity(0.7)),
          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildResultCard(Color primaryGreen, Color accentGold, NumberFormat currencyFormatter) {
    final hasInput = _totalExpenses > 0 || _totalIncome > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (!hasInput) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Center(
          child: Text(
            MyApp.selectedLanguage.value == 'en'
                ? 'Enter details above to see the calculation summary'
                : 'हिशोबाचा गोषवारा पाहण्यासाठी वरती माहिती भरा',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final isProfit = _netResult >= 0;
    final cardColor = isProfit 
        ? (isDark ? const Color(0xFF1B5E20).withOpacity(0.2) : const Color(0xFFE8F5E9)) 
        : (isDark ? const Color(0xFFB71C1C).withOpacity(0.2) : const Color(0xFFFFEBEE));
    final borderColor = isProfit ? Colors.green[400]! : Colors.red[300]!;
    final resultColor = isProfit ? (isDark ? Colors.green[300]! : Colors.green[800]!) : (isDark ? Colors.red[300]! : Colors.red[800]!);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('calc_result_header'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
          const Divider(height: 20, color: Colors.black12),
          _buildResultRow(tr('calc_total_expense'), currencyFormatter.format(_totalExpenses), isDark ? Colors.white70 : Colors.black87),
          const SizedBox(height: 8),
          _buildResultRow(tr('calc_total_income'), currencyFormatter.format(_totalIncome), isDark ? Colors.white70 : Colors.black87),
          const Divider(height: 20, color: Colors.black12),
          _buildResultRow(
            isProfit ? tr('calc_net_profit') : tr('calc_net_loss'),
            currencyFormatter.format(_netResult.abs()),
            resultColor,
            isBold: true,
            fontSize: 16,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isProfit ? Icons.check_circle : Icons.warning,
                color: resultColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isProfit ? tr('calc_profit_msg') : tr('calc_loss_msg'),
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color, {bool isBold = false, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
