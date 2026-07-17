import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../common/animated_pressable.dart';
import '../common/app_feedback.dart';

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
  MascotAccessory(
      id: 'crown', name: 'Royal Crown', emoji: '👑', cost: 500, isPremium: true),
  MascotAccessory(id: 'party', name: 'Party Hat', emoji: '🥳', cost: 200),
  MascotAccessory(id: 'wizard', name: 'Wizard Hat', emoji: '🧙‍♂️', cost: 350),
  MascotAccessory(
      id: 'halo', name: 'Angel Halo', emoji: '😇', cost: 1000, isPremium: true),
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
  final int _coins = 1250;
  final Set<String> _ownedItems = {'glasses'};
  String? _equippedItem;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
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
      setState(() {
        _equippedItem = _equippedItem == item.id ? null : item.id;
      });
      Provider.of<AppState>(context, listen: false)
          .setMascotAccessory(_equippedItem);
    } else if (_coins >= item.cost) {
      HapticEngine.success();
      setState(() {
        _ownedItems.add(item.id);
        _equippedItem = item.id;
      });
      Provider.of<AppState>(context, listen: false)
          .setMascotAccessory(_equippedItem);
      if (!MedAiA11y.reducedMotion(context)) {
        _confettiController.play();
      }
    } else {
      HapticEngine.error();
      AppFeedback.toast(
        context,
        'Not enough Med Coins! Keep building your streak.',
        type: 'error',
      );
    }
  }

  Widget _entrance(Widget child, int index) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.squircle)),
          child: MedAiGlass(
            radius: AppRadius.squircle,
            showBorder: false,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Sheet handle',
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: L.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
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
                        ),
                        MedAiGlass(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          radius: AppRadius.xl,
                          child: Row(
                            children: [
                              const Text('🟡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                _coins.toString(),
                                style: AppTypography.titleMedium.copyWith(
                                  color: L.amber,
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
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _availableAccessories.length,
                      itemBuilder: (context, index) {
                        final item = _availableAccessories[index];
                        return _entrance(
                          _AccessoryCard(
                            item: item,
                            isOwned: _ownedItems.contains(item.id),
                            isEquipped: _equippedItem == item.id,
                            onTap: () => _handlePurchaseOrEquip(item),
                            L: L,
                          ),
                          index,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!reduceMotion)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              L.green,
              L.accent,
              L.purple,
              L.amber,
              L.error,
            ],
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
    return Semantics(
      button: true,
      label: '${item.name}${isEquipped ? ', equipped' : isOwned ? ', owned' : ', costs ${item.cost} coins'}',
      selected: isEquipped,
      child: AnimatedPressable(
        onTap: onTap,
        child: MedAiDepthCard(
          padding: const EdgeInsets.all(16),
          radius: AppRadius.xl,
          accentGlow: isEquipped,
          color: isEquipped ? L.accent.withValues(alpha: 0.08) : L.card,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: L.bg,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (isEquipped)
                MedAiGlass(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  radius: AppRadius.xl,
                  tint: L.accent,
                  child: Text(
                    'EQUIPPED',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.bg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else if (isOwned)
                Text(
                  'OWNED',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w900,
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
                        color: L.amber,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
