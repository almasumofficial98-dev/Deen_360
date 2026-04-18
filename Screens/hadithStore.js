import AsyncStorage from '@react-native-async-storage/async-storage';

export const HADITH_COLLECTIONS = [
  { id: 'bukhari', title: 'Sahih al-Bukhari', author: 'Imam al-Bukhari', color: '#f0f9ff', dark: '#0284c7' },
  { id: 'muslim', title: 'Sahih Muslim', author: 'Imam Muslim', color: '#fdf4ff', dark: '#c026d3' },
  { id: 'abudawud', title: 'Sunan Abu Dawud', author: 'Abu Dawud', color: '#f0fdf4', dark: '#16a34a' },
  { id: 'tirmidhi', title: 'Jami at-Tirmidhi', author: 'Al-Tirmidhi', color: '#fffbeb', dark: '#d97706' },
  { id: 'nasai', title: 'Sunan an-Nasai', author: "Al-Nasa'i", color: '#fef2f2', dark: '#dc2626' },
  { id: 'ibnmajah', title: 'Sunan Ibn Majah', author: 'Ibn Majah', color: '#faf5ff', dark: '#9333ea' }
];

// Load Chapters for Collection
export const loadHadithChapters = async (collectionId) => {
   try {
      const res = await fetch(`https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/info.json`);
      if (!res.ok) throw new Error('Failed fetch');
      const data = await res.json();
      
      const sections = data[collectionId]?.metadata?.sections || {};
      
      const chapters = [];
      for (const [key, value] of Object.entries(sections)) {
         if (value && value.trim() !== '') {
            chapters.push({ id: key, title: value });
         }
      }
      return chapters.sort((a,b) => parseInt(a.id) - parseInt(b.id));
   } catch (e) {
      console.error(e);
      return [];
   }
};

// Load Hadiths for Chapter
export const loadHadiths = async (collectionId, chapterId) => {
    const cacheKey = `deen360_hadith_v2_${collectionId}_${chapterId}`;
    try {
        const [enRes, arRes] = await Promise.all([
           fetch(`https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-${collectionId}/sections/${chapterId}.json`),
           fetch(`https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-${collectionId}/sections/${chapterId}.json`)
        ]);
        
        const enData = enRes.ok ? await enRes.json() : { hadiths: [] };
        const arData = arRes.ok ? await arRes.json() : { hadiths: [] };

        const hadiths = [];
        const enHadiths = enData.hadiths || [];
        
        const arMap = {};
        (arData.hadiths || []).forEach(h => {
             arMap[h.hadithnumber] = h.text;
        });

        enHadiths.forEach((h, index) => {
            // Some API text payload has duplicate numbering, fallback to index
            if (!h.text || h.text.trim() === '') return;
            
            hadiths.push({
               id: h.hadithnumber || index,
               en: h.text,
               ar: arMap[h.hadithnumber] || "",
               book: enData.metadata?.name || HADITH_COLLECTIONS.find(c => c.id === collectionId)?.title,
               chapterName: enData.metadata?.section ? enData.metadata.section[chapterId] : '',
               grades: h.grades && h.grades.length > 0 ? h.grades : (
                   (collectionId === 'bukhari') ? [{ grade: "Sahih", name: "Al-Bukhari" }] :
                   (collectionId === 'muslim') ? [{ grade: "Sahih", name: "Muslim" }] : []
               )
            });
        });
        return hadiths;
    } catch(e) {
        console.error(e);
        return [];
    }
};

// Legacy stubs to prevent crashing if components haven't updated yet
export const BUKHARI_TOPICS = [];
export const loadHadithSection = async () => ({ hadiths: [] });
