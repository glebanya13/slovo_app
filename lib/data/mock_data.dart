// Справочники книг, краткий молитвослов и формат даты.
// Текст Писания — из assets/bible_ru.json.gz (Синодальный перевод).

import '../state/app_state.dart';
import 'bible.dart';

export 'bible.dart' show Bible;

class BibleBook {
  const BibleBook(this.id, this.name, this.chapters, {this.deutero = false});
  final String id;
  final String name;

  /// Число глав в справочнике; фактическое берётся из загруженного текста.
  final int chapters;

  /// Неканоническая (у православных) / второканоническая (у католиков) книга.
  final bool deutero;
}

const _otSynodal = <BibleBook>[
  BibleBook('gen', 'Бытие', 50),
  BibleBook('exod', 'Исход', 40),
  BibleBook('lev', 'Левит', 27),
  BibleBook('num', 'Числа', 36),
  BibleBook('deut', 'Второзаконие', 34),
  BibleBook('josh', 'Иисус Навин', 24),
  BibleBook('judg', 'Судьи', 21),
  BibleBook('ruth', 'Руфь', 4),
  BibleBook('1sam', '1 Царств', 31),
  BibleBook('2sam', '2 Царств', 24),
  BibleBook('1kgs', '3 Царств', 22),
  BibleBook('2kgs', '4 Царств', 25),
  BibleBook('1chr', '1 Паралипоменон', 29),
  BibleBook('2chr', '2 Паралипоменон', 36),
  BibleBook('ezra', '1 Ездры', 10),
  BibleBook('neh', 'Неемия', 13),
  BibleBook('1esd', '2 Ездры', 9, deutero: true),
  BibleBook('tob', 'Товит', 14, deutero: true),
  BibleBook('jdt', 'Иудифь', 16, deutero: true),
  BibleBook('esth', 'Есфирь', 10),
  BibleBook('job', 'Иов', 42),
  BibleBook('ps', 'Псалтирь', 151),
  BibleBook('prov', 'Притчи', 31),
  BibleBook('eccl', 'Екклесиаст', 12),
  BibleBook('song', 'Песнь песней', 8),
  BibleBook('wis', 'Премудрость Соломона', 19, deutero: true),
  BibleBook('sir', 'Сирах', 51, deutero: true),
  BibleBook('isa', 'Исаия', 66),
  BibleBook('jer', 'Иеремия', 52),
  BibleBook('lam', 'Плач Иеремии', 5),
  BibleBook('epjer', 'Послание Иеремии', 1, deutero: true),
  BibleBook('bar', 'Варух', 6, deutero: true),
  BibleBook('ezek', 'Иезекииль', 48),
  BibleBook('dan', 'Даниил', 14),
  BibleBook('hos', 'Осия', 14),
  BibleBook('joel', 'Иоиль', 3),
  BibleBook('amos', 'Амос', 9),
  BibleBook('obad', 'Авдий', 1),
  BibleBook('jonah', 'Иона', 4),
  BibleBook('mic', 'Михей', 7),
  BibleBook('nah', 'Наум', 3),
  BibleBook('hab', 'Аввакум', 3),
  BibleBook('zeph', 'Софония', 3),
  BibleBook('hag', 'Аггей', 2),
  BibleBook('zech', 'Захария', 14),
  BibleBook('mal', 'Малахия', 4),
  BibleBook('1macc', '1 Маккавейская', 16, deutero: true),
  BibleBook('2macc', '2 Маккавейская', 15, deutero: true),
  BibleBook('3macc', '3 Маккавейская', 7, deutero: true),
  BibleBook('2esd', '3 Ездры', 16, deutero: true),
];

const _gospelsActs = <BibleBook>[
  BibleBook('matt', 'От Матфея', 28),
  BibleBook('mark', 'От Марка', 16),
  BibleBook('luke', 'От Луки', 24),
  BibleBook('john', 'От Иоанна', 21),
  BibleBook('acts', 'Деяния', 28),
];

