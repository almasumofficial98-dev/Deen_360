import React, { useEffect, useState, useRef } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  TouchableOpacity, 
  ActivityIndicator,
  Animated,
  SafeAreaView,
  StatusBar,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { THEME, SHADOWS, RADIUS, SPACING, GRADIENTS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width } = Dimensions.get('window');

/**
 * BookmarksScreen 2.0: High-Fidelity Favorite's Vault
 * Features:
 * - Animated Sliding Tab Navigator
 * - Playful Staggered Row Entries
 * - Cardless Minimalist Favoriting
 * - Unified Delete UX with Bounces
 * - Premium Empty-State Illustration
 */
export default function BookmarksScreen({ navigate }) {
  // Logic & Data State
  const [quranBookmarks, setQuranBookmarks] = useState([]);
  const [hadithBookmarks, setHadithBookmarks] = useState([]);
  const [activeTab, setActiveTab] = useState('quran'); // 'quran' | 'hadith'
  const [loading, setLoading] = useState(true);
  
  // Animation Values
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const listAnims = useRef(new Animated.Value(0)).current;
  const tabSlide = useRef(new Animated.Value(0)).current; // 0 for quran, 1 for hadith

  useEffect(() => {
    let mounted = true;
    const fetchBookmarks = async () => {
      try {
        const [storedQuran, storedHadith] = await Promise.all([
           AsyncStorage.getItem('deen360_bookmarks'),
           AsyncStorage.getItem('deen360_bookmarks_hadith')
        ]);
        
        if (mounted) {
           if (storedQuran) {
             const parsedQ = JSON.parse(storedQuran);
             setQuranBookmarks(parsedQ.sort((a,b) => new Date(b.date) - new Date(a.date)));
           }
           if (storedHadith) {
             const parsedH = JSON.parse(storedHadith);
             setHadithBookmarks(parsedH.sort((a,b) => new Date(b.date) - new Date(a.date)));
           }
        }
      } catch (error) {
        console.error("Error loading bookmarks", error);
      } finally {
        if (mounted) {
          setLoading(false);
          // Initial Entrance Animation
          Animated.parallel([
            Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
            Animated.spring(listAnims, { toValue: 1, tension: 20, friction: 8, useNativeDriver: true })
          ]).start();
        }
      }
    };
    fetchBookmarks();
    return () => { mounted = false; };
  }, []);

  const switchTab = (tab) => {
    if (activeTab === tab) return;
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setActiveTab(tab);
    
    // Animate Tab Slider
    Animated.spring(tabSlide, { toValue: tab === 'quran' ? 0 : 1, useNativeDriver: false, friction: 8 }).start();
    
    // Re-run list animation
    listAnims.setValue(0);
    Animated.spring(listAnims, { toValue: 1, tension: 20, friction: 8, useNativeDriver: true }).start();
  };

  const deleteBookmark = async (index, type) => {
     try {
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        if (type === 'quran') {
           const newBookmarks = [...quranBookmarks];
           newBookmarks.splice(index, 1);
           setQuranBookmarks(newBookmarks);
           await AsyncStorage.setItem('deen360_bookmarks', JSON.stringify(newBookmarks));
        } else {
           const newBookmarks = [...hadithBookmarks];
           newBookmarks.splice(index, 1);
           setHadithBookmarks(newBookmarks);
           await AsyncStorage.setItem('deen360_bookmarks_hadith', JSON.stringify(newBookmarks));
        }
     } catch (e) {}
  };

  // -- RENDERERS --

  const renderTabHeader = () => {
    const slideTranslate = tabSlide.interpolate({
        inputRange: [0, 1],
        outputRange: [0, (width - 40) / 2], // 40 is paddingHorizontal(20) * 2
    });

    return (
      <View style={styles.headerBlock}>
          <SafeAreaView style={{ backgroundColor: THEME.white, paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }}>
              <View style={styles.topNav}>
                  <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('home')} delayPressIn={100}>
                      <Text style={styles.navBtnText}>←</Text>
                  </AnimatedScaleButton>
                  <Text style={styles.navTitle}>Saved Vault</Text>
                  <View style={{ width: 44 }} />
              </View>
          </SafeAreaView>

          <View style={styles.heroSection}>
              <View style={styles.tabContainer}>
                  <Animated.View style={[styles.tabIndicator, { left: slideTranslate }]} />
                  <AnimatedScaleButton style={styles.tabItem} onPress={() => switchTab('quran')} delayPressIn={100}>
                      <Text style={[styles.tabText, activeTab === 'quran' && styles.tabTextActive]}>Quran</Text>
                  </AnimatedScaleButton>
                  <AnimatedScaleButton style={styles.tabItem} onPress={() => switchTab('hadith')} delayPressIn={100}>
                      <Text style={[styles.tabText, activeTab === 'hadith' && styles.tabTextActive]}>Hadith</Text>
                  </AnimatedScaleButton>
              </View>
          </View>
      </View>
    );
  };

  const renderBookmarkItem = ({ item, index }) => {
    const isQuran = activeTab === 'quran';
    const formattedDate = new Date(item.date).toLocaleDateString(undefined, { 
       month: 'short', day: 'numeric' 
    });

    const itemSlideY = listAnims.interpolate({
      inputRange: [0, 1],
      outputRange: [30 + index * 5, 0]
    });

    return (
      <Animated.View style={[
        styles.rowWrapper, 
        { opacity: fadeAnim, transform: [{ translateY: itemSlideY }] }
      ]}>
        <AnimatedScaleButton 
          style={styles.bookmarkRow}
          onPress={() => isQuran 
             ? navigate('surahContent', item.surah)
             : navigate('hadithList', { collection: { id: item.collection, title: item.collectionName }, chapter: { id: item.chapter, title: `Chapter ${item.chapter}` }})
          }
          activeOpacity={0.8}
          delayPressIn={100}
        >
          <View style={[styles.iconBox, { backgroundColor: '#10B98115' }]}>
              <Text style={styles.icon}>{isQuran ? '📖' : '📜'}</Text>
          </View>
          
          <View style={styles.metaInfo}>
              <Text style={styles.title} numberOfLines={1}>
                  {isQuran ? (item.surahName || `Surah ${item.surah}`) : (item.collectionName || `Book ${item.collection}`)}
              </Text>
              <Text style={[styles.sub, { color: '#10B981' }]}>
                  {isQuran ? `Ayah ${item.ayah}` : `Hadith ${item.id} (Ch. ${item.chapter})`}
              </Text>
          </View>

          <View style={styles.rightActions}>
              <Text style={styles.date}>{formattedDate}</Text>
              <TouchableOpacity onPress={() => deleteBookmark(index, activeTab)} style={styles.removeBtn}>
                  <Text style={styles.removeIcon}>×</Text>
              </TouchableOpacity>
          </View>
        </AnimatedScaleButton>
        <View style={styles.divider} />
      </Animated.View>
    );
  };

  const currentData = activeTab === 'quran' ? quranBookmarks : hadithBookmarks;

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      {renderTabHeader()}
      
      <View style={styles.content}>
        {loading ? (
          <View style={styles.loadingBox}>
            <ActivityIndicator size="large" color={THEME.primary} />
            <Text style={styles.loadingTag}>Opening Vault...</Text>
          </View>
        ) : currentData.length === 0 ? (
          <View style={styles.emptyBox}>
              <View style={styles.emptyCircle}>
                  <Text style={styles.emptyIcon}>{activeTab === 'quran' ? '📖' : '📚'}</Text>
              </View>
              <Text style={styles.emptyTitle}>Nothing Here Yet</Text>
              <Text style={styles.emptySub}>
                  {activeTab === 'quran' 
                    ? "Start building your collection by favoriting Ayahs from the Quran reader." 
                    : "Your favorite Hadiths will appear here once you bookmark them."}
              </Text>
              <AnimatedScaleButton style={styles.exploreBtn} onPress={() => navigate(activeTab === 'quran' ? 'surahList' : 'hadiths')}>
                  <Text style={styles.exploreBtnText}>Go Explore</Text>
              </AnimatedScaleButton>
          </View>
        ) : (
          <FlatList
             data={currentData}
             keyExtractor={(item, idx) => `fav-${idx}`}
             renderItem={renderBookmarkItem}
             contentContainerStyle={styles.listContent}
             showsVerticalScrollIndicator={false}
          />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  content: { flex: 1 },
  listContent: { paddingBottom: 100 },

  // -- Header --
  headerBlock: { backgroundColor: '#FFFFFF', paddingBottom: 10 },
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
  navTitle: { fontSize: 18, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },

  heroSection: { paddingHorizontal: 20, marginTop: 10 },
  tabContainer: { 
    flexDirection: 'row', 
    backgroundColor: 'transparent', 
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    padding: 0, 
    height: 56, 
    alignItems: 'center' 
  },
  tabIndicator: { 
    position: 'absolute', 
    bottom: -1, 
    backgroundColor: '#10B981', 
    borderRadius: 3, 
    height: 3,
    width: (width - 40) / 2, 
  },
  tabItem: { flex: 1, alignItems: 'center', justifyContent: 'center', height: '100%' },
  tabText: { fontSize: 15, fontWeight: '700', color: '#94A3B8' },
  tabTextActive: { color: '#10B981', fontWeight: '900' },

  // -- List Items --
  rowWrapper: { paddingHorizontal: 20 },
  bookmarkRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 24 },
  iconBox: { width: 52, height: 52, borderRadius: 16, justifyContent: 'center', alignItems: 'center', marginRight: 16 },
  icon: { fontSize: 22 },
  metaInfo: { flex: 1 },
  title: { fontSize: 17, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },
  sub: { fontSize: 13, fontWeight: '700', marginTop: 3 },
  
  rightActions: { alignItems: 'flex-end' },
  date: { fontSize: 11, color: '#94A3B8', fontWeight: '700' },
  removeBtn: { 
    width: 28, 
    height: 28, 
    borderRadius: 14, 
    backgroundColor: '#F1F5F9', 
    justifyContent: 'center', 
    alignItems: 'center', 
    marginTop: 8 
  },
  removeIcon: { color: '#EF4444', fontSize: 18, fontWeight: '700' },
  divider: { height: 1.5, backgroundColor: '#F1F5F9', marginLeft: 68 },

  // -- Empty State --
  emptyBox: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 40, paddingTop: 40 },
  emptyCircle: { width: 100, height: 100, borderRadius: 50, backgroundColor: '#F8FAFC', justifyContent: 'center', alignItems: 'center', marginBottom: 24 },
  emptyIcon: { fontSize: 48 },
  emptyTitle: { fontSize: 22, fontWeight: '900', color: THEME.text },
  emptySub: { fontSize: 14, fontWeight: '500', color: '#64748B', textAlign: 'center', marginTop: 12, lineHeight: 22 },
  exploreBtn: { backgroundColor: '#10B981', paddingHorizontal: 32, paddingVertical: 14, borderRadius: 100, marginTop: 32, ...SHADOWS.premium },
  exploreBtnText: { color: 'white', fontWeight: '800', fontSize: 15 },

  // -- Loading --
  loadingBox: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingTag: { marginTop: 16, fontWeight: '700', color: THEME.primary }
});
