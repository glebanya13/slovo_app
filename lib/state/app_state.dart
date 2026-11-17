import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/local_store.dart';

enum Tradition { orthodox, catholic, exploring, undecided }

extension TraditionX on Tradition {
  String get title => switch (this) {
    Tradition.orthodox => 'Православие',
    Tradition.catholic => 'Католицизм',
    Tradition.exploring => 'Изучаю христианство',
    Tradition.undecided => 'Пока не определился',
  };

  String get subtitle => switch (this) {
    Tradition.orthodox =>
      'Синодальный перевод, юлианский календарь, православный молитвослов',
    Tradition.catholic =>
      'Католический канон, литургический календарь, Катехизис',
    Tradition.exploring => 'Общехристианские ответы, где нужно — обе позиции',
    Tradition.undecided => 'Можно выбрать позже в настройках',
  };

  /// Сколько книг Ветхого Завета показывать (без неканонических).
  int get oldTestamentBooks => 39;

  /// Православная (и синодальная) нумерация псалмов — по Септуагинте.
  bool get lxxPsalms => this != Tradition.catholic;
}

@immutable
class Session {
  const Session({
    this.onboarded = false,
    this.signedIn = false,
    this.name = '',
    this.tradition = Tradition.undecided,
    this.goals = const {},
    this.aiConsent = false,
    this.specialDataConsent = false,
    this.privateAi = false,
    this.region = 'ru',
    this.joinedAt,
    this.voice = 'primary',
    this.themeMode = 'light',
    this.pushEnabled = true,
    this.hideNotificationBody = false,
    this.appLock = false,
    this.morningReminder = true,
    this.eveningReminder = true,
    this.morningHour = 8,
    this.morningMinute = 0,
    this.eveningHour = 21,
    this.eveningMinute = 0,
  });

  final bool onboarded;
  final bool signedIn;
  final String name;
  final Tradition tradition;
  final Set<String> goals;
  final bool aiConsent;
  final bool specialDataConsent;
  final bool privateAi;

  /// Контур хранения данных: ru — РФ и СНГ, int — остальные страны (раздел 2 ТЗ).
  final String region;

  /// Когда человек начал пользоваться приложением («История пути»).
  final DateTime? joinedAt;

  /// Голос озвучки: имя значения TtsVoice.
  final String voice;

  /// Тема: light / dark / system.
  final String themeMode;

  /// Разрешены ли push-уведомления в приложении.
  final bool pushEnabled;

  /// Скрывать текст уведомлений на экране блокировки (сохраняется для будущей нативной настройки).
  final bool hideNotificationBody;

  /// Защита приложения Face ID / отпечатком.
  final bool appLock;

  final bool morningReminder;
  final bool eveningReminder;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;

  bool get isGuest => !signedIn;

  ThemeMode get materialThemeMode => switch (themeMode) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  Session copyWith({
    bool? onboarded,
    bool? signedIn,
    String? name,
    Tradition? tradition,
    Set<String>? goals,
    bool? aiConsent,
    bool? specialDataConsent,
    bool? privateAi,
    String? region,
    DateTime? joinedAt,
    String? voice,
    String? themeMode,
    bool? pushEnabled,
    bool? hideNotificationBody,
    bool? appLock,
    bool? morningReminder,
    bool? eveningReminder,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
  }) => Session(
    onboarded: onboarded ?? this.onboarded,
    signedIn: signedIn ?? this.signedIn,
    name: name ?? this.name,
    tradition: tradition ?? this.tradition,
    goals: goals ?? this.goals,
    aiConsent: aiConsent ?? this.aiConsent,
    specialDataConsent: specialDataConsent ?? this.specialDataConsent,
    privateAi: privateAi ?? this.privateAi,
    region: region ?? this.region,
    joinedAt: joinedAt ?? this.joinedAt,
    voice: voice ?? this.voice,
    themeMode: themeMode ?? this.themeMode,
    pushEnabled: pushEnabled ?? this.pushEnabled,
    hideNotificationBody: hideNotificationBody ?? this.hideNotificationBody,
    appLock: appLock ?? this.appLock,
    morningReminder: morningReminder ?? this.morningReminder,
    eveningReminder: eveningReminder ?? this.eveningReminder,
    morningHour: morningHour ?? this.morningHour,
    morningMinute: morningMinute ?? this.morningMinute,
    eveningHour: eveningHour ?? this.eveningHour,
    eveningMinute: eveningMinute ?? this.eveningMinute,
  );

