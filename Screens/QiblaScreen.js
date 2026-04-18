import React, { useState, useEffect, useRef } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  Animated, 
  TouchableOpacity, 
  SafeAreaView, 
  StatusBar,
  Dimensions,
  ActivityIndicator,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import * as Location from 'expo-location';
import { getUserLocation, saveUserLocation } from '../data/salahStore';
import { THEME, SHADOWS, RADIUS, SPACING } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';
import { LinearGradient } from 'expo-linear-gradient';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width, height } = Dimensions.get('window');
const COMPASS_SIZE = width * 0.8;

const KAABA_LAT = 21.422487;
const KAABA_LNG = 39.826206;

const calculateQibla = (lat, lng) => {
  const PI = Math.PI;
  const latK = KAABA_LAT * (PI / 180.0);
  const lngK = KAABA_LNG * (PI / 180.0);
  const phi = lat * (PI / 180.0);
  const lambda = lng * (PI / 180.0);
  const y = Math.sin(lngK - lambda);
  const x = Math.cos(phi) * Math.tan(latK) - Math.sin(phi) * Math.cos(lngK - lambda);
  let qibla = Math.atan2(y, x) * (180.0 / PI);
  return (qibla + 360) % 360;
};

/**
 * QiblaScreen 2.0: High-Fidelity Orientation Engine
 * Features:
 * - 3D-feeling Glow Compass
 * - Emerald Alignment Pulse
 * - Real-time Bearing Calculation
 * - Atmospheric Distance Header
 * - Micro-interactions (Scale & Bounce)
 */
