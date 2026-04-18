class Dua {
  final String arabic;
  final String transliteration;
  final String translation;
  final String reference;

  Dua({required this.arabic, required this.transliteration, required this.translation, required this.reference});

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(arabic: json['arabic'] ?? '', transliteration: json['transliteration'] ?? '', translation: json['translation'] ?? '', reference: json['reference'] ?? '');
  }
}

class SubCategory {
  final String id;
  final String title;
  final String icon;
  final List<Dua> duas;

  SubCategory({required this.id, required this.title, required this.icon, required this.duas});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    final list = (json['duas'] as List<dynamic>?) ?? [];
    return SubCategory(id: json['id'] ?? '', title: json['title'] ?? '', icon: json['icon'] ?? '', duas: list.map((e) => Dua.fromJson(e)).toList());
  }
}

class DuaCategory {
  final String categoryId;
  final String title;
  final String icon;
  final List<SubCategory> subCategories;

  DuaCategory({required this.categoryId, required this.title, required this.icon, required this.subCategories});

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    final list = (json['subCategories'] as List<dynamic>?) ?? [];
    return DuaCategory(categoryId: json['categoryId'] ?? '', title: json['title'] ?? '', icon: json['icon'] ?? '', subCategories: list.map((e) => SubCategory.fromJson(e)).toList());
  }
}

class DuaRepository {
  List<DuaCategory> categories = [];

  Future<void> init() async {
    categories = _buildFullDatabase();
  }

  List<Dua> getDuasForSubCategory(String subCatId) {
    for (var cat in categories) {
      for (var sub in cat.subCategories) {
        if (sub.id == subCatId) return sub.duas;
      }
    }
    return [];
  }

  SubCategory? getSubCategoryData(String subCatId) {
    for (var cat in categories) {
      for (var sub in cat.subCategories) {
        if (sub.id == subCatId) return sub;
      }
    }
    return null;
  }

