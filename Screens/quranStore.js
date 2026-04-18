// Lightweight Quran data loader with offline-first caching
import AsyncStorage from '@react-native-async-storage/async-storage';

const BASE = 'https://api.quran.com/api/v4';

export async function loadSurah(surahNumber, language = 'en') {
  const cacheKey = `quran_surah_v2_${surahNumber}_${language}`;
  try {
    const cached = await AsyncStorage.getItem(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
  } catch (e) {
    // ignore cache error
  }

  // Fetch from API (best effort)
  try {
    let allVerses = [];
    let currentPage = 1;
    let totalPages = 1;

    do {
      // Fetch verses with Uthmani script and Sahih International translation (20)
      const res = await fetch(`${BASE}/verses/by_chapter/${surahNumber}?language=${language}&translations=20,131&fields=text_uthmani&per_page=100&page=${currentPage}`);
      if (!res.ok) {
        throw new Error('Network error');
      }

      const json = await res.json();

      // Normalize structure to a simple array of verses
      const verses = (json?.verses || []).map((v) => {
        // Find best translation
        let translationText = '';
        if (v?.translations && v.translations.length > 0) {
          translationText = v.translations[0]?.text || '';
          // remove html tags from translation if any
          translationText = translationText.replace(/<[^>]*>?/gm, '');
        }

        const arabic = v?.text_uthmani || v?.text_imlaei_simple || '';
        return {
          ayah: v?.verse_key || `${surahNumber}:${v.verse_number}`,
          ar: arabic,
          en: translationText,
        };
      });

      allVerses = [...allVerses, ...verses];

      totalPages = json?.pagination?.total_pages || 1;
      currentPage++;
    } while (currentPage <= totalPages);

    if (allVerses.length > 0) {
      await AsyncStorage.setItem(cacheKey, JSON.stringify(allVerses));
      return allVerses;
    }
  } catch (e) {
    console.error('Failed to fetch surah from network:', e);
    // network error; fall back to offline data
  }

  // Offline minimal fallback data (very small sample to keep app usable)
  const fallback = {
    1: [
      { ayah: '1:1', ar: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ', en: 'In the name of Allah, the Most Gracious, the Most Merciful.' },
      { ayah: '1:2', ar: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', en: 'All praise is due to Allah, Lord of all the worlds.' },
    ],
  };
  const list = fallback[surahNumber] || [];
  try {
    await AsyncStorage.setItem(cacheKey, JSON.stringify(list));
  } catch (e) { }
  return list;
}

export async function clearQuranCache() {
  try {
    const keys = await AsyncStorage.getAllKeys();
    const qKeys = keys.filter((k) => k.startsWith('quran_surah_'));
    await AsyncStorage.multiRemove(qKeys);
  } catch (e) {
    // ignore
  }
}
