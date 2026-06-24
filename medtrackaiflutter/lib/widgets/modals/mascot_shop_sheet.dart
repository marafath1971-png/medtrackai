import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../shared/shared_widgets.dart';
import '../../providers/app_state.dart';
import 'package:confetti/confetti.dart';

class MascotAccessory {
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final bool isPremium;

  const MascotAccessory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    this.isPremium = false,
  });
}

const List<MascotAccessory> _availableAccessories = [
  MascotAccessory(id: 'glasses', name: 'Cool Shades', emoji: '🕶️', cost: 150),
  MascotAccessory(id: 'crown', name: 'Royal Crown', emoji: '👑', cost: 500, isPremium: true),
  MascotAccessory(id: 'party', name: 'Party Hat', emoji: '🥳', cost: 200),
  MascotAccessory(id: 'wizard', name: 'Wizard Hat', emoji: '🧙‍♂️', cost: 350),
  MascotAccessory(id: 'halo', name: 'Angel Halo', emoji: '😇', cost: 1000, isPremium: true),
  MascotAccessory(id: 'nerd', name: 'Smart Glasses', emoji: '🤓', cost: 100),
];

class MascotShopSheet extends StatefulWidget {
  const MascotShopSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticEngine.selection();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MascotShopSheet(),
    );
  }

  @override
  State<MascotShopSheet> createState() => _MascotShopSheetState();
}

class _MascotShopSheetState extends State<MascotShopSheet> {
  // Using dummy coins and ownership for the demo
  final int _coins = 1250;
  final Set<String> _ownedItems = {'glasses'};
  String? _equippedItem; // Could be tracked in AppState if real
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _equippedItem = 'glasses';
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handlePurchaseOrEquip(MascotAccessory item) {
    HapticEngine.selection();
    
    if (_ownedItems.contains(item.id)) {
      // Equip or unequip
      setState(() {
        if (_equippedItem == item.id) {
          _equippedItem = null;
        } else {
          _equippedItem = item.id;
        }
      });
      // In a real app, update AppState
      Provider.of<AppState>(context, listen: false).setMascotAccessory(_equippedItem);
    } else {
      if (_coins >= item.cost) {
        // Mock purchase
        HapticEngine.success();
        setState(() {
          _ownedItems.add(item.id);
          _equippedItem = item.id;
        });
        Provider.of<AppState>(context, listen: false).setMascotAccessory(_equippedItem);
        _confettiController.play();
      } else {
        HapticEngine.error();
        // Show not enough coins message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough Med Coins! Keep building your streak.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: L.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: L.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mascot Wardrobe',
                          style: AppTypography.headlineMedium.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Customize your AI buddy',
                          style: AppTypography.bodyMedium.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Coins Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Text('🟡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            _coins.toString(),
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _availableAccessories.length,
                  itemBuilder: (context, index) {
                    final item = _availableAccessories[index];
                    final isOwned = _ownedItems.contains(item.id);
                    final isEquipped = _equippedItem == item.id;

                    return _AccessoryCard(
                      item: item,
                      isOwned: isOwned,
                      isEquipped: isEquipped,
                      onTap: () => _handlePurchaseOrEquip(item),
                      L: L,
                    ).animate(delay: (50 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Confetti effect
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.05,
          shouldLoop: false,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ],
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  final MascotAccessory item;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _AccessoryCard({
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isEquipped ? L.primary.withValues(alpha: 0.1) : L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEquipped ? L.primary : (isOwned ? L.border.withValues(alpha: 0.2) : L.border.withValues(alpha: 0.1)),
            width: isEquipped ? 2 : 1,
          ),
          boxShadow: isEquipped ? [
            BoxShadow(color: L.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))
          ] : AppShadows.neumorphic,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji Display
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: L.bg,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              item.name,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Price / Status
            if (isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: L.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'EQUIPPED',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else if (isOwned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'OWNED',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🟡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    item.cost.toString(),
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
