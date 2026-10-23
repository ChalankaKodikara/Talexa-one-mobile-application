import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? Colors.white60 : const Color(0xFF89919D);
    final line = dark ? Colors.white12 : const Color(0xFFECEFF3);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true, backgroundColor: bg, foregroundColor: ink,
        elevation: 0, scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
        children: [
          Text('How can we help?', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 24, color: ink)),
          const SizedBox(height: 6),
          Text('Our team is here when you need a hand.',
            style: TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 30),
          Text('CONTACT SUPPORT', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: .6, color: muted)),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(color: surface,
              borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              _HelpRow(icon: Icons.mail_outline_rounded, title: 'Email Support',
                detail: 'it-support@talentfort.lk', dark: dark,
                onTap: () => _launch(context,
                  Uri(scheme: 'mailto', path: 'it-support@talentfort.lk'))),
              Padding(padding: const EdgeInsets.only(left: 52),
                child: Divider(height: 1, color: line)),
              // No hard-coded phone number: original source used a placeholder.
              _HelpRow(icon: Icons.support_agent_outlined,
                title: 'Technical assistance',
                detail: 'For urgent issues, contact your IT support team.',
                dark: dark),
            ]),
          ),
          const SizedBox(height: 22),
          Center(child: Text('Talexa HRMS • Smart workplace access',
            style: TextStyle(color: muted, fontSize: 11))),
        ],
      )),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final success = await launchUrl(uri);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application available to open email.')));
    }
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.icon, required this.title,
    required this.detail, required this.dark, this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? Colors.white60 : const Color(0xFF89919D);
    return Material(color: Colors.transparent,
      child: InkWell(onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: Row(children: [
            Icon(icon, size: 21, color: ink),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: ink,
                  fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(detail, style: TextStyle(color: muted, fontSize: 12)),
              ])),
            if (onTap != null) Icon(Icons.chevron_right_rounded,
              size: 19, color: muted),
          ]),
        ),
      ),
    );
  }
}
