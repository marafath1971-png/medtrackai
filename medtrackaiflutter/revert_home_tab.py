import re

with open('lib/screens/home/home_tab.dart', 'r') as f:
    content = f.read()

# 1. Remove DuolingoPathFeed import
content = content.replace("import 'widgets/duolingo_path_feed.dart';\n", "")

# 2. Add HomeDoseGroup import if missing (it might be missing if we removed it earlier, wait, it's actually in widgets/home_meds_section.dart or widgets/dose_group.dart? Let's check imports.)

# Wait, the previous version had:
# import 'widgets/home_meds_section.dart'; (which contains HomeDoseGroup probably?)
# Let's replace the Duolingo block with the old block.
# I saved the old block in the python script from earlier!

to_replace_start = "                  // ── SHARE CTA ──"
to_replace_end = "                  // ── MEDICINE CABINET SECTION HEADER ──"

regex = re.compile(re.escape(to_replace_start) + r".*?" + re.escape(to_replace_end), re.DOTALL)

replacement = """                  // ── SHARE CTA ──
                  if (streak >= 7)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: _ShareMilestoneCardCTA(
                          streak: streak,
                          dosePct: dosePct,
                          userName: context.select<AppState, String>((s) => s.activeProfile?.name ?? s.profile?.name ?? ''),
                          totalDosesTaken: takenCount,
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 300.ms)
                            .slideX(begin: 0.1, end: 0),
                      ),
                    ),

                  // ── DAILY SCHEDULE SECTION HEADER ──
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'DAILY SCHEDULE',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.8),
                                fontSize: 11,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── DAILY SCHEDULE GROUPS LIST ──
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = groups[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: HomeDoseGroup(
                                title: group.title,
                                doses: group.items,
                                takenToday: takenMap,
                                state: context.read<AppState>(),
                                selectedDate: _selectedDate,
                                onView: (med) => setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = false;
                                }),
                                onEdit: (med) => setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = true;
                                }),
                                onTakeDose: () {
                                  // HapticEngine.success() or similar can go here
                                },
                              ),
                            );
                          },
                          childCount: groups.length,
                        ),
                      ),
                    ),

                  // ── MEDICINE CABINET SECTION HEADER ──"""

content = regex.sub(replacement, content)

with open('lib/screens/home/home_tab.dart', 'w') as f:
    f.write(content)