const _catholicEpistles = <BibleBook>[
  BibleBook('jas', 'Иакова', 5),
  BibleBook('1pet', '1 Петра', 5),
  BibleBook('2pet', '2 Петра', 3),
  BibleBook('1john', '1 Иоанна', 5),
  BibleBook('2john', '2 Иоанна', 1),
  BibleBook('3john', '3 Иоанна', 1),
  BibleBook('jude', 'Иуды', 1),
];

const _pauline = <BibleBook>[
  BibleBook('rom', 'Римлянам', 16),
  BibleBook('1cor', '1 Коринфянам', 16),
  BibleBook('2cor', '2 Коринфянам', 13),
  BibleBook('gal', 'Галатам', 6),
  BibleBook('eph', 'Ефесянам', 6),
  BibleBook('phil', 'Филиппийцам', 4),
  BibleBook('col', 'Колоссянам', 4),
  BibleBook('1thess', '1 Фессалоникийцам', 5),
  BibleBook('2thess', '2 Фессалоникийцам', 3),
  BibleBook('1tim', '1 Тимофею', 6),
  BibleBook('2tim', '2 Тимофею', 4),
  BibleBook('titus', 'Титу', 3),
  BibleBook('phlm', 'Филимону', 1),
  BibleBook('heb', 'Евреям', 13),
];

const _rev = BibleBook('rev', 'Откровение', 22);


/// Книги, которых нет в загруженном тексте Синодального перевода
/// (73-книжное издание): 2 Ездры, 3 Маккавейская, 3 Ездры.
/// Послание Иеремии входит в Варуха как 6-я глава.
const _missingInText = {'1esd', '3macc', '2esd', 'epjer'};

List<BibleBook> _withText(Iterable<BibleBook> books) => [
      for (final b in books)
        if (!_missingInText.contains(b.id) && Bible.instance.hasBook(b.id))
          BibleBook(b.id, b.name, Bible.instance.chapterCount(b.id), deutero: b.deutero),
    ];

/// Порядок книг: у православных — по Синодальному изданию,
/// у католиков — Товит и Иудифь после Неемии, Маккавейские после Есфири.
List<BibleBook> oldTestament(Tradition t) {
  // Неканонические / второканонические книги не показываем.
  final books = _otSynodal.where((b) => !b.deutero);
  if (t != Tradition.catholic) return _withText(books);
  const catholicOrder = [
    'gen', 'exod', 'lev', 'num', 'deut', 'josh', 'judg', 'ruth', '1sam', '2sam', '1kgs', '2kgs',
    '1chr', '2chr', 'ezra', 'neh', 'esth', 'job', 'ps', 'prov', 'eccl', 'song', 'isa', 'jer', 'lam',
    'ezek', 'dan', 'hos', 'joel', 'amos', 'obad', 'jonah', 'mic', 'nah', 'hab', 'zeph', 'hag', 'zech',
    'mal',
  ];
  final byId = {for (final b in books) b.id: b};
  return _withText([for (final id in catholicOrder) byId[id]!]);
}

/// В Синодальном издании соборные послания идут перед посланиями Павла,
/// в католических изданиях — после.
List<BibleBook> newTestament(Tradition t) => _withText(t == Tradition.catholic
    ? [..._gospelsActs, ..._pauline, ..._catholicEpistles, _rev]
    : [..._gospelsActs, ..._catholicEpistles, ..._pauline, _rev]);

BibleBook bookById(String id) {
  final b = [..._otSynodal, ..._gospelsActs, ..._catholicEpistles, ..._pauline, _rev].firstWhere((b) => b.id == id);
  return Bible.instance.hasBook(id) ? BibleBook(b.id, b.name, Bible.instance.chapterCount(id), deutero: b.deutero) : b;
}

/// Текст — Синодальный перевод с нумерацией псалмов по Септуагинте (LXX).
/// Для всех традиций показываем номер LXX и в скобках еврейский номер.
String chapterTitle(BibleBook b, int ch, Tradition t) {
  if (b.id != 'ps') return '${b.name}, глава $ch';
  final hebrew = _lxxToHebrew(ch);
  return hebrew == ch ? 'Псалом $ch' : 'Псалом $ch ($hebrew)';
}

