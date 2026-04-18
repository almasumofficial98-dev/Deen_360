import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Animated,
  FlatList,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { LinearGradient } from 'expo-linear-gradient';
import { THEME, SPACING, SHADOWS, RADIUS, GRADIENTS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { loadSurahList } from '../data/surahList';
import { SurahListSkeleton, ErrorState, EmptyState } from '../components/Skeleton';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width } = Dimensions.get('window');

/**
 * SurahListScreen 2.0: High-Fidelity Quran Listing
 * Features:
 * - Dynamic "Last Read" Hero Card
 * - Playful Staggered Slide-In Animations
 * - Cardless Flat List Design (32px Radii)
 * - Interactive Search Transitions
 * - Advanced Typography & Visual Hierarchy
 */
export default function SurahListScreen({ navigate }) {
  // Logic & Data State
  const [list, setList] = useState([]);
  const [filteredList, setFilteredList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [lastRead, setLastRead] = useState(null);

  // Animation Values
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const headerOpacity = useRef(new Animated.Value(0)).current;
  const listAnims = useRef(new Animated.Value(0)).current;

  // -- DATA LOGIC --
  const fetchData = useMemo(() => async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await loadSurahList();
      setList(data);
      setFilteredList(data);
    } catch (err) {
      setError('Failed to sync Quran list');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    
    // Load last read bookmark
    (async () => {
      try {
        const raw = await AsyncStorage.getItem('deen360_bookmarks');
        const bookmarks = raw ? JSON.parse(raw) : [];
        const latest = Array.isArray(bookmarks) && bookmarks.length > 0 ? bookmarks[bookmarks.length - 1] : null;
        if (latest) setLastRead(latest);
      } catch (e) {}
    })();
  }, [fetchData]);

  useEffect(() => {
    if (!loading && !error && list.length > 0) {
      // Sequence: Header fades in, then List fades and slides
      Animated.sequence([
        Animated.timing(headerOpacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.parallel([
          Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
          Animated.spring(listAnims, { toValue: 1, tension: 20, friction: 7, useNativeDriver: true })
        ])
      ]).start();
    }
  }, [loading, error, list.length]);

  // -- SEARCH LOGIC --
  const handleSearch = (text) => {
    setSearchQuery(text);
    if (!text.trim()) {
      setFilteredList(list);
      return;
    }
    const lowerQuery = text.toLowerCase();
    const filtered = list.filter(
      (s) => s.englishName?.toLowerCase().includes(lowerQuery) || 
             s.name?.toLowerCase().includes(lowerQuery) || 
             String(s.number) === lowerQuery
    );
    setFilteredList(filtered);
  };

  // -- RENDERERS --

  const renderTopHero = () => {
    const heroTranslateY = scrollY.interpolate({
      inputRange: [-100, 0, 100],
      outputRange: [-20, 0, 20],
      extrapolate: 'clamp'
    });

    return (
      <Animated.View style={[styles.heroContainer, { opacity: headerOpacity, transform: [{ translateY: heroTranslateY }] }]}>
        <LinearGradient 
          colors={[THEME.primary, THEME.primaryDark]} 
          style={styles.heroCard}
          start={{x: 0, y: 0}}
          end={{x: 1, y: 1}}
        >
          <View style={styles.heroLeft}>
            <View style={styles.heroBadge}>
               <Text style={styles.heroBadgeText}>LAST READ</Text>
            </View>
            <Text style={styles.heroTitle} numberOfLines={1}>
              {lastRead?.surahName || 'Al-Fatihah'}
            </Text>
            <Text style={styles.heroSubtitle}>Ayah No: {lastRead?.ayah || 1}</Text>
            
            <AnimatedScaleButton 
                style={styles.resumeBtn} 
                onPress={() => navigate('surahContent', lastRead?.surah || 1)}
            >
                <Text style={styles.resumeBtnText}>Resume Reading</Text>
            </AnimatedScaleButton>
          </View>
          <View style={styles.heroIconBox}>
             <Text style={styles.heroIconText}>📖</Text>
          </View>
        </LinearGradient>
      </Animated.View>
    );
  };

  const renderSearchArea = () => (
    <View style={styles.searchArea}>
      <View style={styles.searchBar}>
        <Text style={styles.searchIcon}>⌕</Text>
        <TextInput 
          style={styles.searchInput}
          placeholder="Search Surah name or number..."
          placeholderTextColor="#94A3B8"
          value={searchQuery}
          onChangeText={handleSearch}
        />
        {searchQuery.length > 0 && (
          <TouchableOpacity delayPressIn={100} onPress={() => handleSearch('')}>
            <Text style={styles.clearIcon}>×</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );

  const renderSurahItem = ({ item, index }) => {
    // Staggered slide-in logic based on index (limited to first 20 for performance)
    const staggerDelay = index < 20 ? index * 50 : 0;
    const itemTranslateY = listAnims.interpolate({
      inputRange: [0, 1],
      outputRange: [50 + index * 5, 0],
    });

    return (
      <Animated.View 
        style={[
          styles.itemWrapper, 
          { 
            opacity: fadeAnim, 
            transform: [{ translateY: itemTranslateY }] 
          }
        ]}
      >
        <AnimatedScaleButton 
          style={styles.surahRow}
          onPress={() => navigate('surahContent', item.number)}
        >
          <View style={styles.numberContainer}>
              <Text style={styles.numberText}>{item.number}</Text>
          </View>
          
          <View style={styles.surahMeta}>
              <Text style={styles.surahNameEng} numberOfLines={1}>{item.englishName}</Text>
              <Text style={styles.surahSpecs}>
                 {(item.revelationType || 'Makkah').toUpperCase()} • {item.versesCount || 0} VERSES
              </Text>
          </View>

          <Text style={styles.surahNameAr}>{item.name}</Text>
        </AnimatedScaleButton>
        <View style={styles.rowDivider} />
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      <SafeAreaView style={[styles.headerSafe, { paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }]}>
          <View style={styles.headerNav}>
              <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('home')}>
                  <Text style={styles.navBtnText}>≡</Text>
              </AnimatedScaleButton>
              <Text style={styles.headerTitle}>Noble Quran</Text>
              <View style={{ width: 44 }} />
          </View>
      </SafeAreaView>

      <Animated.FlatList 
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        data={loading || error ? [] : filteredList}
        keyExtractor={(item) => String(item.number)}
        renderItem={renderSurahItem}
        ListHeaderComponent={(
          <View>
            {renderTopHero()}
            {renderSearchArea()}
            <View style={styles.listPreHeader}>
               <Text style={styles.listTitle}>All Surahs</Text>
               <Text style={styles.listCount}>{filteredList.length} Found</Text>
            </View>
          </View>
        )}
        ListEmptyComponent={() => {
          if (loading) return <SurahListSkeleton />;
          if (error) return <ErrorState message={error} onRetry={fetchData} />;
          return <EmptyState title="No Surah found" />;
        }}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        initialNumToRender={15}
        windowSize={5}
        removeClippedSubviews={Platform.OS === 'android'}
      />
    </View>
  );
}

// -- STYLES (High Fidelity) --
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  headerSafe: { backgroundColor: '#FFFFFF' },
  headerNav: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    paddingHorizontal: 20,
    paddingVertical: 10,
  },
  navBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  navBtnText: { fontSize: 22, color: THEME.primary, fontWeight: '800' },
  headerTitle: { fontSize: 20, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },

  listContent: { paddingBottom: 120 },

  // -- Hero --
  heroContainer: { paddingHorizontal: 20, marginTop: 10 },
  heroCard: {
    borderRadius: 32,
    padding: 24,
    flexDirection: 'row',
    alignItems: 'center',
    ...SHADOWS.premium,
  },
  heroLeft: { flex: 1 },
  heroBadge: { 
    backgroundColor: 'rgba(255,255,255,0.2)', 
    paddingHorizontal: 10, 
    paddingVertical: 4, 
    borderRadius: 8, 
    alignSelf: 'flex-start' 
  },
  heroBadgeText: { color: 'white', fontSize: 10, fontWeight: '800', letterSpacing: 1 },
  heroTitle: { color: 'white', fontSize: 24, fontWeight: '900', marginTop: 12, letterSpacing: -0.5 },
  heroSubtitle: { color: 'rgba(255,255,255,0.8)', fontSize: 14, fontWeight: '600', marginTop: 4 },
  resumeBtn: {
    backgroundColor: 'white',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 14,
    alignSelf: 'flex-start',
    marginTop: 20,
  },
  resumeBtnText: { color: THEME.primary, fontWeight: '800', fontSize: 13 },
  heroIconBox: { 
    width: 70, 
    height: 70, 
    borderRadius: 20, 
    backgroundColor: 'rgba(255,255,255,0.15)', 
    justifyContent: 'center', 
    alignItems: 'center' 
  },
  heroIconText: { fontSize: 32 },

  // -- Search --
  searchArea: { paddingHorizontal: 20, marginTop: 24 },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    borderRadius: 20,
    paddingHorizontal: 16,
    height: 56,
  },
  searchIcon: { fontSize: 20, color: '#94A3B8', marginRight: 10 },
  searchInput: { flex: 1, fontSize: 15, fontWeight: '600', color: THEME.text },
  clearIcon: { fontSize: 22, color: '#94A3B8', padding: 4 },

  listPreHeader: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'flex-end', 
    paddingHorizontal: 20, 
    marginTop: 32,
    marginBottom: 16,
  },
  listTitle: { fontSize: 20, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },
  listCount: { fontSize: 12, fontWeight: '700', color: THEME.primary, textTransform: 'uppercase', letterSpacing: 1 },

  // -- Surah Item --
  itemWrapper: { paddingHorizontal: 20 },
  surahRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 18,
    borderRadius: 20,
  },
  numberContainer: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: THEME.primary + '10',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  numberText: { color: THEME.primary, fontWeight: '900', fontSize: 14 },
  surahMeta: { flex: 1 },
  surahNameEng: { fontSize: 17, fontWeight: '800', color: THEME.text, letterSpacing: -0.3 },
  surahSpecs: { fontSize: 11, fontWeight: '700', color: '#64748B', marginTop: 4, letterSpacing: 0.5 },
  surahNameAr: { fontSize: 24, fontWeight: '800', color: THEME.primary, textAlign: 'right' },
  rowDivider: { height: 1.5, backgroundColor: '#F1F5F9', marginLeft: 60 }
});