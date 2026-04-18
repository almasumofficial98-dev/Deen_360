import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Animated,
  FlatList,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  Share,
  Alert,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager,
  ActivityIndicator
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Audio } from 'expo-av';
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { LinearGradient } from 'expo-linear-gradient';
import { Feather } from '@expo/vector-icons';
import { THEME, SPACING, SHADOWS, RADIUS, GRADIENTS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { loadSurah } from '../data/quranStore';
import { loadSurahList } from '../data/surahList';
import { AyahListSkeleton, ErrorState, EmptyState } from '../components/Skeleton';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width, height } = Dimensions.get('window');
const DEFAULT_RECITER = 'Alafasy_128kbps';

const pad = (num, size) => {
  let s = String(num);
  while (s.length < size) s = `0${s}`;
  return s;
};

/**
 * SurahScreen 2.0: High-Fidelity Quran Reading Experience
 * Features:
 * - Parallax Header with Bismillah Hero
 * - Cardless Minimalist Ayah Layout
 * - Staggered Slide-In Animations
 * - Playful Audio Highlighting (Scale & Pulse)
 * - Reading Progress Tracker
 * - Quick-Action Floating Overlay
 */
export default function SurahScreen({ surah, navigate }) {
  const surahNumber = typeof surah === 'number' ? surah : surah?.number || 1;

  // -- DATA STATE --
  const [surahMeta, setSurahMeta] = useState(null);
  const [verses, setVerses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [readProgress, setReadProgress] = useState(0);
  const [activeBookmark, setActiveBookmark] = useState(null);
  const [isSharing, setIsSharing] = useState(false);

  // -- PLAYBACK STATE --
  const currentSound = useRef(null);
  const [playingAyah, setPlayingAyah] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);

  // -- ANIMATION & SCROLL VALUES --
  const flatListRef = useRef(null);
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const headerOpacity = useRef(new Animated.Value(0)).current;
  const ayahAnims = useRef(new Animated.Value(0)).current; // For staggered entry

  const surahTitle = surahMeta?.englishName || `Surah ${surahNumber}`;
  const metaLine = `${(surahMeta?.revelationType || 'makkah').toUpperCase()} • ${surahMeta?.versesCount || 0} VERSES`;

  // -- DATA FETCHING --
  const fetchSurah = useMemo(() => async () => {
    setLoading(true);
    setError(null);
    try {
      const [data, list] = await Promise.all([loadSurah(surahNumber, 'en'), loadSurahList()]);
      const meta = Array.isArray(list) ? list.find((s) => s.number === surahNumber) : null;
      setSurahMeta(meta || null);

      const normalized = (Array.isArray(data) ? data : []).map((v, index) => {
        let ayNum = index + 1;
        if (typeof v?.ayah === 'string' && v.ayah.includes(':')) ayNum = parseInt(v.ayah.split(':')[1], 10);
        else if (v?.ayah) ayNum = parseInt(v.ayah, 10);
        return { ayah: ayNum, ar: v?.ar ?? v?.text ?? '', en: v?.en ?? v?.translation ?? '' };
      });

      setVerses(normalized);
    } catch (err) {
      setError('Failed to load noble verses');
    } finally {
      setLoading(false);
    }
  }, [surahNumber]);

  useEffect(() => {
    fetchSurah();
    
    // Load existing bookmark for this surah
    (async () => {
      try {
        const current = await AsyncStorage.getItem('deen360_bookmarks');
        const bookmarks = current ? JSON.parse(current) : [];
        const surahBookmark = bookmarks.find(b => b.surah === surahNumber);
        if (surahBookmark) setActiveBookmark(surahBookmark.ayah);
      } catch (e) {}
    })();

    return () => stopPlayback();
  }, [fetchSurah, surahNumber]);

  useEffect(() => {
    if (!loading && !error && verses.length > 0) {
      Animated.sequence([
        Animated.timing(headerOpacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.parallel([
          Animated.timing(fadeAnim, { toValue: 1, duration: 800, useNativeDriver: true }),
          Animated.spring(ayahAnims, { toValue: 1, tension: 15, friction: 8, useNativeDriver: true })
        ])
      ]).start();

      // Implement Direct Resume Auto-Scroll
      if (surah?.initialAyah) {
        setTimeout(() => {
          try {
            flatListRef.current?.scrollToIndex({ 
               index: surah.initialAyah - 1, 
               animated: true, 
               viewPosition: 0.1 
            });
          } catch (e) {}
        }, 600); // Wait for stagger animations to render initial blocks
      }
    }
  }, [loading, error, verses.length, surah]);

  // -- AUDIO LOGIC --
  const stopPlayback = async () => {
    setPlayingAyah(null);
    setIsPlaying(false);
    if (currentSound.current) {
      await currentSound.current.unloadAsync().catch(() => {});
      currentSound.current = null;
    }
  };

  const playAyah = async (ayahNum) => {
      try {
        if (isPlaying && playingAyah === ayahNum) { await stopPlayback(); return; }
        await stopPlayback();
        setIsPlaying(true);
        setPlayingAyah(ayahNum);
        
        // Ensure robust padding for URL construction
        const s = String(surahNumber).padStart(3, '0');
        const a = String(ayahNum).padStart(3, '0');
        const url = `https://everyayah.com/data/${DEFAULT_RECITER}/${s}${a}.mp3`;
        
        const { sound } = await Audio.Sound.createAsync({ uri: url }, { shouldPlay: true });
        currentSound.current = sound;
        sound.setOnPlaybackStatusUpdate(status => {
          if (status?.didJustFinish) stopPlayback();
        });
      } catch (e) {
        await stopPlayback();
        Alert.alert('Audio error', 'Unable to play this Ayah.');
      }
  };

  // -- ACTIONS --
  const shareAyahText = async (item) => {
    try {
      await Share.share({ message: `${item.ar}\n\n${item.en}\n\n- Quran (${surahTitle || 'Surah'}, Ayah ${item.ayah})` });
    } catch (e) {}
  };

  const shareAyahAudio = async (item) => {
    try {
      setIsSharing(true);
      const s = String(surahNumber).padStart(3, '0');
      const a = String(item.ayah).padStart(3, '0');
      const audioUrl = `https://everyayah.com/data/${DEFAULT_RECITER}/${s}${a}.mp3`;
      
      const fileUri = FileSystem.cacheDirectory + `quran_${s}_${a}.mp3`;
      
      const { uri } = await FileSystem.downloadAsync(audioUrl, fileUri);
      
      if (await Sharing.isAvailableAsync()) {
          await Sharing.shareAsync(uri, {
             mimeType: 'audio/mpeg',
             dialogTitle: `Share Ayah ${item.ayah} Audio`,
             UTI: 'public.mp3'
          });
      } else {
          Alert.alert('Share Unavailable', 'Your device does not support native file sharing.');
      }
    } catch (e) {
       Alert.alert('Share Error', `Failed to fetch or share audio: ${e.message}`);
    } finally {
       setIsSharing(false);
    }
  };

  const bookmarkAyah = async (item) => {
    try {
      const current = await AsyncStorage.getItem('deen360_bookmarks');
      let bookmarks = current ? JSON.parse(current) : [];
      // Remove old bookmark for this Surah
      bookmarks = bookmarks.filter(b => b.surah !== surahNumber);
      // Append new bookmark with total ayah context
      bookmarks.push({ 
        surah: surahNumber, 
        surahName: surahTitle, 
        ayah: item.ayah, 
        totalAyahs: surahMeta?.versesCount || 1,
        date: new Date().toISOString() 
      });
      await AsyncStorage.setItem('deen360_bookmarks', JSON.stringify(bookmarks));
      setActiveBookmark(item.ayah);
      LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
    } catch (e) {}
  };

  // -- SCROLL LISTENER FOR PROGRESS --
  const handleScroll = (event) => {
      const contentHeight = event.nativeEvent.contentSize.height;
      const scrollOffset = event.nativeEvent.contentOffset.y;
      const containerHeight = event.nativeEvent.layoutMeasurement.height;
      const progress = scrollOffset / (contentHeight - containerHeight);
      setReadProgress(Math.max(0, Math.min(progress, 1)));
  };

  // -- RENDERERS --
  const renderHeader = () => {
    const bismillahScale = scrollY.interpolate({
      inputRange: [50, 200],
      outputRange: [1, 0.9],
      extrapolate: 'clamp'
    });

    return (
      <View style={styles.headerBlock}>
        <SafeAreaView style={{ backgroundColor: '#FFFFFF', paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }}>
            <View style={styles.topNav}>
                <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('surahList')} delayPressIn={100}>
                    <Text style={styles.navBtnText}>←</Text>
                </AnimatedScaleButton>
                <View style={styles.headerTitles}>
                    <Text style={styles.headerSurahName}>{surahTitle}</Text>
                    <Text style={styles.headerMeta}>{metaLine}</Text>
                </View>
                <AnimatedScaleButton style={styles.navBtn} delayPressIn={100}>
                    <Text style={styles.navBtnText}>⚙️</Text>
                </AnimatedScaleButton>
            </View>
            <View style={styles.progressTrack}>
                <Animated.View style={[styles.progressFill, { width: `${readProgress * 100}%` }]} />
            </View>
        </SafeAreaView>

        <Animated.View style={[styles.heroSection, { opacity: headerOpacity }]}>
            <LinearGradient 
              colors={[THEME.primary, THEME.primaryDark]} 
              style={styles.heroGradient}
              start={{x: 0, y: 0}}
              end={{x: 1, y: 1}}
            >
              <Animated.View style={{ transform: [{ scale: bismillahScale }] }}>
                  <Text style={styles.heroBismillah}>بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ</Text>
                  <View style={styles.heroDivider} />
                  <Text style={styles.heroInfoText}>Begin in the Name of Allah</Text>
              </Animated.View>
            </LinearGradient>
        </Animated.View>
        
        {isSharing && (
           <View style={styles.sharingOverlay}>
              <ActivityIndicator size="small" color={THEME.primary} />
              <Text style={styles.sharingText}>Preparing Audio...</Text>
           </View>
        )}
      </View>
    );
  };

  const renderAyah = ({ item, index }) => {
    const isPlayingThis = playingAyah === item.ayah;
    const isBismillah = item.ar && item.ar.includes('بِسْمِ ٱللَّهِ') && surahNumber !== 1 && index === 0;
    const arText = isBismillah ? item.ar.replace('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ', '').trim() : item.ar;
    
    // Staggered entry animation
    const itemSlideY = ayahAnims.interpolate({
      inputRange: [0, 1],
      outputRange: [30 + index * 5, 0]
    });

    return (
      <Animated.View style={[
        styles.ayahRow, 
        isPlayingThis && styles.ayahRowActive,
        { opacity: fadeAnim, transform: [{ translateY: itemSlideY }] }
      ]}>
        <View style={styles.ayahHeader}>
            <View style={[styles.ayahBadge, isPlayingThis && styles.ayahBadgeActive]}>
                <Text style={[styles.ayahBadgeText, isPlayingThis && styles.ayahBadgeTextActive]}>{item.ayah}</Text>
            </View>
            <View style={styles.ayahActions}>
                <AnimatedScaleButton style={styles.actionBtn} onPress={() => shareAyahText(item)} delayPressIn={100}>
                    <Feather name="share-2" size={16} color={THEME.text} />
                </AnimatedScaleButton>
                <AnimatedScaleButton style={styles.actionBtn} onPress={() => shareAyahAudio(item)} delayPressIn={100}>
                    <Feather name="music" size={16} color={THEME.text} />
                </AnimatedScaleButton>
                <AnimatedScaleButton 
                    style={[styles.actionBtn, isPlayingThis && styles.actionBtnActive]} 
                    onPress={() => playAyah(item.ayah)}
                    delayPressIn={100}
                >
                    <Feather 
                        name={isPlayingThis && isPlaying ? "square" : "play"} 
                        size={16} 
                        color={isPlayingThis ? 'white' : THEME.text} 
                    />
                </AnimatedScaleButton>
                <AnimatedScaleButton 
                    style={[styles.actionBtn, activeBookmark === item.ayah && styles.actionBtnActive]} 
                    onPress={() => bookmarkAyah(item)} 
                    delayPressIn={100}
                >
                    <Feather 
                        name="bookmark" 
                        size={16} 
                        color={activeBookmark === item.ayah ? 'white' : THEME.text} 
                    />
                </AnimatedScaleButton>
            </View>
        </View>

        <Text style={styles.arabicText}>{arText}</Text>
        <Text style={styles.translationText}>{item.en}</Text>
        <View style={styles.rowDivider} />
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      {loading ? (
        <View style={styles.loadingBox}>
          <AyahListSkeleton />
        </View>
      ) : (
        <Animated.FlatList 
          ref={flatListRef}
          onScroll={Animated.event(
            [{ nativeEvent: { contentOffset: { y: scrollY } } }],
            { useNativeDriver: true, listener: handleScroll }
          )}
          data={loading || error ? [] : verses}
          keyExtractor={(item) => `ay-${item.ayah}`}
          renderItem={renderAyah}
          ListHeaderComponent={renderHeader}
          ListEmptyComponent={<ErrorState onRetry={fetchSurah} />}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          initialNumToRender={10}
          windowSize={5}
          onScrollToIndexFailed={(info) => {
            const wait = new Promise(resolve => setTimeout(resolve, 500));
            wait.then(() => {
              flatListRef.current?.scrollToIndex({ index: info.index, animated: true, viewPosition: 0.1 });
            });
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  loadingBox: { flex: 1, backgroundColor: '#FFFFFF' },
  listContent: { paddingBottom: 100 },
  
  // -- Navigation & Progress --
  headerBlock: { backgroundColor: '#FFFFFF', marginBottom: SPACING.lg },
  topNav: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    paddingHorizontal: 20, 
    paddingVertical: 12 
  },
  navBtn: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center'
  },
  navBtnText: { fontSize: 20, color: THEME.text, fontWeight: '800' },
  headerTitles: { flex: 1, alignItems: 'center' },
  headerSurahName: { fontSize: 18, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },
  headerMeta: { fontSize: 11, fontWeight: '700', color: '#64748B', marginTop: 2, textTransform: 'uppercase', letterSpacing: 0.5 },
  
  progressTrack: { height: 4, backgroundColor: '#F1F5F9', width: '100%', position: 'absolute', bottom: 0 },
  progressFill: { height: '100%', backgroundColor: THEME.primary },

  // -- Hero --
  heroSection: { paddingHorizontal: 20, marginTop: 10 },
  heroGradient: { 
    borderRadius: 32, 
    padding: 32, 
    alignItems: 'center', 
    ...SHADOWS.premium 
  },
  heroBismillah: { color: 'white', fontSize: 26, fontWeight: '800', textAlign: 'center', lineHeight: 48 },
  heroDivider: { width: 40, height: 3, backgroundColor: 'rgba(255,255,255,0.3)', marginVertical: 16, borderRadius: 2 },
  heroInfoText: { color: 'rgba(255,255,255,0.8)', fontSize: 12, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 2 },

  // -- Ayah Row --
  ayahRow: { paddingHorizontal: 20, paddingVertical: 24 },
  ayahRowActive: { backgroundColor: THEME.primary + '05' },
  ayahHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  ayahBadge: { 
    width: 40, 
    height: 40, 
    borderRadius: 12, 
    backgroundColor: THEME.inputBg, 
    justifyContent: 'center', 
    alignItems: 'center' 
  },
  ayahBadgeActive: { backgroundColor: THEME.primary },
  ayahBadgeText: { color: THEME.primary, fontWeight: '900', fontSize: 14 },
  ayahBadgeTextActive: { color: 'white' },
  
  ayahActions: { flexDirection: 'row', alignItems: 'center' },
  actionBtn: { 
    width: 40, 
    height: 40, 
    borderRadius: 12, 
    backgroundColor: THEME.inputBg, 
    marginLeft: 12, 
    justifyContent: 'center', 
    alignItems: 'center' 
  },
  actionBtnActive: { backgroundColor: THEME.primary },
  actionIcon: { fontSize: 16, color: THEME.text },
  
  arabicText: { 
    fontSize: 28, 
    color: THEME.arabic, 
    textAlign: 'right', 
    lineHeight: 56, 
    marginBottom: 20, 
    fontWeight: '400' 
  },
  translationText: { 
    fontSize: 16, 
    color: '#334155', 
    lineHeight: 28, 
    fontWeight: '500' 
  },
  rowDivider: { height: 1.5, backgroundColor: '#F1F5F9', marginTop: 32, marginHorizontal: 10 }
});