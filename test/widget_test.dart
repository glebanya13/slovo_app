import 'dart:io';

import 'package:slovo_app/data/mock_data.dart';
import 'package:slovo_app/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Bible.loadFromBytes(File('assets/bible_ru.json.gz').readAsBytesSync()));

  test('Синодальный перевод загружен: 66 книг', () {
    expect(oldTestament(Tradition.orthodox).length, 39);
    expect(oldTestament(Tradition.catholic).length, 39);
    expect(newTestament(Tradition.orthodox).length, 27);
    expect(bookById('ps').chapters, 151);
  });

  test('порядок книг зависит от традиции', () {
    final orthodox = newTestament(Tradition.orthodox).map((b) => b.id).toList();
    expect(orthodox.indexOf('jas'), orthodox.indexOf('acts') + 1);
    final catholic = newTestament(Tradition.catholic).map((b) => b.id).toList();
    expect(catholic.indexOf('rom'), catholic.indexOf('acts') + 1);
  });

  test('нумерация псалмов по Септуагинте', () {
    expect(chapterTitle(bookById('ps'), 22, Tradition.orthodox), 'Псалом 22 (23)');
    expect(chapterText('ps', 22, Tradition.orthodox)!.first.text, contains('Пастырь мой'));
    expect(chapterText('matt', 5, Tradition.catholic)![2].text, startsWith('Блаженны нищие духом'));
  });

  test('поиск по тексту', () {
    final hits = Bible.instance.search('Отче наш');
    expect(hits, isNotEmpty);
    expect(hits.first.book, 'matt');
  });
}
