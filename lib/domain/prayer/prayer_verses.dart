import 'dart:math';

class PrayerVerse {
  const PrayerVerse({
    required this.tr,
    required this.en,
    required this.reference,
  });

  final String tr;
  final String en;
  final String reference;
}

/// A small offline set of Quran passages explicitly about establishing prayer.
const prayerVerses = <PrayerVerse>[
  PrayerVerse(
    tr: 'Namazı dosdoğru kılın, zekâtı verin ve rükû edenlerle birlikte rükû edin.',
    en: 'Establish prayer, give zakah, and bow with those who bow.',
    reference: 'Bakara 2:43 · Al-Baqarah 2:43',
  ),
  PrayerVerse(
    tr: 'Sabır ve namazla Allah’tan yardım isteyin. Şüphesiz namaz, Allah’a derinden saygı duyanlardan başkasına ağır gelir.',
    en: 'Seek help through patience and prayer. Indeed, it is difficult except for the humbly submissive.',
    reference: 'Bakara 2:45 · Al-Baqarah 2:45',
  ),
  PrayerVerse(
    tr: 'Namazlara ve orta namaza devam edin; gönülden bağlılık ve saygı içinde Allah’ın huzurunda durun.',
    en: 'Maintain the prayers, especially the middle prayer, and stand before Allah in devotion.',
    reference: 'Bakara 2:238 · Al-Baqarah 2:238',
  ),
  PrayerVerse(
    tr: 'Namaz, müminler üzerine vakitleri belirlenmiş bir farzdır.',
    en: 'Indeed, prayer has been decreed upon the believers at appointed times.',
    reference: 'Nisâ 4:103 · An-Nisa 4:103',
  ),
  PrayerVerse(
    tr: 'Namazı dosdoğru kılın, zekâtı verin ve Peygamber’e itaat edin ki merhamet olunasınız.',
    en: 'Establish prayer, give zakah, and obey the Messenger so that you may receive mercy.',
    reference: 'Nûr 24:56 · An-Nur 24:56',
  ),
  PrayerVerse(
    tr: 'Sana vahyedilen Kitab’ı oku ve namazı dosdoğru kıl. Çünkü namaz, hayâsızlıktan ve kötülükten alıkoyar.',
    en: 'Recite what has been revealed to you of the Book and establish prayer. Prayer restrains immorality and wrongdoing.',
    reference: 'Ankebût 29:45 · Al-Ankabut 29:45',
  ),
  PrayerVerse(
    tr: 'Ey oğulcuğum! Namazı dosdoğru kıl, iyiliği emret, kötülükten sakındır ve başına gelene sabret.',
    en: 'O my son, establish prayer, encourage what is right, forbid what is wrong, and be patient over what befalls you.',
    reference: 'Lokmân 31:17 · Luqman 31:17',
  ),
  PrayerVerse(
    tr: 'Gündüzün iki ucunda ve gecenin gündüze yakın vakitlerinde namazı dosdoğru kıl. İyilikler kötülükleri giderir.',
    en: 'Establish prayer at the two ends of the day and in the early part of the night. Good deeds remove misdeeds.',
    reference: 'Hûd 11:114 · Hud 11:114',
  ),
  PrayerVerse(
    tr: 'Ailene namazı emret ve kendin de ona sabırla devam et.',
    en: 'Enjoin prayer upon your family and be steadfast in maintaining it.',
    reference: 'Tâhâ 20:132 · Ta-Ha 20:132',
  ),
  PrayerVerse(
    tr: 'Güneşin zevalinden gecenin karanlığına kadar namazı kıl; sabah namazını da. Çünkü sabah namazı şahitlidir.',
    en: 'Establish prayer from the sun’s decline until the darkness of night, and the Quran at dawn; the dawn recitation is witnessed.',
    reference: 'İsrâ 17:78 · Al-Isra 17:78',
  ),
];

PrayerVerse randomPrayerVerse([Random? random]) =>
    prayerVerses[(random ?? Random()).nextInt(prayerVerses.length)];
