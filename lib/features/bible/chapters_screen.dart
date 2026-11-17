import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/mock_data.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';

/// BIB-02 — главы книги.
class ChaptersScreen extends ConsumerWidget {
  const ChaptersScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tradition = ref.watch(sessionProvider).tradition;
    final book = [...oldTestament(tradition), ...newTestament(tradition)].firstWhere((b) => b.id == bookId);

    return Scaffold(
      appBar: appHeader(context, book.name),
      body: GridView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 72, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: book.chapters,
        itemBuilder: (context, i) => Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/read/$bookId/${i + 1}'),
            child: Center(child: Text('${i + 1}', style: context.text.titleMedium)),
          ),
        ),
      ),
    );
  }
}