export default function QiblaScreen({ navigate }) {
  // Logic & Data State
  const [loading, setLoading] = useState(true);
  const [calibrating, setCalibrating] = useState(true);
  const [errorMsg, setErrorMsg] = useState(null);
  const [qiblaBearing, setQiblaBearing] = useState(0);
  const [currentHeading, setCurrentHeading] = useState(0);
  const [locationName, setLocationName] = useState('Locating...');
  const [distance, setDistance] = useState('--- km');

  // Animation Values
  const compassSpin = useRef(new Animated.Value(0)).current;
  const pointerSpin = useRef(new Animated.Value(0)).current;
  const alignmentPulse = useRef(new Animated.Value(1)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;

  // -- CALCULATIONS --
  const getDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Radius of earth in km
    const dLat = (lat2-lat1) * Math.PI / 180;
    const dLon = (lon2-lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
            Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return Math.round(R * c);
  };

  const handleRefresh = () => {
     setLoading(true);
     setCalibrating(true);
     initSensors();
  };

  const initSensors = async () => {
      try {
        let lat, lng;
        const savedLoc = await getUserLocation();
        
        if (savedLoc && savedLoc.lat && savedLoc.lng) {
          lat = savedLoc.lat; lng = savedLoc.lng;
          setLocationName(savedLoc.name?.split(',')[0] || 'My Location');
        } else {
          let { status } = await Location.requestForegroundPermissionsAsync();
          if (status !== 'granted') { setErrorMsg('Location access is required.'); setLoading(false); return; }
          let location = await Location.getCurrentPositionAsync({});
          lat = location.coords.latitude; lng = location.coords.longitude;
          let geocode = await Location.reverseGeocodeAsync({latitude: lat, longitude: lng});
          setLocationName(geocode[0]?.city || 'Current Location');
        }

        setQiblaBearing(calculateQibla(lat, lng));
        setDistance(`${getDistance(lat, lng, KAABA_LAT, KAABA_LNG)} km`);
        setLoading(false);
        Animated.timing(fadeAnim, { toValue: 1, duration: 800, useNativeDriver: true }).start();
        setTimeout(() => setCalibrating(false), 3000);
      } catch (e) {
        setErrorMsg('Error initializing orientation sensors.');
        setLoading(false);
      }
  };

  useEffect(() => {
    initSensors();
    let subscription = null;
    Location.watchHeadingAsync((headingObj) => {
        let heading = headingObj.trueHeading > 0 ? headingObj.trueHeading : headingObj.magHeading;
        if (heading >= 0) setCurrentHeading(heading);
    }).then(sub => (subscription = sub));

    return () => subscription && subscription.remove();
  }, []);

  useEffect(() => {
    // Smoothed spring animations for rotating compass
    Animated.spring(compassSpin, { toValue: -currentHeading, friction: 5, tension: 35, useNativeDriver: true }).start();
    const delta = qiblaBearing - currentHeading;
    Animated.spring(pointerSpin, { toValue: delta, friction: 5, tension: 35, useNativeDriver: true }).start();

    // Check Alignment - Pulse emerald when pointed toward Kaaba
    const isAligned = Math.abs(delta % 360) < 3 || Math.abs(delta % 360) > 357;
    if (isAligned) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(alignmentPulse, { toValue: 1.1, duration: 400, useNativeDriver: true }),
          Animated.timing(alignmentPulse, { toValue: 1.0, duration: 400, useNativeDriver: true })
        ])
      ).start();
    } else {
      alignmentPulse.setValue(1);
    }
  }, [currentHeading, qiblaBearing]);

  // -- RENDERERS --
  const renderCompass = () => {
    const spinNorth = compassSpin.interpolate({ inputRange: [-360, 0, 360], outputRange: ['-360deg', '0deg', '360deg'] });
    const spinQibla = pointerSpin.interpolate({ inputRange: [-360, 0, 360], outputRange: ['-360deg', '0deg', '360deg'] });
    const isAligned = Math.abs((qiblaBearing - currentHeading) % 360) < 3;

    return (
      <View style={styles.compassBox}>
        <Animated.View style={[styles.glowRing, { transform: [{ scale: alignmentPulse }], opacity: isAligned ? 1 : 0.05 }]} />
        
        {/* Outer Degree Marks */}
        <Animated.View style={[styles.compassDial, { transform: [{ rotate: spinNorth }] }]}>
            {Array.from({ length: 72 }).map((_, i) => (
                <View key={i} style={[styles.tick, { transform: [{ rotate: `${i * 5}deg` }], height: i % 18 === 0 ? 12 : 6, backgroundColor: i % 18 === 0 ? THEME.primary : '#E2E8F0' }]} />
            ))}
            <Text style={[styles.cardinal, styles.north]}>N</Text>
            <Text style={[styles.cardinal, styles.south]}>S</Text>
            <Text style={[styles.cardinal, styles.east]}>E</Text>
            <Text style={[styles.cardinal, styles.west]}>W</Text>
        </Animated.View>

        {/* Floating Kaaba Pointer */}
        <Animated.View style={[styles.pointerStack, { transform: [{ rotate: spinQibla }] }]}>
            <LinearGradient colors={[THEME.primary, THEME.primaryDark]} style={styles.pointerLine} />
            <View style={styles.kaabaIconBox}>
                <Text style={styles.kaabaIcon}>🕋</Text>
            </View>
        </Animated.View>

        <View style={styles.centerAnchor} />
      </View>
    );
  };

  const renderHeader = () => (
    <View style={styles.headerArea}>
        <SafeAreaView style={{ paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 }}>
            <View style={styles.topNav}>
                <AnimatedScaleButton style={styles.navBtn} onPress={() => navigate('home')}>
                    <Text style={styles.navBtnText}>←</Text>
                </AnimatedScaleButton>
                <Text style={styles.navTitle}>Qibla Finder</Text>
                <AnimatedScaleButton style={styles.navBtn} onPress={handleRefresh}>
                    <Text style={styles.navBtnText}>↻</Text>
                </AnimatedScaleButton>
            </View>
        </SafeAreaView>

        <View style={styles.heroSection}>
            <LinearGradient colors={[THEME.primary, THEME.primaryDark]} style={styles.heroCard} start={{x:0, y:0}} end={{x:1,y:1}}>
                <View style={styles.heroMeta}>
                    <Text style={styles.heroLabel}>DISTANCE TO KAABA</Text>
                    <Text style={styles.heroValue}>{distance}</Text>
                    <Text style={styles.heroSub}>{locationName}, Earth</Text>
                </View>
                <View style={styles.heroGraphic}>
                    <Text style={styles.worldIcon}>🌍</Text>
                </View>
            </LinearGradient>
        </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      {renderHeader()}
      
      {loading ? (
        <View style={styles.loadingBox}>
            <ActivityIndicator size="large" color={THEME.primary} />
            <Text style={styles.loadingText}>Syncing with Satellite...</Text>
        </View>
      ) : (
        <Animated.View style={[styles.content, { opacity: fadeAnim }]}>
            {calibrating ? (
                <View style={styles.calibBlock}>
                    <Text style={styles.calibTitle}>Calibrating Sensors</Text>
                    <Text style={styles.calibSub}>Please move your phone in a "Figure 8" path for better accuracy.</Text>
                </View>
            ) : (
                <View style={styles.mainCompassArea}>
                    <Text style={styles.instruction}>Keep device flat for the best result</Text>
                    {renderCompass()}
                    <View style={styles.statusBox}>
                        <Text style={styles.degreeTitle}>{Math.round(qiblaBearing)}°</Text>
                        <Text style={styles.degreeSub}>Relative to True North</Text>
                    </View>
                </View>
            )}
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  loadingBox: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingText: { marginTop: 16, fontWeight: '700', color: THEME.primary },
  
  // -- Header --
  headerArea: { backgroundColor: '#FFFFFF', paddingBottom: 20 },
  topNav: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 12 },
  navBtn: { width: 44, height: 44, borderRadius: 14, backgroundColor: '#F3F4F6', justifyContent: 'center', alignItems: 'center' },
  navBtnText: { fontSize: 20, fontWeight: '800' },
  navTitle: { fontSize: 18, fontWeight: '900', color: THEME.text, letterSpacing: -0.5 },

  heroSection: { paddingHorizontal: 20, marginTop: 10 },
  heroCard: { borderRadius: 32, padding: 24, flexDirection: 'row', alignItems: 'center', ...SHADOWS.premium },
  heroMeta: { flex: 1 },
  heroLabel: { color: 'rgba(255,255,255,0.6)', fontSize: 10, fontWeight: '900', letterSpacing: 1 },
  heroValue: { color: 'white', fontSize: 32, fontWeight: '900', marginTop: 4 },
  heroSub: { color: 'white', fontSize: 13, fontWeight: '600', marginTop: 4, opacity: 0.8 },
  heroGraphic: { width: 60, height: 60, borderRadius: 20, backgroundColor: 'rgba(255,255,255,0.15)', justifyContent: 'center', alignItems: 'center' },
  worldIcon: { fontSize: 32 },

  // -- Content --
  content: { flex: 1 },
  calibBlock: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 40 },
  calibTitle: { fontSize: 22, fontWeight: '800', color: THEME.text },
  calibSub: { fontSize: 14, color: '#64748B', textAlign: 'center', marginTop: 12, lineHeight: 22 },

  mainCompassArea: { flex: 1, alignItems: 'center', paddingTop: 30 },
  instruction: { fontSize: 13, fontWeight: '600', color: '#64748B', marginBottom: 40 },

  compassBox: { width: COMPASS_SIZE, height: COMPASS_SIZE, justifyContent: 'center', alignItems: 'center' },
  glowRing: { position: 'absolute', width: '100%', height: '100%', borderRadius: COMPASS_SIZE / 2, backgroundColor: THEME.primary + '20', borderWidth: 2, borderColor: THEME.primary },
  compassDial: { width: '100%', height: '100%', borderRadius: COMPASS_SIZE / 2, backgroundColor: '#F8FAFC', justifyContent: 'center', alignItems: 'center' },
  tick: { position: 'absolute', width: 2, top: 0 },
  cardinal: { position: 'absolute', fontSize: 18, fontWeight: '900', color: THEME.text },
  north: { top: 20, color: THEME.primary },
  south: { bottom: 20 },
  east: { right: 20 },
  west: { left: 20 },

  pointerStack: { position: 'absolute', width: '100%', height: '100%', alignItems: 'center', paddingBottom: COMPASS_SIZE / 2, zIndex: 10 },
  pointerLine: { width: 4, height: '40%', borderRadius: 2, marginTop: 40 },
  kaabaIconBox: { width: 48, height: 48, borderRadius: 14, backgroundColor: 'white', justifyContent: 'center', alignItems: 'center', top: -10, ...SHADOWS.premium },
  kaabaIcon: { fontSize: 32 },
  centerAnchor: { position: 'absolute', width: 12, height: 12, borderRadius: 6, backgroundColor: THEME.primary, zIndex: 20, borderWidth: 2, borderColor: 'white' },

  statusBox: { marginTop: 60, alignItems: 'center' },
  degreeTitle: { fontSize: 56, fontWeight: '900', color: THEME.primary, letterSpacing: -2 },
  degreeSub: { fontSize: 14, fontWeight: '700', color: '#64748B', marginTop: -4 }
});
