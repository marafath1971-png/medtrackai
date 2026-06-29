import re

with open('lib/screens/home/home_tab.dart', 'r') as f:
    content = f.read()

# 1. Add import for DuolingoPathFeed
if "import 'widgets/duolingo_path_feed.dart';" not in content:
    content = content.replace("import 'widgets/home_mascot_card.dart';", "import 'widgets/home_mascot_card.dart';\nimport 'widgets/duolingo_path_feed.dart';")

# 2. Modify MeshGradient
mesh_gradient_old = """                  L.accent.withValues(alpha: 0.6),
                  L.purple.withValues(alpha: 0.6),
                  L.bg,
                  Colors.blue.withValues(alpha: 0.6),"""
mesh_gradient_new = """                  L.bg,
                  L.bg,
                  L.bg,
                  L.accent.withValues(alpha: 0.1),"""
content = content.replace(mesh_gradient_old, mesh_gradient_new)

# 3. Add globalNextEntryKey to _buildMainDashboard
build_main_dashboard_start = """    final activeCourses = meds.where((m) => m.isCourseActive).toList();

    // Pre-calculate time groups for timeline to avoid redundant computations and ensure correct childCount
    final groups = ["""

build_main_dashboard_new = """    final activeCourses = meds.where((m) => m.isCourseActive).toList();
    
    String? globalNextEntryKey;
    for (final d in doses) {
      if (takenMap[d.key] != true) {
        globalNextEntryKey = d.key;
        break;
      }
    }

    // Pre-calculate time groups for timeline to avoid redundant computations and ensure correct childCount
    final groups = ["""
content = content.replace(build_main_dashboard_start, build_main_dashboard_new)

# 4. Remove HomeMascotCard, _NextDoseCarousel, DAILY SCHEDULE header, and HomeDoseGroup list
# Replace with DuolingoPathFeed

to_replace_start = "                  SliverPadding(\n                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),\n                    sliver: SliverToBoxAdapter(\n                      child: const HomeMascotCard()"
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

                  // ── DUOLINGO STYLE WINDING PATH ──
                  if (doses.isNotEmpty)
                    DuolingoPathFeed(
                      doses: doses,
                      takenMap: takenMap,
                      globalNextEntryKey: globalNextEntryKey,
                      state: context.read<AppState>(),
                      selectedDate: _selectedDate,
                      onView: (med) => setState(() {
                        _viewingMed = med;
                        _startInEditMode = false;
                      }),
                      onTakeDose: () {
                        // handled inside node
                      },
                    ),

                  // ── MEDICINE CABINET SECTION HEADER ──"""

# Note: streak >= 7 is already above HomeMascotCard or below it?
# Let's just remove the old streak >= 7 block to avoid duplicates if it was already there.
streak_block = """                  if (streak >= 7)
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
                    ),"""
content = content.replace(streak_block, "")

content = regex.sub(replacement, content)


with open('lib/screens/home/home_tab.dart', 'w') as f:
    f.write(content)