  Map<String, Object?> toJson() => {
    'onboarded': onboarded,
    'signedIn': signedIn,
    'name': name,
    // Особая категория данных хранится только с согласия (раздел 2.2 ТЗ).
    'tradition': specialDataConsent ? tradition.name : Tradition.undecided.name,
    'goals': goals.toList(),
    'aiConsent': aiConsent,
    'specialDataConsent': specialDataConsent,
    'privateAi': privateAi,
    'region': region,
    'joinedAt': joinedAt?.toIso8601String(),
    'voice': voice,
    'themeMode': themeMode,
    'pushEnabled': pushEnabled,
    'hideNotificationBody': hideNotificationBody,
    'appLock': appLock,
    'morningReminder': morningReminder,
    'eveningReminder': eveningReminder,
    'morningHour': morningHour,
    'morningMinute': morningMinute,
    'eveningHour': eveningHour,
    'eveningMinute': eveningMinute,
  };

  factory Session.fromJson(Map<String, Object?> j) => Session(
    onboarded: j['onboarded'] as bool? ?? false,
    signedIn: j['signedIn'] as bool? ?? false,
    name: j['name'] as String? ?? '',
    tradition:
        Tradition.values.asNameMap()[j['tradition']] ?? Tradition.undecided,
    goals: {...(j['goals'] as List? ?? const []).cast<String>()},
    aiConsent: j['aiConsent'] as bool? ?? false,
    specialDataConsent: j['specialDataConsent'] as bool? ?? false,
    privateAi: j['privateAi'] as bool? ?? false,
    region: j['region'] as String? ?? 'ru',
    joinedAt: DateTime.tryParse(j['joinedAt'] as String? ?? ''),
    voice: j['voice'] as String? ?? 'primary',
    themeMode: j['themeMode'] as String? ?? 'light',
    pushEnabled: j['pushEnabled'] as bool? ?? true,
    hideNotificationBody: j['hideNotificationBody'] as bool? ?? false,
    appLock: j['appLock'] as bool? ?? false,
    morningReminder: j['morningReminder'] as bool? ?? true,
    eveningReminder: j['eveningReminder'] as bool? ?? true,
    morningHour: j['morningHour'] as int? ?? 8,
    morningMinute: j['morningMinute'] as int? ?? 0,
    eveningHour: j['eveningHour'] as int? ?? 21,
    eveningMinute: j['eveningMinute'] as int? ?? 0,
  );
}

class SessionNotifier extends Notifier<Session> {
  static const _key = 'session';

  @override
  Session build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    final s = j is Map<String, Object?> ? Session.fromJson(j) : const Session();
    return _enforceConsent(s);
  }

  @override
  set state(Session value) {
    super.state = value;
    ref.read(localStoreProvider).writeJson(_key, value.toJson());
  }

  /// Религиозные взгляды считаются особыми данными: без явного согласия
  /// традиция не сохраняется и не используется ни локально, ни в запросах.
  static Session _enforceConsent(Session s) =>
      s.specialDataConsent || s.tradition == Tradition.undecided
      ? s
      : s.copyWith(tradition: Tradition.undecided);

  void update(Session Function(Session s) fn) =>
      state = _enforceConsent(fn(state));

  void finishOnboarding({required bool signedIn}) => state = _enforceConsent(
    state.copyWith(
      onboarded: true,
      signedIn: signedIn,
      joinedAt: state.joinedAt ?? DateTime.now(),
    ),
  );

  /// Выход: все локальные данные удаляются с устройства.
  Future<void> signOut() async {
    await ref.read(localStoreProvider).clearAll();
    ref.invalidate(practicesProvider);
    ref.invalidate(journalProvider);
    ref.invalidate(myPrayersProvider);
    ref.invalidate(favoritePrayersProvider);
    ref.invalidate(aiCacheProvider);
    ref.invalidate(confessionListProvider);
    ref.invalidate(readerMarksProvider);
    ref.invalidate(readingProgressProvider);
    super.state = const Session();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);

String _today() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Практики дня, отмеченные «сделано» (индикатор «3 из 5»). Сбрасываются каждый день.
class PracticesNotifier extends Notifier<Set<String>> {
  static const _key = 'practices';

