import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  SafeAreaView, 
  TouchableOpacity, 
  StatusBar,
  Share,
  Platform
} from 'react-native';
import { THEME, SHADOWS } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { getSubCategoryData } from '../data/duaStore';

export default function DuaListScreen({ subCatId, navigate }) {
  const [data, setData] = useState(null);

  useEffect(() => {
    const sub = getSubCategoryData(subCatId);
    if (sub) {
        setData(sub);
    }
  }, [subCatId]);

  const handleShare = async (dua) => {
    try {
      await Share.share({
        message: `${dua.arabic}\n\n${dua.translation}\n\nReference: ${dua.reference}\n\nShared via Deen360`,
      });
    } catch (error) { }
  };

  if (!data) return null;

  const renderHeader = () => (
    <SafeAreaView style={[styles.headerContainer, { paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }]}>
        <View style={styles.topNav}>
            <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('duaCategories')} delayPressIn={100}>
                <Text style={styles.navBtnText}>←</Text>
            </AnimatedScaleButton>
            <View style={styles.navTitleContainer}>
                <Text style={styles.navTitle}>{data.title}</Text>
                <Text style={styles.navSubtitle}>{data.duas.length} Duas • Hisnul Muslim</Text>
            </View>
            <View style={styles.navBtnProxy}>
               <Text style={{fontSize: 24}}>{data.icon}</Text>
            </View>
        </View>
    </SafeAreaView>
  );

  const renderDuaItem = ({ item, index }) => (
    <View style={styles.duaCard}>
        <View style={styles.duaHeader}>
            <View style={styles.badge}>
                <Text style={styles.badgeText}>DUA {index + 1}</Text>
            </View>
            {item.reference && (
                <Text style={styles.reference}>{item.reference}</Text>
            )}
        </View>

        <Text style={styles.arabicText}>{item.arabic}</Text>
        
        <View style={styles.translationBlock}>
            <Text style={styles.transliteration}>{item.transliteration}</Text>
            <Text style={styles.translation}>{item.translation}</Text>
        </View>

        <View style={styles.actionRow}>
            <AnimatedScaleButton 
              style={styles.actionBtn}
              onPress={() => handleShare(item)}
            >
                <Text style={styles.actionIcon}>📤</Text>
                <Text style={styles.actionLabel}>Share</Text>
            </AnimatedScaleButton>
        </View>
    </View>
  );

  const renderEmpty = () => (
      <View style={styles.emptyState}>
          <Text style={{fontSize: 48, marginBottom: 20}}>🤲</Text>
          <Text style={styles.emptyTitle}>No Duas Yet</Text>
          <Text style={styles.emptySub}>We are updating this category soon.</Text>
      </View>
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      {renderHeader()}
      
      <FlatList
        data={data.duas}
        keyExtractor={(_, i) => `dua_${i}`}
        renderItem={renderDuaItem}
        ListEmptyComponent={renderEmpty}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAFA' },
  listContent: { paddingBottom: 120, paddingTop: 10 },

  headerContainer: { backgroundColor: '#FFFFFF', ...SHADOWS.soft, marginBottom: 15, zIndex: 10 },
  topNav: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    paddingHorizontal: 20, 
    paddingBottom: 15,
    paddingTop: 10
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
  navTitle: { fontSize: 18, fontWeight: '900', color: THEME.text, textAlign: 'center' },
  navSubtitle: { fontSize: 12, fontWeight: '600', color: '#10B981', marginTop: 2 },
  navBtnProxy: { width: 44, height: 44, justifyContent: 'center', alignItems: 'center' },

  duaCard: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 16,
    borderRadius: 24,
    padding: 24,
    borderWidth: 1,
    borderColor: '#F1F5F9',
    ...SHADOWS.floating
  },
  duaHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  badge: { 
    backgroundColor: '#10B98115', 
    paddingHorizontal: 12, 
    paddingVertical: 6, 
    borderRadius: 8 
  },
  badgeText: { color: '#10B981', fontSize: 12, fontWeight: '900', letterSpacing: 0.5 },
  reference: { color: '#94A3B8', fontSize: 12, fontWeight: '700' },

  arabicText: { 
    fontSize: 32, 
    color: THEME.arabic, 
    textAlign: 'center', 
    marginBottom: 24,
    lineHeight: 50
  },
  translationBlock: {
    backgroundColor: '#F8FAFC',
    padding: 16,
    borderRadius: 16,
    marginBottom: 20
  },
  transliteration: { 
    fontSize: 15, 
    fontWeight: '800',
    color: THEME.text, 
    marginBottom: 8,
    fontStyle: 'italic',
    lineHeight: 22
  },
  translation: { 
    fontSize: 15, 
    color: '#475569', 
    fontWeight: '500',
    lineHeight: 24
  },
  
  actionRow: { flexDirection: 'row', justifyContent: 'flex-end', marginTop: 5 },
  actionBtn: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: '#10B98110', 
    paddingHorizontal: 16, 
    paddingVertical: 8, 
    borderRadius: 100, 
  },
  actionIcon: { fontSize: 16, marginRight: 6 },
  actionLabel: { fontSize: 14, fontWeight: '800', color: '#10B981' },

  emptyState: { alignItems: 'center', justifyContent: 'center', marginTop: 60, paddingHorizontal: 40 },
  emptyTitle: { fontSize: 20, fontWeight: '900', color: THEME.text, marginBottom: 8 },
  emptySub: { fontSize: 15, color: '#64748B', fontWeight: '500', textAlign: 'center', lineHeight: 22 }
});
