import React, { useRef, useEffect, useState } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  ScrollView,
  TouchableOpacity, 
  Animated,
  SafeAreaView,
  StatusBar,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { THEME, SPACING, SHADOWS, RADIUS, GRADIENTS } from '../components/theme';
import { HADITH_COLLECTIONS } from '../data/hadithStore';
import { AnimatedScaleButton } from '../components/UI';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width } = Dimensions.get('window');

/**
 * HadithCollectionsScreen 2.0: High-Fidelity Knowledge Hub
 * Features:
 * - Wisdom Hero Widget (Featured Quote)
 * - Playful Category Pill Navigation
 * - Staggered Slide-In Row Animations
 * - Cardless Minimalist Collection List
 * - Micro-interactions (Scale & Bounce)
 */
export default function HadithCollectionsScreen({ navigate }) {
  // Logic State
  const [activeCategory, setActiveCategory] = useState('All');
  
  // Animation Values
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const headerOpacity = useRef(new Animated.Value(0)).current;
  const listAnims = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Sequential Animation: Header -> List
    Animated.sequence([
      Animated.timing(headerOpacity, { toValue: 1, duration: 400, useNativeDriver: true }),
      Animated.parallel([
        Animated.timing(fadeAnim, { toValue: 1, duration: 800, useNativeDriver: true }),
        Animated.spring(listAnims, { toValue: 1, tension: 15, friction: 8, useNativeDriver: true })
      ])
    ]).start();
  }, []);

  const categories = ['All', 'Sahih', 'Sunan', 'Muwatta'];

  const filteredCollections = HADITH_COLLECTIONS.filter(c => {
    if (activeCategory === 'All') return true;
    return c.title.includes(activeCategory);
  });

  const renderHeaderHero = () => {
    const heroTranslateY = scrollY.interpolate({
      inputRange: [-100, 0, 100],
      outputRange: [-20, 0, 20],
      extrapolate: 'clamp'
    });

    return (
      <View style={styles.headerBlock}>
        <SafeAreaView style={{ backgroundColor: THEME.white, paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }}>
            <View style={styles.topNav}>
                <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('home')} delayPressIn={100}>
                    <Text style={styles.navBtnText}>←</Text>
                </AnimatedScaleButton>
                <Text style={styles.navTitle}>Knowledge Hub</Text>
                <AnimatedScaleButton style={styles.navBtn} delayPressIn={100}>
                    <Text style={styles.navBtnText}>❤️</Text>
                </AnimatedScaleButton>
            </View>
        </SafeAreaView>

        <Animated.View style={[styles.heroContainer, { opacity: headerOpacity, transform: [{ translateY: heroTranslateY }] }]}>
            <LinearGradient 
              colors={[THEME.primary, THEME.primaryDark]} 
              style={styles.heroCard}
              start={{x: 0, y: 0}}
              end={{x: 1, y: 1}}
            >
              <View style={styles.heroContent}>
                  <View style={styles.heroBadge}>
                      <Text style={styles.heroBadgeText}>WISDOM OF THE DAY</Text>
                  </View>
                  <Text style={styles.heroQuote} numberOfLines={3}>
                    "The best among you are those who have the best manners and character."
                  </Text>
                  <Text style={styles.heroRef}>Sahih Al-Bukhari</Text>
              </View>
              <View style={styles.heroDecor}>
                  <Text style={styles.decorIcon}>🕊️</Text>
              </View>
            </LinearGradient>
        </Animated.View>

        <View style={styles.categoryRow}>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.categoryScroll}>
                {categories.map((cat) => {
                    const isActive = activeCategory === cat;
                    return (
                        <AnimatedScaleButton 
                            key={cat} 
                            style={[styles.categoryPill, isActive && styles.categoryPillActive]}
                            onPress={() => {
                                LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                                setActiveCategory(cat);
                            }}
                            delayPressIn={100}
                        >
                            <Text style={[styles.categoryText, isActive && styles.categoryTextActive]}>{cat}</Text>
                        </AnimatedScaleButton>
                    );
                })}
            </ScrollView>
        </View>
      </View>
    );
  };

  const renderCollectionItem = ({ item, index }) => {
    const itemSlideY = listAnims.interpolate({
      inputRange: [0, 1],
      outputRange: [40 + index * 10, 0]
    });

    return (
      <Animated.View style={[
        styles.collectionWrapper, 
        { 
          opacity: fadeAnim, 
          transform: [{ translateY: itemSlideY }] 
        }
      ]}>
        <AnimatedScaleButton 
          style={styles.collectionRow}
          onPress={() => navigate('hadithChapters', item)}
          delayPressIn={100}
        >
            <View style={[styles.bookIconBox, { backgroundColor: item.color + '15' }]}>
                <Text style={{ fontSize: 24 }}>📚</Text>
            </View>
            <View style={styles.collectionMeta}>
                <Text style={styles.collectionTitle}>{item.title}</Text>
                <Text style={styles.collectionAuthor}>{item.author}</Text>
                <View style={[styles.typeBadge, { backgroundColor: item.color + '20' }]}>
                    <Text style={[styles.typeBadgeText, { color: item.dark || THEME.primary }]}>
                        {item.title.split(' ')[0]} Verified
                    </Text>
                </View>
            </View>
            <View style={styles.arrowCircle}>
               <Text style={styles.arrowIcon}>→</Text>
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
        data={filteredCollections}
        keyExtractor={(item) => item.id}
        renderItem={renderCollectionItem}
        ListHeaderComponent={renderHeaderHero}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  listContent: { paddingBottom: 100 },

  // -- Header & Nav --
  headerBlock: { backgroundColor: '#FFFFFF', marginBottom: 20 },
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

  // -- Hero --
  heroContainer: { paddingHorizontal: 20, marginTop: 10 },
  heroCard: { 
    borderRadius: 32, 
    padding: 24, 
    flexDirection: 'row', 
    alignItems: 'center', 
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
  heroQuote: { color: 'white', fontSize: 16, fontWeight: '700', marginTop: 16, lineHeight: 24, fontStyle: 'italic' },
  heroRef: { color: 'rgba(255,255,255,0.8)', fontSize: 12, fontWeight: '800', marginTop: 12, textTransform: 'uppercase' },
  heroDecor: { width: 50, height: 50, alignItems: 'center', justifyContent: 'center' },
  decorIcon: { fontSize: 32 },

  // -- Categories --
  categoryRow: { marginTop: 24 },
  categoryScroll: { paddingHorizontal: 20 },
  categoryPill: { 
    paddingHorizontal: 20, 
    paddingVertical: 10, 
    borderRadius: 100, 
    backgroundColor: '#F3F4F6', 
    marginRight: 12 
  },
  categoryPillActive: { backgroundColor: THEME.primary },
  categoryText: { fontSize: 14, fontWeight: '700', color: '#64748B' },
  categoryTextActive: { color: 'white' },

  // -- Collection Items --
  collectionWrapper: { paddingHorizontal: 20 },
  collectionRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 24 },
  bookIconBox: { 
    width: 60, 
    height: 60, 
    borderRadius: 20, 
    justifyContent: 'center', 
    alignItems: 'center', 
    marginRight: 16 
  },
  collectionMeta: { flex: 1 },
  collectionTitle: { fontSize: 18, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },
  collectionAuthor: { fontSize: 14, fontWeight: '600', color: '#64748B', marginTop: 2 },
  typeBadge: { alignSelf: 'flex-start', paddingHorizontal: 8, paddingVertical: 4, borderRadius: 6, marginTop: 8 },
  typeBadgeText: { fontSize: 10, fontWeight: '800', textTransform: 'uppercase' },
  
  arrowCircle: { 
    width: 36, 
    height: 36, 
    borderRadius: 18, 
    backgroundColor: THEME.inputBg, 
    justifyContent: 'center', 
    alignItems: 'center' 
  },
  arrowIcon: { color: THEME.primary, fontSize: 16, fontWeight: '900' },
  divider: { height: 1.5, backgroundColor: '#F1F5F9', marginLeft: 76 }
});