  @override
  Set<String> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is Map && j['date'] == _today()) {
      return {...(j['done'] as List).cast<String>()};
    }
    return const {};
  }

  void _save(Set<String> v) {
    state = v;
    ref.read(localStoreProvider).writeJson(_key, {
      'date': _today(),
      'done': v.toList(),
    });
  }

  void toggle(String id) =>
      _save(state.contains(id) ? ({...state}..remove(id)) : {...state, id});
  void markDone(String id) => _save({...state, id});
}

final practicesProvider = NotifierProvider<PracticesNotifier, Set<String>>(
  PracticesNotifier.new,
);

@immutable
class JournalEntry {
  const JournalEntry({
    required this.date,
    required this.text,
    required this.mood,
  });
  final DateTime date;
  final String text;
  final int mood;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String(),
    'text': text,
    'mood': mood,
  };
  factory JournalEntry.fromJson(Map<String, Object?> j) => JournalEntry(
    date: DateTime.parse(j['date']! as String),
    text: j['text']! as String,
    mood: j['mood'] as int? ?? 2,
  );
}

/// Дневник — в защищённом хранилище устройства.
class JournalNotifier extends Notifier<List<JournalEntry>> {
  static const _key = 'journal';

  @override
  List<JournalEntry> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! List) return const [];
    return [
      for (final e in j)
        JournalEntry.fromJson((e as Map).cast<String, Object?>()),
    ];
  }

  void _save(List<JournalEntry> v) {
    state = v;
    ref.read(localStoreProvider).writeJson(_key, [
      for (final e in v) e.toJson(),
    ]);
  }

  void add(JournalEntry e) => _save([e, ...state]);
  void remove(JournalEntry e) => _save([...state]..remove(e));
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(
  JournalNotifier.new,
);

@immutable
class MyPrayer {
  const MyPrayer({
    required this.title,
    required this.text,
    this.aiGenerated = false,
  });
  final String title;
  final String text;
  final bool aiGenerated;

  Map<String, Object?> toJson() => {
    'title': title,
    'text': text,
    'ai': aiGenerated,
  };
  factory MyPrayer.fromJson(Map<String, Object?> j) => MyPrayer(
    title: j['title']! as String,
    text: j['text']! as String,
    aiGenerated: j['ai'] as bool? ?? false,
  );
}

class MyPrayersNotifier extends Notifier<List<MyPrayer>> {
  static const _key = 'my_prayers';

  @override
  List<MyPrayer> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! List) return const [];
    return [
      for (final e in j) MyPrayer.fromJson((e as Map).cast<String, Object?>()),
    ];
  }

  void _save(List<MyPrayer> v) {
    state = v;
    ref.read(localStoreProvider).writeJson(_key, [
      for (final p in v) p.toJson(),
    ]);
  }

  void add(MyPrayer p) => _save([p, ...state]);
  void remove(MyPrayer p) => _save([...state]..remove(p));
}

final myPrayersProvider = NotifierProvider<MyPrayersNotifier, List<MyPrayer>>(
  MyPrayersNotifier.new,
);

/// Избранные молитвы из молитвослова (по id).
class FavoritePrayersNotifier extends Notifier<Set<String>> {
  static const _key = 'favorite_prayers';

  @override
  Set<String> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! List) return const {};
    return {...j.cast<String>()};
  }

  void _save(Set<String> v) {
    state = v;
    ref.read(localStoreProvider).writeJson(_key, v.toList());
  }

  void toggle(String id) =>
      _save(state.contains(id) ? ({...state}..remove(id)) : {...state, id});
  bool isFavorite(String id) => state.contains(id);
}

final favoritePrayersProvider =
    NotifierProvider<FavoritePrayersNotifier, Set<String>>(
      FavoritePrayersNotifier.new,
    );

