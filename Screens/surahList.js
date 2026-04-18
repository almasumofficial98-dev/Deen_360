const BASE = 'https://api.quran.com/api/v4';

export async function loadSurahList() {
  try {
    // The Quran.com API v4 chapters endpoint
    const res = await fetch(`${BASE}/chapters?language=en`);
    if (!res.ok) throw new Error('Failed to fetch surah list');
    const json = await res.json();
    console.log('SurahList API response:', json);
    const surahs = (json?.chapters || []).map((s) => ({
      number: s.id,
      englishName: s.name_simple || s.translated_name?.name,
      name: s.name_arabic,
      revelationType: s.revelation_place,
      versesCount: s.verses_count,
    }));
    
    if (surahs.length >= 1) return surahs;
    
    // Fallback minimal list
    return fallbackData();
  } catch (e) {
    console.error('Error fetching surahs:', e);
    return fallbackData();
  }
}

function fallbackData() {
  return Array.from({ length: 114 }).map((_, idx) => ({ 
    number: idx + 1, 
    englishName: `Surah ${idx + 1}`, 
    name: `سورة ${idx + 1}`,
    versesCount: 0,
    revelationType: 'makkah'
  }));
}
