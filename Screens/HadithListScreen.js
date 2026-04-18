import React, { useEffect, useState, useRef, useMemo } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  TouchableOpacity, 
  Animated,
  SafeAreaView,
  StatusBar,
  Alert,
  FlatList,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import ViewShot from 'react-native-view-shot';
import * as Sharing from 'expo-sharing';
import { LinearGradient } from 'expo-linear-gradient';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { THEME, SPACING, SHADOWS, RADIUS, GRADIENTS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { loadHadiths } from '../data/hadithStore';
import { HadithListSkeleton, EmptyState, ErrorState } from '../components/Skeleton';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width, height } = Dimensions.get('window');

/**
 * HadithListScreen 2.0: High-Fidelity Hadith Reading
 * Features:
 * - Dynamic Full-Bleed Chapter Hero
 * - Playful Grade Badges (Premium UI)
 * - Cardless Minimalist Hadith rows
 * - Staggered Entry Animations
 * - Micro-interactions (Bounce/Scale)
 * - Social Ready Sharing (ViewShot)
 */
export default function HadithListScreen({ collection, chapter, navigate }) {
  if (!collection || !chapter) {
    return <ErrorState onRetry={() => navigate('hadiths')} title="Missing Parameters" />;
  }
  // Standardize on the new Emerald Green "Spiritual Roadmap" theme
  const collectionColor = '#10B981';
  const collectionDark = '#059669';

  // Logic & Data State
  const [hadiths, setHadiths] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // Animation Values
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const headerOpacity = useRef(new Animated.Value(0)).current;
  const listAnims = useRef(new Animated.Value(0)).current;
  const viewRefs = useRef({});

  // -- DATA FETCHING --
  const fetchHadiths = useMemo(() => async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await loadHadiths(collection?.id, chapter?.id);
      setHadiths(data);
    } catch (err) {
      setError('Failed to sync Hadith list');
    } finally {
      setLoading(false);
    }
  }, [collection.id, chapter.id]);

  useEffect(() => {
    fetchHadiths();
  }, [fetchHadiths]);

  useEffect(() => {
    if (!loading && !error && hadiths.length > 0) {
      Animated.sequence([
        Animated.timing(headerOpacity, { toValue: 1, duration: 400, useNativeDriver: true }),
        Animated.parallel([
          Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
          Animated.spring(listAnims, { toValue: 1, tension: 15, friction: 8, useNativeDriver: true })
        ])
      ]).start();
    }
  }, [loading, error, hadiths.length]);

  // -- ACTIONS --
  const shareImage = async (index) => {
    try {
       const ref = viewRefs.current[index];
       if (ref && ref.capture) {
          const uri = await ref.capture();
          const isAvailable = await Sharing.isAvailableAsync();
          if (isAvailable) {
             await Sharing.shareAsync(uri);
          }
       }
    } catch (e) {
       Alert.alert('Sharing error', 'Unable to capture this Hadith.');
    }
  };

  const bookmarkHadith = async (hadith) => {
    try {
      const stored = await AsyncStorage.getItem('deen360_bookmarks_hadith') || '[]';
      const bookmarks = JSON.parse(stored);
      bookmarks.push({ 
        id: hadith.id, collection: collection?.id, collectionName: collection?.title,
        chapter: chapter?.id, date: new Date().toISOString()
      });
      await AsyncStorage.setItem('deen360_bookmarks_hadith', JSON.stringify(bookmarks));
      LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
      Alert.alert('Saved', `Hadith ${hadith.id} added to favorites.`);
    } catch(e) {}
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
                <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('hadithChapters', collection)} delayPressIn={100}>
                    <Text style={styles.navBtnText}>←</Text>
                </AnimatedScaleButton>
                <View style={styles.navTitleContainer}>
                    <Text style={styles.navTitle} numberOfLines={1}>{chapter?.title}</Text>
                    <Text style={styles.navSubtitle}>{collection?.title}</Text>
                </View>
                <AnimatedScaleButton style={styles.navBtn} delayPressIn={100}>
                    <Text style={styles.navBtnText}>📤</Text>
                </AnimatedScaleButton>
            </View>
        </SafeAreaView>

        <Animated.View style={[styles.heroContainer, { opacity: headerOpacity, transform: [{ translateY: heroTranslateY }] }]}>
            <LinearGradient 
              colors={[collectionColor, collectionDark]} 
              style={styles.heroCard}
              start={{x: 0, y: 0}}
              end={{x: 1, y: 1}}
            >
                <View style={styles.heroBadge}>
                    <Text style={styles.heroBadgeText}>CHAPTER {chapter?.id}</Text>
                </View>
                <Text style={styles.heroTitle}>{chapter?.title}</Text>
                <View style={styles.heroInfoRow}>
                    <Text style={styles.heroInfoText}>{hadiths.length} Hadiths found</Text>
                </View>
            </LinearGradient>
        </Animated.View>
      </View>
    );
  };

  const renderHadithItem = ({ item, index }) => {
    const itemSlideY = listAnims.interpolate({
      inputRange: [0, 1],
      outputRange: [30 + index * 5, 0]
    });

    return (
      <Animated.View style={[
        styles.hadithWrapper, 
        { 
          opacity: fadeAnim, 
          transform: [{ translateY: itemSlideY }] 
        }
      ]}>
        <ViewShot 
          ref={(r) => { viewRefs.current[index] = r; }}
          options={{ format: 'png', quality: 1.0 }}
          style={{ backgroundColor: THEME.white }}
        >
          <View style={styles.hadithContent}>
              <View style={styles.hadithHeader}>
                  <View style={[styles.hadithBadge, { backgroundColor: '#10B98115' }]}>
                      <Text style={[styles.hadithBadgeText, { color: '#10B981' }]}>HADITH {item.id}</Text>
                  </View>
                  <Text style={styles.collectionLabel}>{collection?.title}</Text>
              </View>

              {item.grades && item.grades.length > 0 && (
                <View style={styles.gradesRow}>
                  {item.grades.map((g, i) => (
                    <View key={i} style={[styles.gradePill, { backgroundColor: '#10B98110' }]}>
                        <Text style={styles.gradeStatus}>{g.grade.toUpperCase()}</Text>
                        <Text style={styles.gradeAuthor}> • {g.name}</Text>
                    </View>
                  ))}
                </View>
              )}

              <Text style={styles.arabicText}>{item.ar}</Text>
              <Text style={styles.translationText}>{item.en}</Text>
          </View>
        </ViewShot>

        <View style={styles.actionRow}>
            <AnimatedScaleButton style={styles.actionBtn} onPress={() => bookmarkHadith(item)} delayPressIn={100}>
                <Text style={styles.actionIcon}>❤️</Text>
                <Text style={styles.actionLabel}>Save</Text>
            </AnimatedScaleButton>
            <AnimatedScaleButton style={styles.actionBtn} onPress={() => shareImage(index)} delayPressIn={100}>
                <Text style={styles.actionIcon}>🔗</Text>
                <Text style={styles.actionLabel}>Share</Text>
            </AnimatedScaleButton>
        </View>
        <View style={styles.divider} />
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      {loading ? (
        <HadithListSkeleton />
      ) : (
        <Animated.FlatList 
          onScroll={Animated.event(
            [{ nativeEvent: { contentOffset: { y: scrollY } } }],
            { useNativeDriver: true }
          )}
          data={loading || error ? [] : hadiths}
          keyExtractor={(item, index) => `h-${item.id}-${index}`}
          renderItem={renderHadithItem}
          ListHeaderComponent={renderHeroHeader}
          ListEmptyComponent={<ErrorState onRetry={fetchHadiths} />}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          initialNumToRender={5}
        />
      )}
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
  navTitleContainer: { flex: 1, alignItems: 'center', paddingHorizontal: 16 },
  navTitle: { fontSize: 16, fontWeight: '900', color: THEME.text, textAlign: 'center' },
  navSubtitle: { fontSize: 11, fontWeight: '600', color: '#64748B', marginTop: 1 },

  // -- Hero --
  heroContainer: { paddingHorizontal: 20, marginTop: 10 },
  heroCard: { 
    borderRadius: 32, 
    padding: 28, 
    ...SHADOWS.premium 
  },
  heroBadge: { 
    backgroundColor: 'rgba(255,255,255,0.2)', 
    paddingHorizontal: 10, 
    paddingVertical: 5, 
    borderRadius: 8, 
    alignSelf: 'flex-start' 
  },
  heroBadgeText: { color: 'white', fontSize: 10, fontWeight: '800', letterSpacing: 1 },
  heroTitle: { color: 'white', fontSize: 24, fontWeight: '900', marginTop: 16, letterSpacing: -0.5, lineHeight: 32 },
  heroInfoRow: { marginTop: 12 },
  heroInfoText: { color: 'rgba(255,255,255,0.7)', fontSize: 13, fontWeight: '700' },

  // -- Hadith Item --
  hadithWrapper: { paddingHorizontal: 20, paddingVertical: 24 },
  hadithContent: { borderRadius: 0 },
  hadithHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  hadithBadge: { 
    paddingHorizontal: 12, 
    paddingVertical: 6, 
    borderRadius: 10, 
    backgroundColor: '#F1F5F9' 
  },
  hadithBadgeText: { fontWeight: '900', fontSize: 13 },
  collectionLabel: { color: '#64748B', fontSize: 12, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1 },
  
  gradesRow: { flexDirection: 'row', flexWrap: 'wrap', marginBottom: 20 },
  gradePill: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    paddingHorizontal: 12, 
    paddingVertical: 6, 
    borderRadius: 100, 
    marginRight: 8, 
    marginBottom: 8 
  },
  gradeStatus: { fontSize: 10, fontWeight: '900', color: '#10B981' },
  gradeAuthor: { fontSize: 10, fontWeight: '600', color: '#64748B' },

  arabicText: { 
    fontSize: 28, 
    color: THEME.arabic, 
    textAlign: 'right', 
    lineHeight: 56, 
    marginBottom: 20 
  },
  translationText: { 
    fontSize: 16, 
    color: '#334155', 
    lineHeight: 28, 
    fontWeight: '500' 
  },

  // -- Actions --
  actionRow: { flexDirection: 'row', justifyContent: 'flex-end', marginTop: 24 },
  actionBtn: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: '#10B98110', 
    paddingHorizontal: 20, 
    paddingVertical: 10, 
    borderRadius: 100, 
    marginLeft: 12 
  },
  actionIcon: { fontSize: 16, marginRight: 8 },
  actionLabel: { fontSize: 14, fontWeight: '800', color: '#10B981' },

  divider: { height: 1.5, backgroundColor: '#F1F5F9', marginTop: 40, marginHorizontal: 10 }
});