@immutable
class AiCacheEntry {
  const AiCacheEntry({
    required this.question,
    required this.answer,
    required this.updatedAt,
  });
  final String question;
  final String answer;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'q': question,
    'a': answer,
    'at': updatedAt.toIso8601String(),
  };

  factory AiCacheEntry.fromJson(Map<String, Object?> j) => AiCacheEntry(
    question: j['q']! as String,
    answer: j['a']! as String,
    updatedAt:
        DateTime.tryParse(j['at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Офлайн-кэш последних ответов AI (ключ — нормализованный вопрос + традиция).
class AiCacheNotifier extends Notifier<Map<String, AiCacheEntry>> {
  static const _key = 'ai_cache';
  static const _max = 40;

  @override
  Map<String, AiCacheEntry> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! Map) return const {};
    return {
      for (final e in j.entries)
        e.key as String: AiCacheEntry.fromJson(
          (e.value as Map).cast<String, Object?>(),
        ),
    };
  }

  static String keyFor(String question, Tradition t) =>
      '${t.name}|${question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';

  void put({
    required String question,
    required String answer,
    required Tradition tradition,
  }) {
    if (question.trim().isEmpty || answer.trim().isEmpty) return;
    final k = keyFor(question, tradition);
    final next = {
      ...state,
      k: AiCacheEntry(
        question: question.trim(),
        answer: answer.trim(),
        updatedAt: DateTime.now(),
      ),
    };
    // Держим только свежие записи.
    final sorted = next.entries.toList()
      ..sort((a, b) => b.value.updatedAt.compareTo(a.value.updatedAt));
    final trimmed = {for (final e in sorted.take(_max)) e.key: e.value};
    state = trimmed;
    ref.read(localStoreProvider).writeJson(_key, {
      for (final e in trimmed.entries) e.key: e.value.toJson(),
    });
  }

  AiCacheEntry? get(String question, Tradition tradition) =>
      state[keyFor(question, tradition)];
}

final aiCacheProvider =
    NotifierProvider<AiCacheNotifier, Map<String, AiCacheEntry>>(
      AiCacheNotifier.new,
    );

@immutable
class StoredChatMessage {
  const StoredChatMessage({
    required this.fromUser,
    required this.text,
    required this.at,
    this.failed = false,
  });
  final bool fromUser;
  final String text;
  final DateTime at;
  final bool failed;

  Map<String, Object?> toJson() => {
    'u': fromUser,
    't': text,
    'at': at.toIso8601String(),
    'f': failed,
  };

  factory StoredChatMessage.fromJson(Map<String, Object?> j) =>
      StoredChatMessage(
        fromUser: j['u'] as bool? ?? true,
        text: j['t'] as String? ?? '',
        at:
            DateTime.tryParse(j['at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        failed: j['f'] as bool? ?? false,
      );
}

/// История беседы AI на устройстве (не пишется при «Приватный AI»).
class ChatHistoryNotifier extends Notifier<List<StoredChatMessage>> {
  static const _key = 'chat_history';
  static const _max = 80;

  @override
  List<StoredChatMessage> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! List) return const [];
    return [
      for (final e in j)
        if (e is Map) StoredChatMessage.fromJson(e.cast<String, Object?>()),
    ];
  }

  void _persist(List<StoredChatMessage> msgs) {
    final private = ref.read(sessionProvider).privateAi;
    if (private) {
      state = const [];
      ref.read(localStoreProvider).writeJson(_key, const []);
      return;
    }
    final trimmed = msgs.length > _max
        ? msgs.sublist(msgs.length - _max)
        : List<StoredChatMessage>.from(msgs);
    state = trimmed;
    ref.read(localStoreProvider).writeJson(_key, [
      for (final m in trimmed) m.toJson(),
    ]);
  }

  void saveAll(List<StoredChatMessage> msgs) => _persist(msgs);

  void clear() {
    state = const [];
    ref.read(localStoreProvider).writeJson(_key, const []);
  }
}

final chatHistoryProvider =
    NotifierProvider<ChatHistoryNotifier, List<StoredChatMessage>>(
      ChatHistoryNotifier.new,
    );

/// Список «Сказать священнику» — только на устройстве, в защищённом хранилище (раздел 8.4 ТЗ).
class ConfessionListNotifier extends Notifier<List<String>> {
  static const _key = 'confession_list';

  @override
  List<String> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    return j is List ? j.cast<String>() : const [];
  }

  void _save(List<String> v) {
    state = v;
    ref.read(localStoreProvider).writeJson(_key, v);
  }

  void addAll(Iterable<String> items) => _save({...state, ...items}.toList());
  void remove(String item) => _save([...state]..remove(item));
  void clear() => _save(const []);
}

