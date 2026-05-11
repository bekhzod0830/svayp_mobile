import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';

/// Telegram-style emoji picker panel that appears above the input bar.
/// Fully functional: tapping an emoji inserts it at the cursor position.
class ChatEmojiPanel extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClose;

  const ChatEmojiPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel> {
  // Category: (tab emoji icon, display name, emoji list)
  static const _categories = [
    (icon: '😊', name: 'Smileys'),
    (icon: '👋', name: 'Gestures'),
    (icon: '🐶', name: 'Animals'),
    (icon: '🍎', name: 'Food'),
    (icon: '✈️', name: 'Travel'),
    (icon: '⚽', name: 'Sports'),
    (icon: '💡', name: 'Objects'),
    (icon: '❤️', name: 'Symbols'),
  ];

  static const _emojisByCategory = <String, List<String>>{
    'Smileys': [
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉',
      '😍', '🥰', '😘', '😗', '😋', '😜', '🤪', '😝', '😎', '🥳', '🤩',
      '😮', '😯', '😱', '😳', '😢', '😭', '😤', '😠', '😡', '🤯', '🥺',
      '😐', '😑', '🙄', '😏', '😒', '😔', '😪', '🤤', '😴', '🥱', '😷',
    ],
    'Gestures': [
      '👋', '🤚', '🖐', '✋', '🖖', '👌', '🤌', '✌️', '🤞', '🤟', '🤘',
      '🤙', '👈', '👉', '👆', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛',
      '🤜', '👏', '🙌', '🫶', '🤝', '🙏', '💪', '🦵', '🦶', '💅', '🤳',
    ],
    'Animals': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁',
      '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🦄', '🦓', '🐔', '🐧',
      '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🐝', '🦋', '🐢', '🐊',
    ],
    'Food': [
      '🍎', '🍊', '🍋', '🍇', '🍓', '🫐', '🍉', '🍑', '🥭', '🍍', '🥥',
      '🍅', '🫒', '🥑', '🍆', '🥦', '🌽', '🥕', '🍄', '🍕', '🍔', '🌮',
      '🌯', '🥗', '🍜', '🍣', '🍱', '🍦', '🍰', '🎂', '🍫', '🍬', '☕',
      '🍵', '🧋', '🍺', '🍻', '🥂',
    ],
    'Travel': [
      '✈️', '🚀', '🛸', '🚁', '🚂', '🚗', '🚕', '🚙', '🚌', '🏎️', '🏍️',
      '🛵', '🚲', '⛵', '🛳️', '🏖️', '🏝️', '⛺', '🌋', '🏔️', '🗻', '🌃',
      '🌆', '🏙️', '🗽', '🗼', '🏰', '🗺️', '🧭', '🌍', '🌎', '🌏',
    ],
    'Sports': [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓',
      '🏸', '🥊', '🥋', '🎽', '⛷️', '🏂', '🤸', '⛹️', '🤺', '🤼', '🤾',
      '🏋️', '🚴', '🧘', '🏊', '🏄', '🎯', '🎮', '🎲',
    ],
    'Objects': [
      '💼', '👜', '👛', '👓', '🕶️', '💍', '💎', '💰', '💳', '💡', '🔦',
      '📱', '💻', '🖥️', '🎮', '📷', '🎵', '🎶', '🎸', '🎹', '🎤', '🎧',
      '📚', '✏️', '📝', '🔑', '🗝️', '🔒', '🔓', '🔨', '🪄', '🧲', '🔭',
    ],
    'Symbols': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❤️‍🔥',
      '💕', '💞', '💓', '💗', '💖', '💘', '💝', '⭐', '🌟', '✨', '💫',
      '🌙', '☀️', '⛅', '🌈', '⚡', '🔥', '💧', '🌊', '🌸', '🌺', '🌻',
      '🌹', '🍀', '🎉', '🎊', '🏆', '🎁',
    ],
  };

  int _selectedCategoryIndex = 0;

  void _insertEmoji(String emoji) {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, emoji);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryName = _categories[_selectedCategoryIndex].name;
    final emojis = _emojisByCategory[categoryName] ?? [];

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Category tab bar ────────────────────────────────────
          SizedBox(
            height: 46,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCategoryIndex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 38,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.white : AppColors.black)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _categories[index].icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Close / back-to-keyboard button
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.keyboard_outlined,
                      size: 22,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Thin divider ────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
          ),

          // ── Emoji grid ──────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _insertEmoji(emojis[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A slim emoji button for the input bar left side (Telegram-style smiley).
class EmojiToggleButton extends StatelessWidget {
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const EmojiToggleButton({
    super.key,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.white : AppColors.black)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isActive
                  ? Icons.emoji_emotions
                  : Icons.emoji_emotions_outlined,
              size: 20,
              color: isActive
                  ? (isDark ? AppColors.black : AppColors.white)
                  : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray500),
            ),
          ),
        ),
      ),
    );
  }
}
