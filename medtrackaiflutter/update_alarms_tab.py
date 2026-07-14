import re

with open('lib/screens/alarms/alarms_tab.dart', 'r') as f:
    content = f.read()

# 1. Update the Padding around _AlarmCard
content = content.replace("padding: const EdgeInsets.only(bottom: 12),", "padding: EdgeInsets.zero,")

# 2. Add Cupertino to imports if missing
if "import 'package:flutter/cupertino.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/cupertino.dart';")

# 3. Replace _AlarmCard
new_alarm_card = """class _AlarmCard extends StatelessWidget {
  final ScheduledMed sch;
  final AppThemeColors L;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _AlarmCard({
    required this.sch,
    required this.L,
    required this.isNext,
    required this.onToggle,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final med = sch.med;
    final s = sch.sched;
    final isEnabled = s.enabled;
    
    // We parse the time to separate the H:MM from the AM/PM if possible.
    final timeString = fmtTime(s.h, s.m, context);
    final parts = timeString.split(' ');
    final mainTime = parts[0];
    final amPm = parts.length > 1 ? parts[1] : '';

    return Dismissible(
      key: Key('alarm_${med.id}_${sch.idx}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticEngine.heavyImpact();
        return true;
      },
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: CupertinoColors.destructiveRed,
        child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          mainTime,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.5,
                            color: isEnabled ? L.text : L.sub.withValues(alpha: 0.4),
                            height: 1.0,
                          ),
                        ),
                        if (amPm.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            amPm,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: isEnabled ? L.text : L.sub.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.name} • ${s.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isEnabled ? L.sub.withValues(alpha: 0.7) : L.sub.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isEnabled,
                activeColor: L.accent,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}"""

# Replace the old _AlarmCard with the new one
content = re.sub(
    r'class _AlarmCard extends StatelessWidget \{.*?\n\}\n(?=\nclass _StatusChip|\n//|\Z)',
    new_alarm_card + '\n',
    content,
    flags=re.DOTALL
)

with open('lib/screens/alarms/alarms_tab.dart', 'w') as f:
    f.write(content)

