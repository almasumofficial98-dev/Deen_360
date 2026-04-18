import React, { useState, useEffect } from 'react';
import { 
  SafeAreaView, 
  StyleSheet, 
  Text, 
  View, 
  StatusBar, 
  Platform, 
  LayoutAnimation, 
  UIManager,
  Dimensions
} from 'react-native';
import { THEME, SHADOWS, RADIUS } from './components/theme';
import { AnimatedScaleButton } from './components/UI';
import { Feather } from '@expo/vector-icons';
import HomeScreen from './screens/HomeScreen';
import SurahListScreen from './screens/SurahListScreen';
import SurahScreen from './screens/SurahScreen';
import SalahScreen from './screens/SalahScreen';
import QiblaScreen from './screens/QiblaScreen';
import BookmarksScreen from './screens/BookmarksScreen';
import HadithCollectionsScreen from './screens/HadithCollectionsScreen';
import HadithChaptersScreen from './screens/HadithChaptersScreen';
import HadithListScreen from './screens/HadithListScreen';
import MasjidLocatorScreen from './screens/MasjidLocatorScreen';
import AsmaScreen from './screens/AsmaScreen';
import DuaCategoriesScreen from './screens/DuaCategoriesScreen';
import DuaListScreen from './screens/DuaListScreen';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width } = Dimensions.get('window');

/**
 * Deen360 Premium Root Navigation 2.0
 * Features:
 * - Floating Haptic-Style Bottom Nav
 * - Smooth Cross-Screen Layout Transitions
 * - Unified Design Token usage
 * - Playful Interaction Feedback
 */
export default function App() {
  const [activeTab, setActiveTab] = useState('home');
  const [selectedSurah, setSelectedSurah] = useState(null);
  const [params, setParams] = useState({});

  const navigate = (target, payload) => {
    // Premium Cross-Fade Transition
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    
    if (target === 'surahContent') {
      setSelectedSurah(payload);
      setActiveTab('surahContent');
      return;
    }
    setParams(payload || {});
    setActiveTab(target);
  };

  const handleTabPress = (tabKey) => {
    if (activeTab === tabKey) return;
    LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
    setActiveTab(tabKey);
  };

  const renderScreen = () => {
    switch (activeTab) {
      case 'home': return <HomeScreen navigate={navigate} />;
      case 'bookmarks': return <BookmarksScreen navigate={navigate} />;
      case 'hadiths': return <HadithCollectionsScreen navigate={navigate} />;
      case 'asma': return <AsmaScreen navigate={navigate} />;
      case 'duaCategories': return <DuaCategoriesScreen navigate={navigate} />;
      case 'duaList': return <DuaListScreen subCatId={params?.subCatId} navigate={navigate} />;
      case 'hadithChapters': return <HadithChaptersScreen collection={params} navigate={navigate} />;
      case 'hadithList': return <HadithListScreen collection={params?.collection} chapter={params?.chapter} navigate={navigate} />;
      case 'surahList': return <SurahListScreen navigate={navigate} onSelect={payload => setSelectedSurah(payload)} />;
      case 'surahContent': return selectedSurah ? <SurahScreen surah={selectedSurah} navigate={navigate} /> : <HomeScreen navigate={navigate} />;
      case 'salah': return <SalahScreen navigate={navigate} />;
      case 'qibla': return <QiblaScreen navigate={navigate} />;
      case 'masjidLocator': return <MasjidLocatorScreen navigate={navigate} />;
      default: return <HomeScreen navigate={navigate} />;
    }
  };

  // Define tabs for the persistent floating navigator
  const tabs = [
    { key: 'home', label: 'Home', icon: 'home' },
    { key: 'surahList', label: 'Quran', icon: 'book' },
    { key: 'hadiths', label: 'Hadith', icon: 'server' },
    { key: 'bookmarks', label: 'Saved', icon: 'bookmark' },
  ];

  return (
    <View style={styles.app}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      
      <View style={{ flex: 1 }}>
        {renderScreen()}
      </View>

      {/* Modern Floating Bottom Navigation */}
      <SafeAreaView style={styles.floatingNavContainer} pointerEvents="box-none">
        <View style={[styles.bottomBar, SHADOWS.premium]}>
          {tabs.map((t) => {
            const isActive = activeTab === t.key || (t.key === 'surahList' && activeTab === 'surahContent') || (t.key === 'hadiths' && (activeTab === 'hadithChapters' || activeTab === 'hadithList'));
            
            return (
              <AnimatedScaleButton 
                key={t.key} 
                onPress={() => handleTabPress(t.key)} 
                style={[styles.tabItem, isActive && styles.tabItemActive]}
                activeOpacity={0.8}
              >
                <Feather 
                  name={t.icon} 
                  size={20} 
                  color={isActive ? "#FFFFFF" : "#000000"} 
                  style={!isActive && { opacity: 0.5 }}
                />
                {isActive && (
                  <Text style={styles.tabLabelActive}>{t.label}</Text>
                )}
              </AnimatedScaleButton>
            )
          })}
        </View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  app: { flex: 1, backgroundColor: '#FFFFFF' },
  
  floatingNavContainer: {
    position: 'absolute',
    bottom: 30,
    left: 0,
    right: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  
  bottomBar: {
    height: 72,
    width: width * 0.9,
    backgroundColor: '#FFFFFF',
    borderRadius: 36,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: '#F3F4F6',
    ...SHADOWS.premium,
  },
  
  tabItem: { 
    height: 48,
    alignItems: 'center', 
    justifyContent: 'center', 
    paddingHorizontal: 20,
    borderRadius: 24,
    flexDirection: 'row',
  },

  tabItemActive: {
    backgroundColor: '#000000',
    ...SHADOWS.soft,
  },
  
  tabLabelActive: { 
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '900',
    marginLeft: 10,
  },
});
