import React, { useEffect, useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Animated,
  SafeAreaView,
  StatusBar,
  Dimensions,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { THEME, SHADOWS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { loadAsmaUlHusna } from '../data/asmaStore';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

/**
 * AsmaScreen: 99 Names of Allah
 * Emerald Green Minimalist Aesthetic
 */
export default function AsmaScreen({ navigate }) {
  const [names, setNames] = useState([]);
  const [loading, setLoading] = useState(true);

  // Animation Values
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const headerOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    let mounted = true;
    const fetchNames = async () => {
      try {
        const data = await loadAsmaUlHusna();
        if (mounted && data) {
          setNames(data);
        }
      } catch (err) {
        console.error("Failed to load names", err);
      } finally {
        if (mounted) {
          setLoading(false);
          Animated.sequence([
            Animated.timing(headerOpacity, { toValue: 1, duration: 400, useNativeDriver: true }),
            Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true })
          ]).start();
        }
      }
    };
    fetchNames();
    return () => { mounted = false; };
  }, []);

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
            <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('home')} delayPressIn={100}>
              <Text style={styles.navBtnText}>←</Text>
            </AnimatedScaleButton>
            <View style={styles.navTitleContainer}>
              <Text style={styles.navTitle} numberOfLines={1}>Asma-Ul-Husna</Text>
              <Text style={styles.navSubtitle}>The 99 Beautiful Names</Text>
            </View>
            <View style={{ width: 44 }} />
          </View>
        </SafeAreaView>

        <Animated.View style={[styles.heroContainer, { opacity: headerOpacity, transform: [{ translateY: heroTranslateY }] }]}>
          <LinearGradient
            colors={['#10B981', '#059669']}
            style={styles.heroCard}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            <View style={styles.heroBadge}>
              <Text style={styles.heroBadgeText}>ALLAH (SWT)</Text>
            </View>
            <Text style={styles.heroTitle}>99 Attributes</Text>

          </LinearGradient>
        </Animated.View>
      </View>
    );
  };

  const renderNameItem = ({ item, index }) => {
    return (
      <Animated.View style={[styles.rowWrapper, { opacity: fadeAnim }]}>
        <View style={styles.contentCard}>
          <View style={styles.rowHeader}>
            <View style={[styles.badge, { backgroundColor: '#10B98115' }]}>
              <Text style={[styles.badgeText, { color: '#10B981' }]}>
                {String(item.number || (index + 1)).padStart(2, '0')}
              </Text>
            </View>
          </View>

          <Text style={styles.arabicText}>{item.name}</Text>

          <View style={styles.englishBlock}>
            <Text style={styles.transliteration}>{item.transliteration}</Text>
            <Text style={styles.meaning}>{item.en?.meaning}</Text>
          </View>
        </View>
        <View style={styles.divider} />
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {loading ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
          <Text style={{ color: '#10B981', fontWeight: '800' }}>Loading...</Text>
        </View>
      ) : (
        <Animated.FlatList
          onScroll={Animated.event(
            [{ nativeEvent: { contentOffset: { y: scrollY } } }],
            { useNativeDriver: true }
          )}
          data={names}
          keyExtractor={(item, index) => `n-${index}`}
          renderItem={renderNameItem}
          ListHeaderComponent={renderHeroHeader}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          initialNumToRender={10}
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

  // -- Items --
  rowWrapper: { paddingHorizontal: 20, paddingTop: 30 },
  contentCard: {},
  rowHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 },
  badge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  badgeText: { fontWeight: '900', fontSize: 13 },

  arabicText: {
    fontSize: 42,
    color: THEME.arabic,
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 60,
  },
  englishBlock: {
    alignItems: 'center'
  },
  transliteration: {
    fontSize: 20,
    fontWeight: '900',
    color: THEME.text,
    marginBottom: 6,
  },
  meaning: {
    fontSize: 15,
    color: '#64748B',
    fontWeight: '600',
    textAlign: 'center'
  },
  divider: { height: 1.5, backgroundColor: '#F1F5F9', marginTop: 40, marginHorizontal: 10 }
});
