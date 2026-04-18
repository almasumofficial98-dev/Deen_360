import React, { useEffect, useState, useRef, useMemo } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  TouchableOpacity,
  Animated,
  SafeAreaView,
  StatusBar,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager,
  TextInput
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { THEME, SPACING, SHADOWS, RADIUS, GRADIENTS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { loadHadithChapters } from '../data/hadithStore';
import { HadithChaptersSkeleton, EmptyState, ErrorState } from '../components/Skeleton';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width, height } = Dimensions.get('window');

/**
 * HadithChaptersScreen 2.0: High-Fidelity Book Browser
 * Features:
 * - Dynamic Full-Bleed Hero (Themed to Collection)
 * - Playful Staggered Row Entries
 * - Integrated Chapter Search
 * - Cardless Minimalist Architecture
 * - Micro-interactions (Bounce & Scale)
 */
export default function HadithChaptersScreen({ collection, navigate }) {
  if (!collection || !collection.id) {
     return <ErrorState onRetry={() => navigate('hadiths')} title="Missing Collection" />;
  }
  const collectionColor = collection?.color || THEME.primary;
  
  // Logic & Data State
  const [chapters, setChapters] = useState([]);
  const [filteredChapters, setFilteredChapters] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');

  // Animation Values
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const headerOpacity = useRef(new Animated.Value(0)).current;
  const listAnims = useRef(new Animated.Value(0)).current;

  // -- DATA FETCHING --
  const fetchChapters = useMemo(() => async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await loadHadithChapters(collection?.id);
      setChapters(data);
      setFilteredChapters(data);
    } catch (err) {
      setError('Failed to load chapters');
    } finally {
      setLoading(false);
    }
  }, [collection.id]);

  useEffect(() => {
    fetchChapters();
  }, [fetchChapters]);

  useEffect(() => {
    if (!loading && !error && chapters.length > 0) {
      // Sequence: Header -> List Slide
      Animated.sequence([
        Animated.timing(headerOpacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.parallel([
          Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
          Animated.spring(listAnims, { toValue: 1, tension: 15, friction: 8, useNativeDriver: true })
        ])
      ]).start();
    }
  }, [loading, error, chapters.length]);

  // -- SEARCH LOGIC --
  const handleSearch = (text) => {
    setSearchQuery(text);
    if (!text.trim()) {
      setFilteredChapters(chapters);
      return;
    }
    const lower = text.toLowerCase();
    const filtered = chapters.filter(c => 
      c.title.toLowerCase().includes(lower) || 
      String(c.id).includes(lower)
    );
    setFilteredChapters(filtered);
  };

  // -- RENDERERS --

  const renderHeroHeader = () => {
    const heroTranslateY = scrollY.interpolate({
      inputRange: [-100, 0, 100],
      outputRange: [-20, 0, 20],
      extrapolate: 'clamp'
    });

    return (
      <View style={styles.headerBlock}>
        <SafeAreaView style={{ backgroundColor: THEME.white, paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }}>
            <View style={styles.topNav}>
                <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('hadiths')} delayPressIn={100}>
                    <Text style={styles.navBtnText}>←</Text>
                </AnimatedScaleButton>
                <View style={styles.navTitleContainer}>
                    <Text style={styles.navTitle}>{collection?.title || 'Collection'}</Text>
                    <Text style={styles.navSubtitle}>{collection?.author || ''}</Text>
                </View>
                <AnimatedScaleButton style={styles.navBtn} delayPressIn={100}>
                    <Text style={styles.navBtnText}>ℹ️</Text>
                </AnimatedScaleButton>
            </View>
        </SafeAreaView>

        <Animated.View style={[styles.heroContainer, { opacity: headerOpacity, transform: [{ translateY: heroTranslateY }] }]}>
            <LinearGradient 
              colors={[collectionColor, THEME.primaryDark]} 
              style={styles.heroCard}
              start={{x: 0, y: 0}}
              end={{x: 1, y: 1}}
            >
              <View style={styles.heroContent}>
                  <View style={styles.heroBadge}>
                      <Text style={styles.heroBadgeText}>FOUNDATION</Text>
                  </View>
                  <Text style={styles.heroTitle}>{collection?.title}</Text>
                  <Text style={styles.heroDesc}>Explore {chapters.length} chapters of authentic knowledge.</Text>
              </View>
            </LinearGradient>
        </Animated.View>

        <View style={styles.searchArea}>
          <View style={styles.searchBar}>
            <Text style={styles.searchIconText}>⌕</Text>
            <TextInput 
              style={styles.searchInput}
              placeholder="Search chapters..."
              placeholderTextColor="#94A3B8"
              value={searchQuery}
              onChangeText={handleSearch}
            />
            {searchQuery.length > 0 && (
              <AnimatedScaleButton onPress={() => handleSearch('')} delayPressIn={100}>
                <Text style={styles.clearIconText}>×</Text>
              </AnimatedScaleButton>
            )}
          </View>
        </View>
      </View>
    );
  };

  const renderChapterItem = ({ item, index }) => {
    const itemSlideY = listAnims.interpolate({
      inputRange: [0, 1],
      outputRange: [30 + index * 5, 0]
    });

    return (
      <Animated.View style={[
        styles.chapterWrapper, 
        { 
          opacity: fadeAnim, 
          transform: [{ translateY: itemSlideY }] 
        }
      ]}>
        <AnimatedScaleButton 
          style={styles.chapterRow}
          onPress={() => navigate('hadithList', { collection, chapter: item })}
          delayPressIn={100}
        >
            <View style={[styles.numberBadge, { backgroundColor: collectionColor + '15' }]}>
                <Text style={[styles.numberText, { color: collectionColor }]}>{item.id}</Text>
            </View>
            <View style={styles.chapterInfo}>
                <Text style={styles.chapterTitle}>{item.title}</Text>
                <Text style={styles.chapterMeta}>Read full hadiths in this chapter</Text>
            </View>
            <View style={styles.arrowCircle}>
               <Text style={[styles.arrowIcon, { color: collectionColor }]}>→</Text>
            </View>
        </AnimatedScaleButton>
        <View style={styles.divider} />
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      <Animated.FlatList 
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        data={filteredChapters}
        keyExtractor={(item) => String(item.id)}
        renderItem={renderChapterItem}
        ListHeaderComponent={renderHeroHeader}
        ListEmptyComponent={() => {
          if (loading) return <HadithChaptersSkeleton />;
          if (error) return <ErrorState onRetry={fetchChapters} />;
          return <EmptyState title="No chapters found" />;
        }}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        initialNumToRender={15}
        windowSize={5}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  listContent: { paddingBottom: 100 },

  // -- Navigation --
  headerBlock: { backgroundColor: '#FFFFFF', marginBottom: 10 },
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
  navBtnText: { fontSize: 20, fontWeight: '800' },
  navTitleContainer: { flex: 1, alignItems: 'center' },
  navTitle: { fontSize: 16, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },
  navSubtitle: { fontSize: 11, fontWeight: '600', color: '#64748B', marginTop: 1 },

  // -- Hero --
  heroContainer: { paddingHorizontal: 20, marginTop: 10 },
  heroCard: { 
    borderRadius: 32, 
    padding: 28, 
    ...SHADOWS.premium 
  },
  heroContent: { flex: 1 },
  heroBadge: { 
    backgroundColor: 'rgba(255,255,255,0.2)', 
    paddingHorizontal: 10, 
    paddingVertical: 5, 
    borderRadius: 8, 
    alignSelf: 'flex-start' 
  },
  heroBadgeText: { color: 'white', fontSize: 10, fontWeight: '800', letterSpacing: 1 },
  heroTitle: { color: 'white', fontSize: 26, fontWeight: '900', marginTop: 16, letterSpacing: -0.5 },
  heroDesc: { color: 'rgba(255,255,255,0.8)', fontSize: 14, fontWeight: '500', marginTop: 8 },

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
  searchIconText: { fontSize: 20, color: '#94A3B8', marginRight: 10 },
  searchInput: { flex: 1, fontSize: 15, fontWeight: '600', color: THEME.text },
  clearIconText: { fontSize: 22, color: '#94A3B8', padding: 4 },

  // -- Chapter Rows --
  chapterWrapper: { paddingHorizontal: 20 },
  chapterRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 24 },
  numberBadge: { 
    width: 48, 
    height: 48, 
    borderRadius: 16, 
    justifyContent: 'center', 
    alignItems: 'center', 
    marginRight: 16 
  },
  numberText: { fontSize: 16, fontWeight: '900' },
  chapterInfo: { flex: 1 },
  chapterTitle: { fontSize: 17, fontWeight: '800', color: THEME.text, letterSpacing: -0.3, lineHeight: 24 },
  chapterMeta: { fontSize: 12, fontWeight: '600', color: '#64748B', marginTop: 4 },
  
  arrowCircle: { 
    width: 32, 
    height: 32, 
    borderRadius: 16, 
    backgroundColor: '#F8FAFC', 
    justifyContent: 'center', 
    alignItems: 'center' 
  },
  arrowIcon: { fontSize: 16, fontWeight: '900' },
  divider: { height: 1.5, backgroundColor: '#F1F5F9', marginLeft: 64 }
});