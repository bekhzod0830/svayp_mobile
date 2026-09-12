import 'package:flutter/material.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:swipe/shared/widgets/guest_login_prompt.dart';

/// Opens the chat list as a full-screen route on the ROOT navigator (the tab
/// bar is hidden underneath), now that Chat is no longer a bottom tab.
///
/// Guests get the login prompt instead — the chat API is per-user. Shared by
/// the header paper-plane icon ([MainTopBar]), the web→native `open_chat_list`
/// bridge message, and legacy `navigateToTab(chat)` callers.
Future<void> openChatList(BuildContext context) async {
  final storage = await LocalStorageHelper.getInstance();
  if (!context.mounted) return;
  if (storage.isGuestMode()) {
    GuestLoginPrompt.show(context);
    return;
  }
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const ChatListScreen()),
  );
}
