import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class ZakatScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const ZakatScreen({super.key, required this.onNavigate});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  // Controller for assets
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _investmentController = TextEditingController();
  final _debtsController = TextEditingController();

  double _totalAssets = 0;
  double _totalZakat = 0;

  // Real-world NISAB constants (can be made dynamic later)
  final double _goldNisabGrams = 85.0;
  final double _silverNisabGrams = 595.0;

  // Mock prices for demo (should ideally come from an API)
  final double _goldPricePerGram = 75.0; // Example
  final double _silverPricePerGram = 1.0; // Example

  @override
  void initState() {
    super.initState();
    _cashController.addListener(_calculate);
    _goldController.addListener(_calculate);
    _silverController.addListener(_calculate);
    _investmentController.addListener(_calculate);
    _debtsController.addListener(_calculate);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _investmentController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!mounted) return;

    double cash = double.tryParse(_cashController.text) ?? 0;
    double goldVal =
        (double.tryParse(_goldController.text) ?? 0) * _goldPricePerGram;
    double silverVal =
        (double.tryParse(_silverController.text) ?? 0) * _silverPricePerGram;
    double investments = double.tryParse(_investmentController.text) ?? 0;
    double debts = double.tryParse(_debtsController.text) ?? 0;

    double total = cash + goldVal + silverVal + investments;
    double net = total - debts;

    // Standard Zakat 2.5%
    double zakatLimit = _goldNisabGrams * _goldPricePerGram;

    setState(() {
      _totalAssets = net > 0 ? net : 0;
      _totalZakat = _totalAssets >= zakatLimit ? _totalAssets * 0.025 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isNisabReached = _totalZakat > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(theme, isNisabReached),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Cash & Liquidity',
                    'Al-Naghdayn',
                    Icons.payments_rounded,
                    'Zakat is obligatory on accumulated wealth. Sahih Bukhari: "Take from their wealth as Sadaqah (Zakat) to be given to the poor."',
                  ),
                  _buildInputField(
                    _cashController,
                    'Total Savings (Cash/Bank)',
                    Icons.account_balance_rounded,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Precious Metals',
                    'Al-Dhahab wa al-Fiddah',
                    Icons.diamond_rounded,
                    'Gold Nisab is 85g and Silver is 595g. If you own less, no Zakat is due on that specific metal unless the total wealth exceeds Nisab. (Sahih Muslim).',
                  ),
                  _buildInputField(
                    _goldController,
                    'Gold Weight (Grams)',
                    Icons.auto_awesome_rounded,
                  ),
                  _buildInputField(
                    _silverController,
                    'Silver Weight (Grams)',
                    Icons.blur_on_rounded,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Investments',
                    'Uruz al-Tijarah',
                    Icons.trending_up_rounded,
                    'Zakat is due on trade goods intended for sale. (Quran 2:267: "O you who believe! Spend of the good things which you have (legally) earned").',
                  ),
                  _buildInputField(
                    _investmentController,
                    'Business Assets / Stocks',
                    Icons.storefront_rounded,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Liabilities',
                    'Al-Duyun',
                    Icons.remove_circle_outline_rounded,
                    'Debts and immediate liabilities are subtracted from total assets as Zakat is only due on wealth exceeding one\'s basic needs.',
                    isNegative: true,
                  ),
                  _buildInputField(
                    _debtsController,
                    'Money You Owe (Debts)',
                    Icons.receipt_long_rounded,
                  ),

                  const SizedBox(height: 40),
                  _buildEvidenceSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeProvider theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.text,
          size: 20,
        ),
        onPressed: () => widget.onNavigate('more'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: const Text(
          'Zakat & Wealth',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeProvider theme, bool isNisabReached) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: theme.activeGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.dynamicFloating(theme.primaryColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zakat Due',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isNisabReached ? 'Nisab Reached' : 'Below Nisab',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              '\$${_totalZakat.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculated at 2.5% of net wealth',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEvidence(String title, String evidence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          evidence,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String arabic,
    IconData icon,
    String evidence, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isNegative ? Colors.redAccent : AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  arabic,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppTheme.textMuted,
            ),
            onPressed: () => _showEvidence(title, evidence),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Scriptural Evidence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '"And perform Salât and give Zakat, and whatever of good you send forth for yourselves before you, you shall find it with Allah. Certainly, Allah is All-Seer of what you do."',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '— Quran, Al-Baqarah 2:110',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const Divider(height: 32),
          const Text(
            '"The Prophet (peace be upon him) said: One-fortieth (2.5%) is to be taken from their wealth as Zakat."',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '— Sahih Bukhari',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
