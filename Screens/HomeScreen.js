import React, { useEffect, useRef, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Animated,
  SafeAreaView,
  StatusBar,
  Dimensions,
  ImageBackground,
  Platform,
  LayoutAnimation,
  UIManager,
  Share
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { LinearGradient } from 'expo-linear-gradient';
import { Feather } from '@expo/vector-icons';
import { getSalahTimingsByCoordinates, getSalahTimingsByCity, saveUserLocation, getUserLocation } from '../data/salahStore';
import { THEME, SPACING, SHADOWS, RADIUS, GRADIENTS } from '../components/theme';
import { PillButton, FloatingOverlayCard, AnimatedScaleButton } from '../components/UI';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width, height } = Dimensions.get('window');

/**
 * HomeScreen 2.0: High-Fidelity Spiritual Dashboard
 * Features:
 * - Parallax Header Scroll Effects
 * - Atmospheric Mood Themes (Dawn, Noon, Sunset, Night)
 * - Staggered Entry Animations
 * - Micro-interactions (Scaling, Bouncing)
 */
export default function HomeScreen({ navigate }) {
  // Appearance State
  const [atmosphere, setAtmosphere] = useState('Day'); // Dawn, Day, Sunset, Night

  // Data State
  const [locationName, setLocationName] = useState('Fetching...');
  const [salatActive, setSalatActive] = useState('Maghrib');
  const [currentTimeStr, setCurrentTimeStr] = useState('');
  const [fullDate, setFullDate] = useState('');
  // Authentic Salah States
  const [currentBlock, setCurrentBlock] = useState(null);
  const [nextBlock, setNextBlock] = useState(null);
  const [timeRemaining, setTimeRemaining] = useState('--:--:--');
  const [timings, setTimings] = useState(null);
  const [prayerProgress, setPrayerProgress] = useState(0);
  const [temperature, setTemperature] = useState(null);
  const [weatherCondition, setWeatherCondition] = useState('Clear');
  const [weatherEmoji, setWeatherEmoji] = useState('☀️');
  const [lastReadQuran, setLastReadQuran] = useState(null);
  const initialTracker = { Fajr: false, Dhuhr: false, Asr: false, Maghrib: false, Isha: false };
  const [prayerTrackerData, setPrayerTrackerData] = useState(initialTracker);

  // Animation Values
  const scrollY = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const entryAnims = useRef([
    new Animated.Value(0), // Header
    new Animated.Value(0), // Hero
    new Animated.Value(0), // Features
    new Animated.Value(0), // Last Read
  ]).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  /**
   * Determine the visual mood based on the current hour.
   * Dawn: 5am-7am, Day: 7am-5pm, Sunset: 5pm-7pm, Night: 7pm-5am
   */
  const updateAtmosphere = () => {
    const hour = new Date().getHours();
    let newAtmosphere = 'Day';
    if (hour >= 5 && hour < 7) newAtmosphere = 'Dawn';
    else if (hour >= 7 && hour < 17) newAtmosphere = 'Day';
    else if (hour >= 17 && hour < 19) newAtmosphere = 'Sunset';
    else newAtmosphere = 'Night';

    if (newAtmosphere !== atmosphere) {
      LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
      setAtmosphere(newAtmosphere);
    }
  };

  /**
   * Main logic for calculating the next prayer and countdown.
   * Kept robust for premium accuracy.
   */
  const updateTimeLogic = (t = timings) => {
    const now = new Date();

    // 1. Uncouple clock sequence from Network Dependency
    try {
      setCurrentTimeStr(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
      setFullDate(now.toLocaleDateString('en-US', { day: 'numeric', month: 'long', year: 'numeric' }));
    } catch (e) {
      // Android JSC Fallback
      let hrs = now.getHours();
      const mns = String(now.getMinutes()).padStart(2, '0');
      const ampm = hrs >= 12 ? 'PM' : 'AM';
      hrs = hrs % 12 || 12;
      setCurrentTimeStr(`${hrs}:${mns} ${ampm}`);
      setFullDate(now.toDateString());
    }
    updateAtmosphere();

    if (!t) return;

    const parseTime = (timeStr, isTomorrow = false) => {
      const [h, m] = timeStr.split(' ')[0].split(':').map(Number);
      const d = new Date(now);
      d.setHours(h, m, 0, 0);
      if (isTomorrow) d.setDate(d.getDate() + 1);
      return d;
    };

    // Calculate genuine Midnight boundary
    let midnightEnd = parseTime(t.Midnight);
    if (midnightEnd < parseTime(t.Isha)) {
       midnightEnd.setDate(midnightEnd.getDate() + 1);
    }

    // 2. Define the exact block sequence
    const blocks = [
      { name: 'Fajr', start: parseTime(t.Fajr), end: parseTime(t.Sunrise), type: 'Fard' },
      { name: 'Sunrise', start: parseTime(t.Sunrise), end: parseTime(t.Dhuhr), type: 'Prohibited' },
      { name: 'Dhuhr', start: parseTime(t.Dhuhr), end: parseTime(t.Asr), type: 'Fard' },
      { name: 'Asr', start: parseTime(t.Asr), end: parseTime(t.Maghrib), type: 'Fard' },
      { name: 'Maghrib', start: parseTime(t.Maghrib), end: parseTime(t.Isha), type: 'Fard' },
      { name: 'Isha', start: parseTime(t.Isha), end: midnightEnd, type: 'Fard' },
      { name: 'Tahajjud', start: midnightEnd, end: parseTime(t.Fajr, true), type: 'Nafl' }
    ];

    // Handle before-Fajr edge case (it belongs to the previous day's Isha block)
    if (now < blocks[0].start) {
      blocks.unshift({
        name: 'Isha',
        start: parseTime(t.Isha, false),
        end: parseTime(t.Fajr),
        type: 'Fard'
      });
    }

    // 3. Identify active block
    let activeIdx = -1;
    for (let i = 0; i < blocks.length; i++) {
      if (now >= blocks[i].start && now < blocks[i].end) {
        activeIdx = i;
        break;
      }
    }

    if (activeIdx !== -1) {
      const active = blocks[activeIdx];
      const next = blocks[(activeIdx + 1) % blocks.length];

      setCurrentBlock(active);
      setNextBlock(next);
      setSalatActive(active.name);

      // 4. Countdown logic
      let diff = Math.floor((active.end.getTime() - now.getTime()) / 1000);
      const h = Math.floor(diff / 3600);
      const m = Math.floor((diff % 3600) / 60);
      const s = Math.floor(diff % 60);
      setTimeRemaining(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`);
    }
  };

  const fetchWeatherData = async (lat, lng) => {
    try {
      // 10-Minute Throttling / Cache Check
      const lastFetch = await AsyncStorage.getItem('deen360_weather_timestamp');
      const now = Date.now();
      if (lastFetch && (now - parseInt(lastFetch)) < 600000) { // 10 minutes
        const cached = await AsyncStorage.getItem('deen360_weather_cache');
        if (cached) {
          const parsed = JSON.parse(cached);
          setTemperature(parsed.temp);
          setWeatherCondition(parsed.label);
          setWeatherEmoji(parsed.emoji);
          return;
        }
      }

      // Open-Meteo (Production Ready URL)
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current_weather=true&hourly=temperature_2m,precipitation_probability&daily=sunrise,sunset&timezone=auto`;
      const res = await fetch(url);
      const data = await res.json();

      if (data && data.current_weather) {
        const temp = Math.round(data.current_weather.temperature);
        const code = data.current_weather.weathercode;

        // Open-Meteo Weather Mapping
        let label = 'Clear';
        let emoji = '☀️';

        if (code === 0) { label = 'Clear Sky'; emoji = '☀️'; }
        else if (code >= 1 && code <= 3) { label = 'Cloudy'; emoji = '⛅'; }
        else if (code >= 45 && code <= 48) { label = 'Foggy'; emoji = '🌫️'; }
        else if (code >= 51 && code <= 55) { label = 'Drizzle'; emoji = '🌧️'; }
        else if (code >= 61 && code <= 65) { label = 'Rainy'; emoji = '🌧️'; }
        else if (code >= 71 && code <= 75) { label = 'Snow'; emoji = '❄️'; }
        else if (code >= 80 && code <= 82) { label = 'Showers'; emoji = '🌦️'; }
        else if (code >= 95 && code <= 99) { label = 'Storm'; emoji = '⛈️'; }

        setTemperature(temp);
        setWeatherCondition(label);
        setWeatherEmoji(emoji);

        // Save to cache
        await AsyncStorage.setItem('deen360_weather_cache', JSON.stringify({ temp, label, emoji, code }));
        await AsyncStorage.setItem('deen360_weather_timestamp', now.toString());
      }
    } catch (e) {
      console.error("Weather fetch failed", e);
    }
  };

  // Location Fetching (Standard robust implementation)
  const fetchDynamicSalah = async (lat, lng, city = null) => {
    let t = null;
    let locData = { city: null, lat: null, lng: null, name: 'Fetching...' };

    // Fetch Weather alongside Salah timings
    fetchWeatherData(lat, lng);

    if (city) {
      t = await getSalahTimingsByCity(city);
      if (t) {
        setLocationName(city);
        locData = { city, name: city };
        // Geocode city to get coordinates for weather
        try {
          const geocode = await Location.geocodeAsync(city);
          if (geocode && geocode.length > 0) {
            const { latitude, longitude } = geocode[0];
            fetchWeatherData(latitude, longitude);
            locData.lat = latitude;
            locData.lng = longitude;
          }
        } catch (e) { }
      }
    } else {
      t = await getSalahTimingsByCoordinates(lat, lng);
      let displayName = 'Current Location';
      try {
        const geocode = await Location.reverseGeocodeAsync({ latitude: lat, longitude: lng });
        if (geocode && geocode.length > 0) {
          const g = geocode[0];
          const resolvedCity = g.city || g.subregion || g.region;
          if (resolvedCity) displayName = resolvedCity;
        }
      } catch (e) { }
      setLocationName(displayName); locData = { lat, lng, name: displayName };
    }
    if (t) {
      setTimings(t);
      saveUserLocation({ ...locData, timings: t });

      // Loop pulse animation
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, { toValue: 0.3, duration: 1200, useNativeDriver: true }),
          Animated.timing(pulseAnim, { toValue: 1, duration: 1200, useNativeDriver: true })
        ])
      ).start();

      updateTimeLogic(t);
    }
  };

  useEffect(() => {
    (async () => {
      const saved = await getUserLocation();
      if (saved && (saved.city || saved.lat)) {
        if (saved.city) fetchDynamicSalah(0, 0, saved.city);
        else {
          if (saved.timings) {
            setTimings(saved.timings);
            setLocationName(saved.name);
            if (saved.lat && saved.lng) {
              fetchWeatherData(saved.lat, saved.lng);
            }
          }
          else { fetchDynamicSalah(saved.lat, saved.lng); }
        }
      } else {
        let { status } = await Location.requestForegroundPermissionsAsync();
        if (status !== 'granted') { fetchDynamicSalah(51.5085, -0.1257); }
        else {
          try {
            let location = await Location.getCurrentPositionAsync({});
            fetchDynamicSalah(location.coords.latitude, location.coords.longitude);
          } catch (e) { fetchDynamicSalah(51.5085, -0.1257); }
        }
      }
    })();

    // Sequence for staggered pops
    const animSequence = entryAnims.map(a => Animated.spring(a, {
      toValue: 1, useNativeDriver: true, tension: 50, friction: 7
    }));

    Animated.stagger(150, animSequence).start();
  }, []);

  useEffect(() => {
    if (!timings) return;
    const intervalId = setInterval(() => updateTimeLogic(timings), 1000);
    return () => clearInterval(intervalId);
  }, [timings]);

  useEffect(() => {
    const loadQuranProgress = async () => {
      try {
        const raw = await AsyncStorage.getItem('deen360_bookmarks');
        const bookmarks = raw ? JSON.parse(raw) : [];
        if (bookmarks.length > 0) {
          setLastReadQuran(bookmarks[bookmarks.length - 1]);
        }
      } catch (e) { }
    };
    loadQuranProgress();
  }, []);

  const fetchProgress = async () => {
    try {
      const savedTracker = await AsyncStorage.getItem('deen360_salah_tracker');
      const today = new Date().toDateString();
      if (savedTracker) {
        const parsed = JSON.parse(savedTracker);
        if (parsed.date === today && parsed.data) {
          const count = Object.values(parsed.data).filter(Boolean).length;
          setPrayerProgress(count);
          setPrayerTrackerData(parsed.data);
          return;
        }
      }
      setPrayerProgress(0);
      setPrayerTrackerData(initialTracker);
    } catch (e) { }
  };

  const handleTogglePrayer = async (prayerName) => {
    try {
      const today = new Date().toDateString();
      const updatedData = { ...prayerTrackerData, [prayerName]: !prayerTrackerData[prayerName] };
      const count = Object.values(updatedData).filter(Boolean).length;
      
      setPrayerTrackerData(updatedData);
      setPrayerProgress(count);
      
      await AsyncStorage.setItem('deen360_salah_tracker', JSON.stringify({
        date: today,
        data: updatedData
      }));
      
      // Sync forward to deep history
      const savedHistory = await AsyncStorage.getItem('deen360_salah_history');
      const historyDict = savedHistory ? JSON.parse(savedHistory) : {};
      if (!historyDict[today]) historyDict[today] = {};
      
      if (updatedData[prayerName]) {
         // Auto-tag as single if marked complete from home screen
         if (!historyDict[today][prayerName]) historyDict[today][prayerName] = {};
         historyDict[today][prayerName].fard = 'single';
      } else {
         // Clear fard requirement if untoggled
         if (historyDict[today][prayerName]) delete historyDict[today][prayerName].fard;
      }
      await AsyncStorage.setItem('deen360_salah_history', JSON.stringify(historyDict));
      
      LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
    } catch(e) {}
  };

  useEffect(() => {
    fetchProgress();
  }, []);

  // Sync progress periodically or when screen data updates
  useEffect(() => {
    if (timings) fetchProgress();
  }, [timings]);

  const handleShareAyah = async () => {
    try {
      await Share.share({
        message: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ\n'Verily, in the remembrance of Allah do hearts find rest.'\n— Quran 13:28\nShared from Deen360",
      });
    } catch (error) {
      console.log(error.message);
    }
  };

  // -- THEME HELPERS --
  const getAtmosphereColors = () => {
    switch (atmosphere) {
      case 'Dawn': return ['#F0F9FF', '#E0F2FE']; // Soft Sky Blue
      case 'Day': return ['#FFFFFF', '#F9FAFB'];  // Pure White
      case 'Sunset': return ['#FFF7ED', '#FFEDD5']; // Soft Peach
      case 'Night': return ['#F1F5F9', '#E2E8F0']; // Very Light Slate
      default: return ['#FFFFFF', '#F9FAFB'];
    }
  };

  const getDynamicGreeting = () => {
    const hour = new Date().getHours();
    let greet = "Blessed Morning";
    if (hour >= 12 && hour < 17) greet = "Peaceful Afternoon";
    else if (hour >= 17 && hour < 20) greet = "Golden Evening";
    else if (hour >= 20 || hour < 5) greet = "Quiet Night";

    const tempStr = temperature !== null ? `, ${temperature}°C` : '';
    return `${greet}${tempStr}`;
  };

  const calculateBlockProgress = () => {
    if (!currentBlock) return 0;
    const now = new Date();
    const total = currentBlock.end.getTime() - currentBlock.start.getTime();
    const elapsed = now.getTime() - currentBlock.start.getTime();
    return Math.max(0, Math.min(1, elapsed / total));
  };

  const getBlockIcon = () => {
    if (!currentBlock) return '✨';
    const name = currentBlock.name.toLowerCase();
    if (name.includes('fajr')) return '🌅';
    if (name.includes('sunrise')) return '☀️';
    if (name.includes('dhuhr')) return '🏙️';
    if (name.includes('asr')) return '🌇';
    if (name.includes('maghrib')) return '🌙';
    if (name.includes('isha')) return '🌌';
    return '✨';
  };

  // -- INTERACTIVE COMPONENTS --

  // -- IMMERSIVE RENDERERS --

  const renderZenHUD = () => {
    return (
      <TouchableOpacity
        style={styles.weatherBentoCard}
        onPress={() => navigate('salah')}
        activeOpacity={0.9}
        delayPressIn={50}
      >
        {/* Top Row: Location & Weather Capsule */}
        <View style={styles.weatherTopRow}>
          <View style={styles.weatherLocationBox}>
            <Text style={styles.weatherLocationIcon}>📍</Text>
            <Text
              style={styles.weatherLocationText}
              numberOfLines={1}
              adjustsFontSizeToFit
            >
              {locationName}
            </Text>
          </View>

          <View style={styles.weatherTopCapsule}>
            <Text style={styles.weatherTopCapsuleText}>
              {weatherEmoji} {temperature !== null ? `${temperature}°C` : '--°C'}
            </Text>
          </View>
        </View>

        {/* Hero Row: Massive Salah Name & Countdown Status */}
        <View style={styles.weatherHeroRow}>
          <View style={styles.weatherNameCol}>
            <Text
              style={styles.weatherMainName}
              numberOfLines={1}
              adjustsFontSizeToFit
              minimumFontScale={0.5}
            >
              {currentBlock?.name.toUpperCase()}
            </Text>
            <Text style={styles.weatherStatTypeLabel}>
              Current {currentBlock?.type === 'Fard' ? 'Salah' : 'Event'}
            </Text>
          </View>
          <View style={styles.weatherStatusCol}>
            <Text
              style={styles.weatherCountdownText}
              numberOfLines={1}
              adjustsFontSizeToFit
            >
              {timeRemaining}
            </Text>
            <Text style={styles.weatherCountLabel}>
              Until {nextBlock?.name || 'Next'}
            </Text>
          </View>
        </View>

        {/* Divider */}
        <View style={styles.weatherDividerLine} />

        {/* Bottom Stats Grid: Started, Ending, Next */}
        <View style={styles.weatherStatsRow}>
          <View style={styles.weatherStatItem}>
            <Text style={styles.weatherStatLabel}>Started</Text>
            <Text style={styles.weatherStatValue}>{currentBlock?.start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</Text>
          </View>
          <View style={styles.weatherVerticalDivider} />
          <View style={styles.weatherStatItem}>
            <Text style={styles.weatherStatLabel}>Ending</Text>
            <Text style={styles.weatherStatValue}>{currentBlock?.end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</Text>
          </View>
          <View style={styles.weatherVerticalDivider} />
          <View style={styles.weatherStatItem}>
            <Text style={styles.weatherStatLabel}>
              {nextBlock?.type === 'Fard' ? 'Next Prayer' : 'Next Event'}
            </Text>
            <Text style={styles.weatherStatValue}>{nextBlock?.name}</Text>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const renderSpiritualRoadmap = () => {
    const roadmapItems = [
      { id: 'quran', title: 'Al-Quran', sub: 'The Divine Word', icon: 'book', route: 'surahList', isHero: true },
      { id: 'hadith', title: 'Daily Hadith', sub: 'Prophetic Wisdom', icon: 'star', route: 'hadiths' },
      { id: 'asma', title: '99 Names of Allah', sub: 'Attributes of Allah', icon: 'heart', route: 'asma' },
      { id: 'mosque', title: 'Mosque Locator', sub: 'Find nearest prayer spaces', icon: 'map-pin', route: 'masjidLocator' },
      { id: 'qibla', title: 'Qibla Compass', sub: 'Kaaba alignment', icon: 'compass', route: 'qibla' },
      { id: 'duas', title: 'Dua Collection', sub: 'Hisnul Muslim', icon: 'message-circle', route: 'duaCategories' },
      { id: 'schedule', title: 'Salah Schedule', sub: 'Monthly timings', icon: 'calendar', route: 'salah' },
    ];

    return (
      <View style={styles.roadmapContainer}>
        {roadmapItems.map((item, index) => (
          <TouchableOpacity
            key={item.id}
            style={[styles.roadmapItem, item.isHero && styles.roadmapHeroItem]}
            onPress={() => navigate(item.route)}
            activeOpacity={0.7}
            delayPressIn={80}
          >
            <View style={[styles.roadmapIconBadge, item.isHero && styles.roadmapHeroIconBadge]}>
              <Feather
                name={item.icon}
                size={item.isHero ? 28 : 22}
                color={item.isHero ? '#FFFFFF' : '#10B981'}
              />
            </View>

            <View style={styles.roadmapContent}>
              <Text style={[styles.roadmapTitle, item.isHero && styles.roadmapHeroTitle]}>{item.title}</Text>
              <Text style={styles.roadmapSub}>{item.sub}</Text>
            </View>

            <View style={styles.roadmapAction}>
              <Text style={styles.roadmapChevron}>→</Text>
            </View>
          </TouchableOpacity>
        ))}
      </View>
    );
  };

  const renderSpiritualProgress = () => {
    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return (
      <View style={styles.progressSection}>
        <View style={styles.sectionHeaderRow}>
          <Text style={styles.sectionTitle}>Daily Tracer</Text>
          <View style={styles.progressBadge}>
            <Feather name="activity" size={14} color="#10B981" />
            <Text style={styles.progressCounter}>{prayerProgress}/5</Text>
          </View>
        </View>
        <View style={styles.prayerTrackerCard}>
          <View style={styles.prayerDotsRow}>
            {prayers.map((p) => {
              const isCompleted = prayerTrackerData[p] === true;
              return (
                <TouchableOpacity 
                  key={p} 
                  style={styles.prayerDotWrapper}
                  activeOpacity={0.6}
                  onPress={() => handleTogglePrayer(p)}
                >
                  <View style={[styles.prayerDot, isCompleted ? styles.prayerDotActive : null]}>
                    {isCompleted && <Feather name="check" size={16} color="#FFFFFF" />}
                  </View>
                  <Text style={[styles.prayerDotLabel, isCompleted ? styles.prayerDotLabelActive : null]}>{p}</Text>
                </TouchableOpacity>
              )
            })}
          </View>
        </View>
      </View>
    );
  };

  const renderDailyAyahBento = () => {
    return (
      <TouchableOpacity
        style={styles.ayahBentoContainer}
        onPress={() => navigate('surahList')}
        activeOpacity={0.9}
      >
        <LinearGradient
          colors={['#10B981', '#059669']}
          style={styles.ayahGradientCard}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.ayahHeaderRow}>
            <View style={styles.ayahBadgeHeader}>
              <Feather name="book-open" size={14} color="#FFF" style={{ marginRight: 6 }} />
              <Text style={styles.ayahTagNew}>DAILY AYAH</Text>
            </View>
            <TouchableOpacity onPress={handleShareAyah} style={styles.ayahShareBtn}>
              <Feather name="share-2" size={16} color="#FFF" />
            </TouchableOpacity>
          </View>

          <Feather name="message-circle" size={32} color="rgba(255,255,255,0.2)" style={{ marginBottom: 10 }} />
          <Text style={styles.ayahArabicNew} numberOfLines={2}>
            "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ"
          </Text>
          <Text style={styles.ayahEnglishNew}>
            "Verily, in the remembrance of Allah do hearts find rest."
          </Text>
          <Text style={styles.ayahRefNew}>Surah Ar-Ra'd [13:28]</Text>
        </LinearGradient>
      </TouchableOpacity>
    );
  };

  const renderContinueReading = () => {
    if (!lastReadQuran) return null;

    const progressPerc = lastReadQuran.totalAyahs && lastReadQuran.totalAyahs > 0
      ? Math.min((lastReadQuran.ayah / lastReadQuran.totalAyahs) * 100, 100)
      : 0;

    return (
      <View style={styles.dashboardGridArea}>
        <Text style={styles.sectionHeader}>Continue Reading</Text>
        <TouchableOpacity
          style={styles.continueReadingCard}
          onPress={() => navigate('surahContent', { number: lastReadQuran.surah, initialAyah: lastReadQuran.ayah })}
          activeOpacity={0.9}
        >
          <View style={styles.crTopRow}>
            <View style={styles.crBadge}>
              <Feather name="book-open" size={14} color="#10B981" />
            </View>
            <Text style={styles.crTitle}>{lastReadQuran.surahName}</Text>
          </View>
          <Text style={styles.crAyahInfo}>Ayah {lastReadQuran.ayah} • {lastReadQuran.totalAyahs} Verses Total</Text>

          <View style={styles.crProgressContainer}>
            <View style={styles.crProgressBar}>
              <View style={[styles.crProgressFill, { width: `${progressPerc}%` }]} />
            </View>
            <Text style={styles.crProgressPercent}>{Math.round(progressPerc)}%</Text>
          </View>

          <View style={styles.crResumeBtn}>
            <Text style={styles.crResumeBtnText}>Resume</Text>
            <Feather name="arrow-right" size={14} color="#FFFFFF" />
          </View>
        </TouchableOpacity>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" translucent backgroundColor="transparent" />

      <LinearGradient
        colors={getAtmosphereColors()}
        style={StyleSheet.absoluteFill}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      />

      <Animated.ScrollView
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        <SafeAreaView style={{ flex: 1 }}>
          {/* Greeting removed per request */}
          {renderZenHUD()}

          <View style={styles.dashboardGridArea}>
            <Text style={styles.sectionHeader}>Journey Roadmap</Text>
            {renderSpiritualRoadmap()}
          </View>

          {renderSpiritualProgress()}

          <View style={styles.dashboardGridArea}>
            <Text style={styles.sectionHeader}>Spiritual Insight</Text>
            {renderDailyAyahBento()}
          </View>

          {renderContinueReading()}

          <View style={{ height: 100 }} />
        </SafeAreaView>
      </Animated.ScrollView>
    </View>
  );
}

// -- STYLES (Expanded for High-Fidelity) --
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF'
  },
  scrollContent: {
    paddingTop: Platform.OS === 'ios' ? 0 : StatusBar.currentHeight,
  },

  // -- Greeting Area --
  mainGreetingArea: {
    paddingHorizontal: 30,
    marginTop: 20,
    marginBottom: 40,
  },
  greetingGreeting: {
    color: 'rgba(255,255,255,0.6)',
    fontSize: 14,
    fontWeight: '700',
    letterSpacing: 1,
    textTransform: 'uppercase',
  },
  greetingDate: {
    color: '#FFF',
    fontSize: 28,
    fontWeight: '900',
    marginTop: 4,
  },

  weatherBentoCard: {
    backgroundColor: '#10B981', // Solid DS Emerald
    marginHorizontal: 20,
    borderRadius: 32,
    padding: 24,
    marginBottom: 40,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
    ...SHADOWS.floating, // Premium shadow for the anchor card
  },
  weatherTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  weatherLocationBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)', // Stay bright on the vibrant card
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    minWidth: 120,
    maxWidth: width * 0.6,
    height: 40,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  weatherLocationIcon: {
    fontSize: 14,
    marginRight: 6,
  },
  weatherLocationText: {
    color: '#FFF',
    fontSize: 14,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  weatherSalahIndicator: {
    color: 'rgba(255,255,255,0.9)',
    fontSize: 14,
    fontWeight: '900',
    letterSpacing: 2,
  },
  weatherTopIcon: {
    fontSize: 32,
  },
  weatherHeroRow: {
    flexDirection: 'row',
    alignItems: 'center', // Centered for balance
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  weatherTimeCol: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  weatherMainTime: {
    color: '#FFF',
    fontSize: 72,
    fontWeight: '900',
    letterSpacing: -2,
    lineHeight: 76,
  },
  weatherTimeSuffix: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '800',
    marginTop: 10,
    marginLeft: 4,
  },
  weatherTopCapsule: {
    backgroundColor: 'rgba(0,0,0,0.15)', // Darker for contrast on bright emerald
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    height: 40,
  },
  weatherTopCapsuleText: {
    color: '#FFF',
    fontSize: 14,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  weatherNameCol: {
    flex: 1.2,
    justifyContent: 'center',
  },
  weatherMainName: {
    color: '#FFF',
    fontSize: 52,
    fontWeight: '900',
    letterSpacing: -1,
    lineHeight: 56,
  },
  weatherStatusCol: {
    flex: 1.4,
    alignItems: 'flex-end',
    justifyContent: 'center',
    marginLeft: 15,
  },
  weatherCountdownText: {
    color: '#FFF',
    fontSize: 32,
    fontWeight: '900',
    textAlign: 'right',
    letterSpacing: -0.5,
  },
  weatherCountLabel: {
    color: '#D1FAE5', // Light Emerald tint for high legibility on dark green
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase',
    letterSpacing: 1,
    textAlign: 'right',
    marginTop: 2,
  },
  weatherStatTypeLabel: {
    color: 'rgba(255,255,255,0.8)', // High contrast on the vibrant green
    fontSize: 12,
    fontWeight: '800',
    textTransform: 'uppercase',
    letterSpacing: 1,
    textAlign: 'left',
    marginTop: 2,
  },
  weatherDateTime: {
    color: 'rgba(255,255,255,0.6)',
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  weatherDividerLine: {
    height: 1,
    backgroundColor: 'rgba(255,255,255,0.2)',
    marginBottom: 20,
  },
  weatherStatsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  weatherStatItem: {
    flex: 1,
    alignItems: 'center',
  },
  weatherStatLabel: {
    color: 'rgba(255,255,255,0.7)',
    fontSize: 11,
    fontWeight: '800',
    marginBottom: 4,
    textTransform: 'uppercase',
  },
  weatherStatValue: {
    color: '#FFF',
    fontSize: 15,
    fontWeight: '900',
  },
  weatherVerticalDivider: {
    width: 1,
    height: 30,
    backgroundColor: 'rgba(255,255,255,0.2)',
  },

  // -- Zen HUD --
  zenHUDContainer: {
    alignItems: 'center',
    marginBottom: 60,
  },
  zenCurrentTime: {
    color: '#FFF',
    fontSize: 80,
    fontWeight: '900',
    letterSpacing: -4,
  },
  zenStatusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: -10,
  },
  zenPrayerName: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '800',
    letterSpacing: 2,
  },
  zenDivider: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: 'rgba(255,255,255,0.3)',
    marginHorizontal: 15,
  },
  zenCountdown: {
    color: 'rgba(255,255,255,0.7)',
    fontSize: 16,
    fontWeight: '700',
  },
  zenLocationBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 20,
    marginTop: 30,
  },
  zenLocationIcon: {
    fontSize: 14,
    marginRight: 8,
  },
  zenLocationText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '800',
  },
  zenProhibitedBadge: {
    backgroundColor: 'rgba(239, 68, 68, 0.2)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 10,
    marginTop: 15,
    borderWidth: 1,
    borderColor: 'rgba(239, 68, 68, 0.4)',
  },
  zenProhibitedText: {
    color: '#FECACA',
    fontSize: 10,
    fontWeight: '900',
    textTransform: 'uppercase',
  },

  // -- Spiritual Roadmap UI --
  dashboardGridArea: {
    paddingHorizontal: 20,
    marginBottom: 40,
  },
  sectionHeader: {
    color: '#111827', // Dark DS Slate
    fontSize: 20,
    fontWeight: '900',
    marginBottom: 20,
    marginLeft: 10,
  },
  roadmapContainer: {
    marginTop: 5,
  },
  roadmapItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingVertical: 18,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
    paddingHorizontal: 10,
  },
  roadmapHeroItem: {
    backgroundColor: '#F9FAFB',
    borderRadius: 24,
    paddingHorizontal: 20,
    borderBottomWidth: 0,
    marginBottom: 10,
  },
  roadmapIconBadge: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'rgba(16, 185, 129, 0.08)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  roadmapHeroIconBadge: {
    backgroundColor: '#10B981',
    width: 54,
    height: 54,
  },
  roadmapIconText: {
    fontSize: 22,
  },
  roadmapHeroIconText: {
    fontSize: 26,
  },
  roadmapContent: {
    flex: 1,
    marginLeft: 18,
  },
  roadmapTitle: {
    color: '#111827',
    fontSize: 17,
    fontWeight: '800',
  },
  roadmapHeroTitle: {
    fontSize: 20,
    fontWeight: '900',
    color: '#111827',
  },
  roadmapSub: {
    color: '#6B7280',
    fontSize: 13,
    fontWeight: '600',
    marginTop: 2,
  },
  roadmapAction: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F9FAFB',
    justifyContent: 'center',
    alignItems: 'center',
  },
  roadmapChevron: {
    color: '#9CA3AF',
    fontSize: 18,
    fontWeight: '800',
  },

  // -- Daily Ayah Bento Redesign --
  ayahBentoContainer: {
    width: '100%',
  },
  ayahGradientCard: {
    borderRadius: 28,
    padding: 24,
    ...SHADOWS.premium,
  },
  ayahHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },
  ayahBadgeHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  ayahTagNew: {
    color: '#FFF',
    fontSize: 10,
    fontWeight: '900',
    letterSpacing: 1,
  },
  ayahShareBtn: {
    backgroundColor: 'rgba(255,255,255,0.2)',
    width: 36,
    height: 36,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 18,
  },
  ayahArabicNew: {
    color: '#FFF',
    fontSize: 26,
    fontWeight: '800',
    fontStyle: 'italic',
    lineHeight: 40,
    textAlign: 'center',
    marginBottom: 12,
  },
  ayahEnglishNew: {
    color: 'rgba(255,255,255,0.85)',
    fontSize: 15,
    fontWeight: '600',
    lineHeight: 22,
    textAlign: 'center',
    marginBottom: 15,
  },
  ayahRefNew: {
    color: '#D1FAE5',
    fontSize: 12,
    fontWeight: '800',
    textAlign: 'center',
    letterSpacing: 0.5,
  },

  // -- Trackers Redesign --
  progressSection: {
    paddingHorizontal: 30,
    marginBottom: 40,
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },
  sectionTitle: {
    color: '#111827',
    fontSize: 18,
    fontWeight: '900',
  },
  progressBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#10B98115',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 10,
  },
  progressCounter: {
    color: '#10B981',
    fontSize: 14,
    fontWeight: '900',
    marginLeft: 6
  },
  prayerTrackerCard: {
    padding: 24,
    borderRadius: 24,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#F1F5F9',
    ...SHADOWS.soft,
  },
  prayerDotsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  prayerDotWrapper: {
    alignItems: 'center',
  },
  prayerDot: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  prayerDotActive: {
    backgroundColor: '#10B981',
  },
  prayerDotLabel: {
    color: '#94A3B8',
    fontSize: 11,
    fontWeight: '800',
  },
  prayerDotLabelActive: {
    color: '#10B981',
  },

  // -- Continue Reading Widget --
  continueReadingCard: {
    borderRadius: 24,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#F1F5F9',
    padding: 24,
    ...SHADOWS.soft,
  },
  crTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  crBadge: {
    width: 32,
    height: 32,
    borderRadius: 10,
    backgroundColor: '#10B98115',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  crTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#111827',
  },
  crAyahInfo: {
    fontSize: 12,
    fontWeight: '700',
    color: '#64748B',
    marginBottom: 20,
    marginLeft: 42,
  },
  crProgressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 20,
  },
  crProgressBar: {
    flex: 1,
    height: 6,
    backgroundColor: '#F1F5F9',
    borderRadius: 3,
    marginRight: 12,
    overflow: 'hidden',
  },
  crProgressFill: {
    height: '100%',
    backgroundColor: '#10B981',
    borderRadius: 3,
  },
  crProgressPercent: {
    fontSize: 12,
    fontWeight: '800',
    color: '#10B981',
  },
  crResumeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#10B981',
    paddingVertical: 14,
    borderRadius: 14,
  },
  crResumeBtnText: {
    color: '#FFFFFF',
    fontWeight: '800',
    fontSize: 14,
    marginRight: 6,
  },
});