final confessionListProvider =
    NotifierProvider<ConfessionListNotifier, List<String>>(
      ConfessionListNotifier.new,
    );

/// Отметки при чтении: выделения стихов, закладки и «нравится» по главам.
/// Ключ главы — «книга:глава», например `ps:22`.
@immutable
class ChapterMarks {
  const ChapterMarks({
    this.highlights = const {},
    this.bookmarked = false,
    this.liked = false,
  });
  final Set<int> highlights;
  final bool bookmarked;
  final bool liked;

  ChapterMarks copyWith({
    Set<int>? highlights,
    bool? bookmarked,
    bool? liked,
  }) => ChapterMarks(
    highlights: highlights ?? this.highlights,
    bookmarked: bookmarked ?? this.bookmarked,
    liked: liked ?? this.liked,
  );

  bool get isEmpty => highlights.isEmpty && !bookmarked && !liked;

  Map<String, Object?> toJson() => {
    'h': highlights.toList(),
    'b': bookmarked,
    'l': liked,
  };
  factory ChapterMarks.fromJson(Map<String, Object?> j) => ChapterMarks(
    highlights: {...(j['h'] as List? ?? const []).cast<int>()},
    bookmarked: j['b'] as bool? ?? false,
    liked: j['l'] as bool? ?? false,
  );
}

class ReaderMarksNotifier extends Notifier<Map<String, ChapterMarks>> {
  static const _key = 'reader_marks';

  @override
  Map<String, ChapterMarks> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! Map) return const {};
    return {
      for (final e in j.entries)
        e.key as String: ChapterMarks.fromJson(
          (e.value as Map).cast<String, Object?>(),
        ),
    };
  }

  void edit(String chapterKey, ChapterMarks Function(ChapterMarks m) fn) {
    final next = fn(state[chapterKey] ?? const ChapterMarks());
    final map = {...state};
    next.isEmpty ? map.remove(chapterKey) : map[chapterKey] = next;
    state = map;
    ref.read(localStoreProvider).writeJson(_key, {
      for (final e in map.entries) e.key: e.value.toJson(),
    });
  }
}

final readerMarksProvider =
    NotifierProvider<ReaderMarksNotifier, Map<String, ChapterMarks>>(
      ReaderMarksNotifier.new,
    );

/// Прогресс чтения по книгам: где остановились (глава и стих).
@immutable
class ReadingSpot {
  const ReadingSpot({
    required this.bookId,
    required this.chapter,
    this.verse = 1,
    required this.updatedAt,
  });
  final String bookId;
  final int chapter;
  final int verse;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'bookId': bookId,
    'chapter': chapter,
    'verse': verse,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReadingSpot.fromJson(Map<String, Object?> j) => ReadingSpot(
    bookId: j['bookId']! as String,
    chapter: j['chapter'] as int? ?? 1,
    verse: j['verse'] as int? ?? 1,
    updatedAt:
        DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class ReadingProgressNotifier extends Notifier<Map<String, ReadingSpot>> {
  static const _key = 'reading_progress';

  @override
  Map<String, ReadingSpot> build() {
    final j = ref.read(localStoreProvider).readJson(_key);
    if (j is! Map) return const {};
    return {
      for (final e in j.entries)
        e.key as String: ReadingSpot.fromJson(
          (e.value as Map).cast<String, Object?>(),
        ),
    };
  }

  void save({required String bookId, required int chapter, int verse = 1}) {
    final spot = ReadingSpot(
      bookId: bookId,
      chapter: chapter,
      verse: verse < 1 ? 1 : verse,
      updatedAt: DateTime.now(),
    );
    final map = {...state, bookId: spot};
    state = map;
    ref.read(localStoreProvider).writeJson(_key, {
      for (final e in map.entries) e.key: e.value.toJson(),
    });
  }

  ReadingSpot? get last {
    if (state.isEmpty) return null;
    return state.values.reduce(
      (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );
  }
}

final readingProgressProvider =
    NotifierProvider<ReadingProgressNotifier, Map<String, ReadingSpot>>(
      ReadingProgressNotifier.new,
    );

final lastReadingProvider = Provider<ReadingSpot?>((ref) {
  final map = ref.watch(readingProgressProvider);
  if (map.isEmpty) return null;
  return map.values.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
});
