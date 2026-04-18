import React, { useRef } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  Animated,
  SafeAreaView,
  StatusBar,
  TouchableOpacity,
  SectionList,
  Platform
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { THEME, SHADOWS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { DUA_CATEGORIES } from '../data/duaStore';

export default function DuaCategoriesScreen({ navigate }) {
  const scrollY = useRef(new Animated.Value(0)).current;

  const sections = DUA_CATEGORIES.map(c => ({
    title: c.title,
    icon: c.icon,
    data: c.subCategories
  }));

  const renderSectionHeader = ({ section }) => (
    <View style={styles.sectionHeaderContainer}>
        <Text style={styles.sectionHeaderIcon}>{section.icon}</Text>
        <Text style={styles.sectionHeaderText}>{section.title}</Text>
    </View>
  );

  const renderItem = ({ item }) => {
    const hasDuas = item.duas && item.duas.length > 0;
    
    return (
      <AnimatedScaleButton 
        style={styles.subCatCard}
        onPress={() => navigate('duaList', { subCatId: item.id })}
      >
          <View style={styles.subCatIconBox}>
             <Text style={styles.subCatIcon}>{item.icon}</Text>
          </View>
          <View style={styles.subCatTextContent}>
             <Text style={styles.subCatTitle}>{item.title}</Text>
             <Text style={styles.subCatSubtitle}>
                {hasDuas ? `${item.duas.length} Duas` : 'Empty (Add later)'}
             </Text>
          </View>
          <View style={styles.subCatArrow}>
             <Text style={styles.arrowText}>→</Text>
          </View>
      </AnimatedScaleButton>
    );
  };

  const renderHeroHeader = () => {
    return (
      <View style={styles.headerBlock}>
        <SafeAreaView style={{ backgroundColor: THEME.white, paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }}>
            <View style={styles.topNav}>
                <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('home')} delayPressIn={100}>
                    <Text style={styles.navBtnText}>←</Text>
                </AnimatedScaleButton>
                <View style={styles.navTitleContainer}>
                    <Text style={styles.navTitle}>Hisnul Muslim</Text>
                    <Text style={styles.navSubtitle}>Fortress of the Muslim</Text>
                </View>
                <View style={{ width: 44 }} />
            </View>
        </SafeAreaView>

        <Animated.View style={styles.heroContainer}>
            <LinearGradient 
              colors={['#10B981', '#059669']} 
              style={styles.heroCard}
              start={{x: 0, y: 0}}
              end={{x: 1, y: 1}}
            >
                <View style={styles.heroBadge}>
                    <Text style={styles.heroBadgeText}>DUA LIBRARY</Text>
                </View>
                <Text style={styles.heroTitle}>Categorized Supplications</Text>
                <View style={styles.heroInfoRow}>
                    <Text style={styles.heroInfoText}>100% Offline Essential Duas</Text>
                </View>
            </LinearGradient>
        </Animated.View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      <SectionList
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: false }
        )}
        sections={sections}
        keyExtractor={(item) => item.id}
        renderSectionHeader={renderSectionHeader}
        renderItem={renderItem}
        ListHeaderComponent={renderHeroHeader}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        stickySectionHeadersEnabled={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  listContent: { paddingBottom: 120 },

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
  navTitleContainer: { flex: 1, alignItems: 'center', paddingHorizontal: 16 },
  navTitle: { fontSize: 16, fontWeight: '900', color: THEME.text, textAlign: 'center' },
  navSubtitle: { fontSize: 11, fontWeight: '600', color: '#64748B', marginTop: 1 },

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

  sectionHeaderContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    marginTop: 25,
    marginBottom: 15
  },
  sectionHeaderIcon: { fontSize: 18, marginRight: 10 },
  sectionHeaderText: {
    fontSize: 14,
    fontWeight: '900',
    color: '#94A3B8',
    letterSpacing: 1,
    textTransform: 'uppercase'
  },

  subCatCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 20,
    marginBottom: 12,
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#F1F5F9',
    ...SHADOWS.soft
  },
  subCatIconBox: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: '#10B98115',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16
  },
  subCatIcon: { fontSize: 22 },
  subCatTextContent: { flex: 1 },
  subCatTitle: { fontSize: 16, fontWeight: '800', color: THEME.text, marginBottom: 4 },
  subCatSubtitle: { fontSize: 13, fontWeight: '600', color: '#64748B' },
  subCatArrow: {},
  arrowText: { fontSize: 20, color: '#CBD5E1', fontWeight: '800' }
});
