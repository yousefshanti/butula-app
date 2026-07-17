import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

/// Result of the picker: either an emoji or a Material icon.
class IconChoice {
  const IconChoice({this.emoji, this.iconCodePoint});
  final String? emoji;
  final int? iconCodePoint;
}

/// A curated set of Material icons users can pick for a habit.
const habitMaterialIcons = <IconData>[
  Icons.self_improvement,
  Icons.menu_book,
  Icons.mosque,
  Icons.fitness_center,
  Icons.directions_run,
  Icons.water_drop,
  Icons.bedtime,
  Icons.wb_sunny,
  Icons.work,
  Icons.school,
  Icons.laptop_mac,
  Icons.brush,
  Icons.edit_note,
  Icons.favorite,
  Icons.volunteer_activism,
  Icons.cleaning_services,
  Icons.local_florist,
  Icons.nightlight_round,
  Icons.phone_disabled,
  Icons.emoji_events,
  Icons.spa,
  Icons.hiking,
  Icons.pedal_bike,
  Icons.restaurant,
  Icons.local_drink,
  Icons.medication,
  Icons.savings,
  Icons.shield,
  Icons.check_circle,
  Icons.star,
];

Future<IconChoice?> showIconPicker(BuildContext context) {
  return showModalBottomSheet<IconChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _PickerSheet(),
  );
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'إيموجي', icon: Icon(Icons.emoji_emotions_outlined)),
                Tab(text: 'أيقونات', icon: Icon(Icons.category_outlined)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      Navigator.of(context).pop(IconChoice(emoji: emoji.emoji));
                    },
                    config: Config(
                      height: double.infinity,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: const EmojiViewConfig(
                        emojiSizeMax: 28,
                      ),
                      categoryViewConfig: const CategoryViewConfig(
                        indicatorColor: Color(0xFF1A472A),
                        iconColorSelected: Color(0xFF1A472A),
                      ),
                      bottomActionBarConfig:
                          const BottomActionBarConfig(enabled: false),
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: habitMaterialIcons.length,
                    itemBuilder: (context, i) {
                      final icon = habitMaterialIcons[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(
                          IconChoice(iconCodePoint: icon.codePoint),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 28),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a habit's icon (emoji or Material icon) at a given size.
/// Material icons are looked up from the const [habitMaterialIcons] list so
/// icon font tree-shaking keeps working in release builds.
Widget habitIcon(String emoji, int? iconCodePoint, {double size = 24}) {
  if (iconCodePoint != null) {
    final icon = habitMaterialIcons.firstWhere(
      (i) => i.codePoint == iconCodePoint,
      orElse: () => Icons.star,
    );
    return Icon(icon, size: size);
  }
  return Text(emoji, style: TextStyle(fontSize: size));
}