/// Упрощённое соответствие LXX → масоретская нумерация для основного диапазона.
int _lxxToHebrew(int lxx) {
  if (lxx <= 8 || lxx >= 148) return lxx;
  if (lxx >= 10 && lxx <= 112) return lxx + 1;
  if (lxx >= 116 && lxx <= 145) return lxx + 1;
  return lxx; // 9, 113–115, 146–147 — составные; точная карта в versification_map
}

class Verse {
  const Verse(this.n, this.text);
  final int n;
  final String text;
}

List<Verse>? chapterText(String bookId, int ch, Tradition t) => Bible.instance.verses(bookId, ch);

class Prayer {
  const Prayer(this.id, this.title, this.text, {this.note});
  final String id;
  final String title;
  final String text;
  final String? note;
}

const _ourFather = Prayer(
  'our_father',
  'Молитва Господня',
  'Отче наш, Иже еси на небесех! Да святится имя Твое, да приидет Царствие Твое, да будет воля Твоя, яко на небеси и на земли. Хлеб наш насущный даждь нам днесь; и остави нам долги наша, якоже и мы оставляем должником нашим; и не введи нас во искушение, но избави нас от лукаваго.',
);

const _jesusPrayer = Prayer(
  'jesus',
  'Иисусова молитва',
  'Господи Иисусе Христе, Сыне Божий, помилуй мя грешнаго.',
  note: 'Читается многократно, в том числе с чётками',
);

const _theotokos = Prayer(
  'theotokos',
  'Богородице Дево, радуйся',
  'Богородице Дево, радуйся, Благодатная Марие, Господь с Тобою; благословенна Ты в женах и благословен Плод чрева Твоего, яко Спаса родила еси душ наших.',
);

const _hailMary = Prayer(
  'hail_mary',
  'Радуйся, Мария',
  'Радуйся, Мария, благодати полная! Господь с Тобою; благословенна Ты между жёнами, и благословен плод чрева Твоего Иисус. Святая Мария, Матерь Божия, молись о нас, грешных, ныне и в час смерти нашей. Аминь.',
);

const _publican = Prayer(
  'publican',
  'Молитва мытаря',
  'Боже, милостив буди мне грешному.',
  note: 'Начало утреннего правила',
);

class PrayerSection {
  const PrayerSection(this.id, this.title, this.subtitle, this.prayers);
  final String id;
  final String title;
  final String subtitle;
  final List<Prayer> prayers;
}

List<PrayerSection> prayerBook(Tradition t) => t == Tradition.catholic
    ? const [
        PrayerSection('morning', 'Утренние молитвы', 'Начать день с Богом', [_ourFather, _hailMary]),
        PrayerSection('evening', 'Вечерние молитвы', 'Испытание совести и благодарность', [_ourFather, _hailMary]),
        PrayerSection('rosary', 'Розарий', 'Тайны дня и молитвы на бусинах', [_hailMary, _ourFather]),
        PrayerSection('short', 'Краткие молитвы', 'В течение дня', [_ourFather, _hailMary]),
      ]
    : const [
        PrayerSection('morning', 'Утреннее правило', 'Полное и краткое', [_publican, _ourFather, _theotokos]),
        PrayerSection('evening', 'Молитвы на сон грядущий', 'Вечернее правило', [_ourFather, _theotokos]),
        PrayerSection('communion', 'Ко Святому Причащению', 'Правило и благодарственные молитвы', [_ourFather]),
        PrayerSection('short', 'Краткие молитвы', 'В течение дня', [_jesusPrayer, _ourFather, _theotokos]),
      ];

Prayer prayerById(String id) =>
    [_ourFather, _jesusPrayer, _theotokos, _hailMary, _publican].firstWhere((p) => p.id == id);

const monthGen = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

const weekdays = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];

String formatDate(DateTime d) => '${d.day} ${monthGen[d.month - 1]}, ${weekdays[d.weekday - 1]}';