  /// Complete Hisnul Muslim Dua Database
  List<DuaCategory> _buildFullDatabase() {
    return [
      // ═══════════════ CORE DAILY LIFE ═══════════════
      DuaCategory(
        categoryId: "core",
        title: "CORE DAILY LIFE DUAS",
        icon: "🧭",
        subCategories: [
          SubCategory(id: "morning_adhkar", title: "Morning Adhkar", icon: "🌅", duas: [
            Dua(arabic: "اللّهُـمَّ بِكَ أَصْـبَحْنا وَبِكَ أَمْسَـينا ، وَبِكَ نَحْـيا وَبِكَ نَمُـوتُ وَإِلَيْكَ النُّـشُور", transliteration: "Allahumma bika asbahna wa bika amsayna, wa bika nahya wa bika namootu wa ilaykan-nushoor", translation: "O Allah, by Your leave we have reached the morning and by Your leave we have reached the evening, by Your leave we live and die and unto You is our resurrection.", reference: "Abu Dawud 4/317"),
            Dua(arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ", transliteration: "Asbahna wa-asbahal-mulku lillah walhamdu lillah la ilaha illallahu wahdahu la shareeka lah", translation: "We have reached the morning and at this very time the whole kingdom belongs to Allah. Praise is to Allah. None has the right to be worshipped but Allah alone.", reference: "Muslim 4/2088"),
            Dua(arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ", transliteration: "SubhanAllahi wa bihamdihi, 'adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatihi", translation: "How perfect Allah is and I praise Him by the number of His creation and His pleasure, and by the weight of His throne, and the ink of His words.", reference: "Muslim 4/2726"),
            Dua(arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma innee as'aluka ilman naafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds.", reference: "Ibn Majah"),
          ]),
          SubCategory(id: "evening_adhkar", title: "Evening Adhkar", icon: "🌆", duas: [
            Dua(arabic: "اللّهُـمَّ بِكَ أَمْسَـينا وَبِكَ أَصْـبَحْنا ، وَبِكَ نَحْـيا وَبِكَ نَمُـوتُ وَإِلَيْكَ المَصِير", transliteration: "Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namootu wa ilaykal-maseer", translation: "O Allah, by Your leave we have reached the evening and by Your leave we have reached the morning, by Your leave we live and die and unto You is our return.", reference: "At-Tirmidhi 5/466"),
            Dua(arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ", transliteration: "Amsayna wa-amsal-mulku lillahi walhamdu lillahi la ilaha illallahu wahdahu la shareeka lahu", translation: "We have reached the evening and at this very time the whole kingdom belongs to Allah. Praise is to Allah. None has the right to be worshipped but Allah alone.", reference: "Muslim 4/2088"),
            Dua(arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ", transliteration: "A'oothu bikalimatil-lahit-tammaati min sharri ma khalaq", translation: "I seek refuge in the perfect words of Allah from the evil of what He has created.", reference: "Muslim 4/2081"),
          ]),
        ],
      ),

      // ═══════════════ SLEEP & WAKE ═══════════════
      DuaCategory(
        categoryId: "sleep",
        title: "SLEEP & WAKE",
        icon: "🌙",
        subCategories: [
          SubCategory(id: "before_sleeping", title: "Before Sleeping", icon: "🛏️", duas: [
            Dua(arabic: "بِاسْـمِكَ اللَّهُـمَّ أَمـوتُ وَأَحْـيا", transliteration: "Bismikal-lahumma amootu wa-ahya", translation: "In Your name O Allah, I live and die.", reference: "Al-Bukhari 11/113"),
            Dua(arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ", transliteration: "Allahumma qinee 'athabaka yawma tab'athu 'ibadak", translation: "O Allah, protect me from Your punishment on the day Your servants are resurrected.", reference: "Abu Dawud 4/311"),
            Dua(arabic: "اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا لَكَ مَمَاتُهَا وَمَحْيَاهَا إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ", transliteration: "Allahumma innaka khalaqta nafsee wa-anta tawaffaha, laka mamatuha wa-mahyaha in ahyaytaha fahfathha wa-in amattaha faghfir laha, allahuma innee as'alukal-'afiyah", translation: "O Allah, verily You have created my soul and You shall take its life. To You belongs its life and death. If You should keep my soul alive then protect it, and if You should take its life then forgive it. O Allah, I ask You for well-being.", reference: "Muslim 4/2083"),
          ]),
          SubCategory(id: "waking_up", title: "Upon Waking Up", icon: "🥱", duas: [
            Dua(arabic: "الْحَمْدُ للهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ", transliteration: "Alhamdu lillahil-lathee ahyana ba'da ma amatana wa-ilayhin-nushoor", translation: "All praise is to Allah Who has given us life after having caused us to die, and unto Him is the resurrection.", reference: "Al-Bukhari 11/113"),
            Dua(arabic: "لَا إِلٰهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", transliteration: "La ilaha illallahu wahdahu la shareeka lahu, lahul-mulku walahul-hamdu wahuwa 'ala kulli shay-in qadeer", translation: "None has the right to be worshipped except Allah alone, with no partner. His is the sovereignty and His is the praise, and He is Able to do all things.", reference: "Al-Bukhari"),
          ]),
        ],
      ),

      // ═══════════════ PRAYER RELATED ═══════════════
      DuaCategory(
        categoryId: "prayer",
        title: "PRAYER RELATED",
        icon: "🕌",
        subCategories: [
          SubCategory(id: "before_wudu", title: "Before Wudu", icon: "💧", duas: [
            Dua(arabic: "بِسْمِ اللَّهِ", transliteration: "Bismillah", translation: "In the Name of Allah.", reference: "Abu Dawud"),
          ]),
          SubCategory(id: "after_wudu", title: "After Wudu", icon: "✨", duas: [
            Dua(arabic: "أَشْهَدُ أَنْ لا إِلَـهَ إِلاّ اللهُ وَحْدَهُ لا شَريـكَ لَـهُ وَأَشْهَدُ أَنَّ مُحَمّـداً عَبْـدُهُ وَرَسـولُـه", transliteration: "Ashhadu an la ilaha illallahu wahdahu la shareeka lah, wa-ashhadu anna Muhammadan 'abduhu warasooluh", translation: "I bear witness that none has the right to be worshipped but Allah alone, Who has no partner; and I bear witness that Muhammad is His slave and His Messenger.", reference: "Muslim 1/209"),
            Dua(arabic: "اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ", transliteration: "Allahummaj'alnee minat-tawwabeena waj'alnee minal-mutatahhireen", translation: "O Allah, make me among those who repent and make me among those who purify themselves.", reference: "At-Tirmidhi 1/78"),
          ]),
          SubCategory(id: "entering_mosque", title: "Entering Mosque", icon: "🚶", duas: [
            Dua(arabic: "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ", transliteration: "Allahummaf-tah lee abwaba rahmatik", translation: "O Allah, open for me the gates of Your mercy.", reference: "Muslim 1/494"),
          ]),
          SubCategory(id: "leaving_mosque", title: "Leaving Mosque", icon: "🚪", duas: [
            Dua(arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ", transliteration: "Allahumma innee as'aluka min fadlik", translation: "O Allah, I ask You from Your bounty.", reference: "Muslim 1/494"),
          ]),
          SubCategory(id: "after_salah", title: "After Salah", icon: "🤲", duas: [
            Dua(arabic: "أَسْتَغْفِرُ اللَّهَ (ثَلاَثَاً) اللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ تَبَارَكْتَ يَا ذَا الْجَلاَلِ وَالإِكْرَامِ", transliteration: "Astaghfirullah (3x). Allahumma Antas-Salamu wa minkas-salam, tabarakta ya dhal-Jalali wal-Ikram", translation: "I seek the forgiveness of Allah (3 times). O Allah, You are Peace and from You comes peace. Blessed are You O Owner of Majesty and Honour.", reference: "Muslim 1/414"),
            Dua(arabic: "لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", transliteration: "La ilaha illallahu wahdahu la shareeka lahu, lahul-mulku walahul-hamdu, wahuwa 'ala kulli shay-in qadeer", translation: "None has the right to be worshipped but Allah alone, with no partner. His is the sovereignty and His is the praise and He is Able to do all things.", reference: "Al-Bukhari 1/255, Muslim 1/414"),
          ]),
          SubCategory(id: "istikhara", title: "Istikhara (Guidance)", icon: "🧭", duas: [
            Dua(arabic: "اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ فَإِنَّكَ تَقْدِرُ وَلاَ أَقْدِرُ وَتَعْلَمُ وَلاَ أَعْلَمُ وَأَنْتَ عَلاَّمُ الْغُيُوبِ", transliteration: "Allahumma innee astakheeruka bi'ilmika wa-astaqdiruka biqudratika wa-as'aluka min fadlikal-'atheem, fa-innaka taqdiru wa la aqdiru wa ta'lamu wa la a'lamu wa anta 'allamul-ghuyoob", translation: "O Allah, I seek Your guidance by virtue of Your knowledge, and I seek ability by virtue of Your power, and I ask You of Your great bounty. You have power, I have none. And You know, I know not. You are the Knower of hidden things.", reference: "Al-Bukhari 7/162"),
          ]),
        ],
      ),

      // ═══════════════ EATING & DAILY HABITS ═══════════════
      DuaCategory(
        categoryId: "eating",
        title: "EATING & DAILY HABITS",
        icon: "🍽️",
        subCategories: [
          SubCategory(id: "before_eating", title: "Before Eating", icon: "🍴", duas: [
            Dua(arabic: "بِسْمِ اللَّهِ", transliteration: "Bismillah", translation: "In the name of Allah.", reference: "Abu Dawud"),
            Dua(arabic: "بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ", transliteration: "Bismillahi wa 'ala barakatillah", translation: "In the name of Allah and with the blessings of Allah.", reference: "Abu Dawud"),
          ]),
          SubCategory(id: "after_eating", title: "After Eating", icon: "😋", duas: [
            Dua(arabic: "الْحَمْـدُ للهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْـرِ حَوْلٍ مِنِّي وَلاَ قُوَّةٍ", transliteration: "Alhamdu lillahil-lathee at'amanee hatha warazaqaneehi min ghayri hawlin minnee wala quwwah", translation: "Praise is to Allah Who has fed me this and provided it for me without any might nor power from myself.", reference: "At-Tirmidhi"),
          ]),
          SubCategory(id: "drinking", title: "Drinking Water / Milk", icon: "🥛", duas: [
            Dua(arabic: "اللَّهُمَّ بَارِكْ لَنَا فِيهِ وَزِدْنَا مِنْهُ", transliteration: "Allahumma barik lana feehi wa zidna minhu", translation: "O Allah, bless us in it and give us more of it.", reference: "At-Tirmidhi"),
          ]),
          SubCategory(id: "wearing_clothes", title: "Wearing Clothes", icon: "👕", duas: [
            Dua(arabic: "الْحَمْدُ للهِ الَّذِي كَسَانِي هَذَا الثَّوْبَ وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلاَ قُوَّةٍ", transliteration: "Alhamdu lillahil-lathee kasanee hatha aththawba wa razaqaneehi min ghayri hawlin minnee wa la quwwah", translation: "Praise is to Allah Who has clothed me with this garment and provided it for me, with no power or might from myself.", reference: "Abu Dawud, At-Tirmidhi"),
          ]),
          SubCategory(id: "new_clothes", title: "Wearing New Clothes", icon: "✨", duas: [
            Dua(arabic: "اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ", transliteration: "Allahumma lakal-hamdu anta kasawtaneehi, as'aluka min khayrihi wa khayri ma suni'a lahu, wa a'oothu bika min sharrihi wa sharri ma suni'a lahu", translation: "O Allah, for You is all praise. You have clothed me with it. I ask You for the good of it and the good for which it was made, and I seek refuge with You from the evil of it and the evil for which it was made.", reference: "Abu Dawud, At-Tirmidhi"),
          ]),
        ],
      ),

      // ═══════════════ HOME & BATHROOM ═══════════════
      DuaCategory(
        categoryId: "home",
        title: "HOME & BATHROOM",
        icon: "🏠",
        subCategories: [
          SubCategory(id: "entering_home", title: "Entering Home", icon: "🚪", duas: [
            Dua(arabic: "بِسْمِ اللهِ وَلَجْنَا، وَبِسْمِ اللهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا", transliteration: "Bismillahi walajna, wa-bismillahi kharajna, wa-'ala rabbina tawakkalna", translation: "In the Name of Allah we enter, in the Name of Allah we leave, and upon our Lord we depend.", reference: "Abu Dawud"),
          ]),
          SubCategory(id: "leaving_home", title: "Leaving Home", icon: "🚶", duas: [
            Dua(arabic: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ", transliteration: "Bismillah, tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah", translation: "In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.", reference: "Abu Dawud 4/325, At-Tirmidhi 5/490"),
          ]),
          SubCategory(id: "entering_toilet", title: "Entering Toilet", icon: "🚻", duas: [
            Dua(arabic: "بِسْمِ اللَّهِ ، اللَّهُـمَّ إِنِّي أَعُـوذُ بِـكَ مِـنَ الْخُـبْثِ وَالْخَبَائِثِ", transliteration: "Bismillah. Allahumma innee a'oothu bika minal-khubthi wal-khaba-ith", translation: "In the Name of Allah. O Allah, I seek protection in You from the male and female unclean spirits.", reference: "Al-Bukhari 1/45"),
          ]),
          SubCategory(id: "leaving_toilet", title: "Leaving Toilet", icon: "🧼", duas: [
            Dua(arabic: "غُفْـرَانَكَ", transliteration: "Ghufranaka", translation: "I ask You (Allah) for forgiveness.", reference: "Abu Dawud"),
          ]),
        ],
      ),

      // ═══════════════ PERSONAL LIFE & EMOTIONS ═══════════════
      DuaCategory(
        categoryId: "emotions",
        title: "PERSONAL LIFE & EMOTIONS",
        icon: "🧍",
        subCategories: [
          SubCategory(id: "anxiety", title: "Anxiety / Stress", icon: "😔", duas: [
            Dua(arabic: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ", transliteration: "Allahumma innee a'oothu bika minal-hammi walhazan, wa-a'oothu bika minal-'ajzi walkasali, wa-a'oothu bika minal-jubni walbukhli, wa-a'oothu bika min ghalabatid-dayni wa qahrir-rijal", translation: "O Allah, I seek refuge in You from worry and grief, from helplessness and laziness, from cowardice and stinginess, and from overpowering of debt and oppression of men.", reference: "Al-Bukhari 7/158"),
            Dua(arabic: "لَا إِلَهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", transliteration: "La ilaha illa anta subhanaka innee kuntu minadh-dhalimeen", translation: "None has the right to be worshipped but You O Allah, far removed are You from every imperfection, I was indeed from the wrongdoers.", reference: "At-Tirmidhi — Dua of Yunus (AS)"),
          ]),
          SubCategory(id: "sadness", title: "Sadness", icon: "😢", duas: [
            Dua(arabic: "اللَّهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ وَأَصْلِحْ لِي شَأْنِي كُلَّهُ لَا إِلَهَ إِلَّا أَنْتَ", transliteration: "Allahumma rahmataka arjoo fala takilnee ila nafsee tarfata 'aynin wa-aslih lee sha'nee kullahu la ilaha illa anta", translation: "O Allah, it is Your mercy that I hope for, so do not leave me in charge of my affairs even for a blink of an eye, and rectify for me all of my affairs. None has the right to be worshipped except You.", reference: "Abu Dawud 4/324"),
          ]),
          SubCategory(id: "anger", title: "Anger", icon: "😠", duas: [
            Dua(arabic: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ", transliteration: "A'oothu billahi minash-shaytanir-rajeem", translation: "I seek refuge in Allah from the accursed devil.", reference: "Al-Bukhari, Muslim"),
          ]),
          SubCategory(id: "forgiveness", title: "Seeking Forgiveness", icon: "🤲", duas: [
            Dua(arabic: "أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ", transliteration: "Astaghfirullahal-lathee la ilaha illa huwal-hayyul-qayyoomu wa-atoobu ilayh", translation: "I seek the forgiveness of Allah — the One besides Whom there is no true god, the Ever-Living, the Self-Sustaining — and I repent to Him.", reference: "Abu Dawud, At-Tirmidhi"),
            Dua(arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ", transliteration: "Allahumma anta rabbee la ilaha illa anta, khalaqtanee wa-ana 'abduka, wa-ana 'ala 'ahdika wa wa'dika mastata'tu, a'oothu bika min sharri ma sana'tu, aboo-u laka bini'matika 'alayya, wa-aboo-u bithanbee, faghfir lee fa-innahu la yaghfiruth-thunooba illa anta", translation: "O Allah, You are my Lord. There is no god but You. You created me, and I am Your servant. I am keeping my promise and covenant to You as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessings upon me, and I acknowledge my sins, so forgive me. Indeed, none can forgive sins except You.", reference: "Al-Bukhari 7/150 — Sayyidul Istighfar"),
          ]),
          SubCategory(id: "gratitude", title: "Gratitude (Shukr)", icon: "✨", duas: [
            Dua(arabic: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", transliteration: "Allahumma a'innee 'ala dhikrika wa shukrika wa husni 'ibadatik", translation: "O Allah, help me to remember You, to thank You, and to worship You in the best of manners.", reference: "Abu Dawud 2/86"),
          ]),
        ],
      ),

      // ═══════════════ TRAVEL & MOVEMENT ═══════════════
      DuaCategory(
        categoryId: "travel",
        title: "TRAVEL & MOVEMENT",
        icon: "🧳",
        subCategories: [
          SubCategory(id: "starting_journey", title: "Starting Journey", icon: "🚗", duas: [
            Dua(arabic: "اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى وَمِنَ الْعَمَلِ مَا تَرْضَى", transliteration: "Allahumma inna nas'aluka fee safarinal-birra wat-taqwa, wa minal-'amali ma tarda", translation: "O Allah, we ask You during this journey of ours for righteousness, piety, and deeds that please You.", reference: "Muslim 2/978"),
          ]),
          SubCategory(id: "boarding_vehicle", title: "Boarding Vehicle", icon: "✈️", duas: [
            Dua(arabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنقَلِبُونَ", transliteration: "Subhanal-lathee sakhkhara lana hatha wama kunna lahu muqrineen, wa-inna ila rabbina lamunqaliboon", translation: "Glory be to the One Who has placed this transport at our service, and we ourselves would not have been capable of that, and to our Lord is our final destiny.", reference: "Az-Zukhruf 43:13-14"),
          ]),
          SubCategory(id: "returning_home", title: "Returning Home", icon: "🏠", duas: [
            Dua(arabic: "آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ", transliteration: "Ayiboona, ta-iboona, 'abidoona, lirabbina hamidoon", translation: "We return, repent, worship, and praise our Lord.", reference: "Muslim 2/980"),
          ]),
        ],
      ),

      // ═══════════════ HEALTH & ILLNESS ═══════════════
      DuaCategory(
        categoryId: "health",
        title: "HEALTH & ILLNESS",
        icon: "🏥",
        subCategories: [
          SubCategory(id: "when_ill", title: "When Ill", icon: "🤒", duas: [
            Dua(arabic: "اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَاسَ اشْفِهِ وَأَنْتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا", transliteration: "Allahumma rabban-nasi, adh-hibil-ba's, ishfihi wa-antash-shafee, la shifa'a illa shifa'uka, shifa'an la yughadiru saqama", translation: "O Allah, Lord of the people, remove the disease, cure him, for You are the one who cures. There is no cure except Your cure, a cure that leaves behind no ailment.", reference: "Al-Bukhari 7/131, Muslim 4/1721"),
          ]),
          SubCategory(id: "visiting_sick", title: "Visiting the Sick", icon: "💐", duas: [
            Dua(arabic: "لاَ بَأْسَ طَهُورٌ إِنْ شَاءَ اللَّهُ", transliteration: "La ba'sa, tahoorun insha-allah", translation: "No worry, it is a purification, if Allah wills.", reference: "Al-Bukhari 7/118"),
            Dua(arabic: "أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ", transliteration: "As'alullahal-'atheema rabbal-'arshil-'atheemi an yashfiyak", translation: "I ask Allah the Almighty, the Lord of the Mighty Throne, to cure you.", reference: "At-Tirmidhi, Abu Dawud — said 7 times"),
          ]),
        ],
      ),

      // ═══════════════ PROTECTION & SAFETY ═══════════════
      DuaCategory(
        categoryId: "protection",
        title: "PROTECTION & SAFETY",
        icon: "🛡️",
        subCategories: [
          SubCategory(id: "evil_eye", title: "From Evil Eye", icon: "🧿", duas: [
            Dua(arabic: "أُعِيذُكَ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ", transliteration: "U'eethuka bikalimatil-lahit-tammati min kulli shaytanin wa hamma wa min kulli 'aynin lammah", translation: "I seek refuge for you in the perfect words of Allah from every devil and every poisonous creature, and from every evil eye.", reference: "Al-Bukhari"),
          ]),
          SubCategory(id: "shaitan", title: "From Shaitan", icon: "👿", duas: [
            Dua(arabic: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ", transliteration: "A'oothu billahi minash-shaytanir-rajeem", translation: "I seek refuge in Allah from the accursed devil.", reference: "Al-Bukhari, Muslim"),
            Dua(arabic: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", transliteration: "Bismillahil-lathee la yadurru ma'asmihi shay'un fil-ardi wa la fis-sama'i wa huwas-samee'ul-'aleem", translation: "In the Name of Allah, with Whose Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.", reference: "Abu Dawud 4/323, At-Tirmidhi — 3 times morning & evening"),
          ]),
        ],
      ),

      // ═══════════════ SPECIAL WORSHIP ═══════════════
      DuaCategory(
        categoryId: "worship",
        title: "SPECIAL WORSHIP",
        icon: "📿",
        subCategories: [
          SubCategory(id: "breaking_fast", title: "Breaking Fast (Iftar)", icon: "🍽️", duas: [
            Dua(arabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ", transliteration: "Dhahaba adh-dham'a wa-abtallatil-'urooq wa thabatal-ajru insha-allah", translation: "The thirst has gone, the veins are moistened, and the reward is confirmed, if Allah wills.", reference: "Abu Dawud 2/306"),
          ]),
          SubCategory(id: "laylatul_qadr", title: "Laylatul Qadr", icon: "✨", duas: [
            Dua(arabic: "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي", transliteration: "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'annee", translation: "O Allah, You are the One Who pardons greatly, and loves to pardon, so pardon me.", reference: "At-Tirmidhi, Ibn Majah"),
          ]),
          SubCategory(id: "hajj_umrah", title: "During Hajj/Umrah", icon: "🕋", duas: [
            Dua(arabic: "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ لَا شَرِيكَ لَكَ", transliteration: "Labbayk Allahumma labbayk, labbayka la shareeka laka labbayk, innal-hamda wan-ni'mata laka wal-mulk, la shareeka lak", translation: "Here I am O Allah, here I am. Here I am, You have no partner, here I am. Verily all praise, grace and sovereignty belong to You. You have no partner.", reference: "Al-Bukhari, Muslim"),
          ]),
        ],
      ),

      // ═══════════════ KNOWLEDGE & LEARNING ═══════════════
      DuaCategory(
        categoryId: "knowledge",
        title: "KNOWLEDGE & LEARNING",
        icon: "🧠",
        subCategories: [
          SubCategory(id: "before_studying", title: "Before Studying", icon: "📚", duas: [
            Dua(arabic: "اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي وَزِدْنِي عِلْمًا", transliteration: "Allahumma-nfa'nee bima 'allamtanee wa 'allimnee ma yanfa'unee wa zidnee 'ilma", translation: "O Allah, benefit me from what You have taught me, and teach me that which will benefit me, and increase me in knowledge.", reference: "At-Tirmidhi, Ibn Majah"),
          ]),
          SubCategory(id: "increasing_knowledge", title: "Increasing Knowledge", icon: "🎓", duas: [
            Dua(arabic: "رَبِّ زِدْنِي عِلْمًا", transliteration: "Rabbi zidnee 'ilma", translation: "My Lord, increase me in knowledge.", reference: "Surah Taha 20:114"),
          ]),
        ],
      ),

      // ═══════════════ RELATIONSHIPS ═══════════════
      DuaCategory(
        categoryId: "relationships",
        title: "RELATIONSHIPS",
        icon: "❤️",
        subCategories: [
          SubCategory(id: "parents", title: "For Parents", icon: "👨‍👩‍👧‍👦", duas: [
            Dua(arabic: "رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا", transliteration: "Rabbir-hamhuma kama rabbayani sagheera", translation: "My Lord, have mercy upon them as they brought me up when I was small.", reference: "Surah Al-Isra 17:24"),
          ]),
          SubCategory(id: "marriage", title: "For Spouse / Marriage", icon: "💍", duas: [
            Dua(arabic: "بَارَكَ اللَّهُ لَكَ وَبَارَكَ عَلَيْكَ وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ", transliteration: "Barakallahu laka wa baraka 'alayka wa jama'a baynakuma fee khayr", translation: "May Allah bless you, and shower His blessings upon you, and join you both in goodness.", reference: "Abu Dawud, At-Tirmidhi, Ibn Majah"),
          ]),
        ],
      ),

      // ═══════════════ DIFFICULT SITUATIONS ═══════════════
      DuaCategory(
        categoryId: "difficulties",
        title: "DIFFICULT SITUATIONS",
        icon: "⚔️",
        subCategories: [
          SubCategory(id: "debt", title: "Debt", icon: "💳", duas: [
            Dua(arabic: "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ", transliteration: "Allahummak-finee bihalaalika 'an haraamika wa-aghninee bifadlika 'amman siwaak", translation: "O Allah, suffice me with what You have allowed instead of what You have forbidden, and make me independent of all others besides You.", reference: "At-Tirmidhi 5/560"),
          ]),
          SubCategory(id: "difficulty", title: "General Difficulty", icon: "⛰️", duas: [
            Dua(arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", transliteration: "Hasbunallahu wa ni'mal-wakeel", translation: "Allah is sufficient for us and He is the Best Guardian.", reference: "Al-Bukhari 4/377"),
            Dua(arabic: "إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا", transliteration: "Inna lillahi wa-inna ilayhi raji'oon, Allahumma'-jurnee fee museebatee wa-akhlif lee khayran minha", translation: "We belong to Allah and to Him we shall return. O Allah, recompense me for my affliction and replace it for me with something better.", reference: "Muslim 2/632"),
          ]),
          SubCategory(id: "oppression", title: "Against Oppression", icon: "⛓️", duas: [
            Dua(arabic: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْغَمِّ وَالْحَزَنِ", transliteration: "Allahumma innee a'oothu bika minal-ghammi wal-hazan", translation: "O Allah, I seek refuge in You from sorrow and grief.", reference: "Al-Bukhari"),
          ]),
        ],
      ),

      // ═══════════════ NATURE & ENVIRONMENT ═══════════════
      DuaCategory(
        categoryId: "nature",
        title: "NATURE & ENVIRONMENT",
        icon: "🌧️",
        subCategories: [
          SubCategory(id: "rain", title: "When It Rains", icon: "🌧️", duas: [
            Dua(arabic: "اللَّهُمَّ صَيِّبًا نَافِعًا", transliteration: "Allahumma sayyiban nafi'a", translation: "O Allah, let it be a beneficial rain.", reference: "Al-Bukhari (1032)"),
          ]),
          SubCategory(id: "thunder", title: "During Thunder", icon: "⚡", duas: [
            Dua(arabic: "سُبْحَانَ الَّذِي يُسَبِّحُ الرَّعْدُ بِحَمْدِهِ وَالْمَلَائِكَةُ مِنْ خِيفَتِهِ", transliteration: "Subhanal-lathee yusabbihur-ra'du bihamdihi wal-mala-ikatu min kheefatih", translation: "How perfect He is, (the One) Whom the thunder declares His perfection with His praise, as do the angels out of fear of Him.", reference: "Al-Muwatta 2/992"),
          ]),
          SubCategory(id: "wind", title: "During Strong Wind", icon: "💨", duas: [
            Dua(arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَهَا وَأَعُوذُ بِكَ مِنْ شَرِّهَا", transliteration: "Allahumma innee as'aluka khayraha wa a'oothu bika min sharriha", translation: "O Allah, I ask You for its goodness and I seek refuge with You from its evil.", reference: "Muslim"),
          ]),
          SubCategory(id: "seeing_moon", title: "Seeing New Moon", icon: "🌙", duas: [
            Dua(arabic: "اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْيُمْنِ وَالْإِيمَانِ وَالسَّلَامَةِ وَالْإِسْلَامِ رَبِّي وَرَبُّكَ اللَّهُ", transliteration: "Allahumma ahillahu 'alayna bil-yumni wal-eemani was-salaamati wal-islaam, rabbee wa rabbukallah", translation: "O Allah, let this moon appear on us with security and faith, with safety and Islam. My Lord and your Lord is Allah.", reference: "At-Tirmidhi 5/504, Ad-Darimi 1/336"),
          ]),
        ],
      ),

      // ═══════════════ WORK & RIZQ ═══════════════
      DuaCategory(
        categoryId: "work",
        title: "WORK & RIZQ",
        icon: "💼",
        subCategories: [
          SubCategory(id: "seeking_rizq", title: "Seeking Provision", icon: "💰", duas: [
            Dua(arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا وَاسِعًا وَعَمَلاً مُتَقَبَّلاً", transliteration: "Allahumma innee as'aluka 'ilman naafi'an, wa rizqan waasi'an, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for beneficial knowledge, abundant provision, and accepted deeds.", reference: "Ibn Majah"),
          ]),
          SubCategory(id: "before_work", title: "Before Work/Task", icon: "🏢", duas: [
            Dua(arabic: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", transliteration: "Rabbishrahlee sadree wa yassirlee amree", translation: "My Lord, expand my chest for me and ease my task for me.", reference: "Surah Taha 20:25-26"),
          ]),
        ],
      ),

      // ═══════════════ SOCIAL INTERACTIONS ═══════════════
      DuaCategory(
        categoryId: "social",
        title: "SOCIAL & INTERACTIONS",
        icon: "🤝",
        subCategories: [
          SubCategory(id: "sneezing", title: "After Sneezing", icon: "🤧", duas: [
            Dua(arabic: "الْحَمْدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "All praise is to Allah. (Response: Yarhamukallah — May Allah have mercy on you)", reference: "Al-Bukhari 7/125"),
          ]),
          SubCategory(id: "visiting", title: "Visiting Someone's Home", icon: "👥", duas: [
            Dua(arabic: "اللَّهُمَّ أَطْعِمْ مَنْ أَطْعَمَنِي وَاسْقِ مَنْ سَقَانِي", transliteration: "Allahumma at'im man at'amanee wasqi man saqanee", translation: "O Allah, feed the one who has fed me and quench the thirst of the one who has given me drink.", reference: "Muslim 3/1626"),
          ]),
        ],
      ),
    ];
  }
}
