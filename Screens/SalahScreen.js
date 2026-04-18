import React, { useEffect, useState, useRef } from 'react';
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
  ActivityIndicator,
  TextInput,
  Platform,
  LayoutAnimation,
  UIManager
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { LinearGradient } from 'expo-linear-gradient';
import { Feather } from '@expo/vector-icons';
import { getUserLocation, getSalahTimingsByCity, getSalahTimingsByCoordinates, saveUserLocation } from '../data/salahStore';
import { THEME, SHADOWS, RADIUS, SPACING } from '../components/theme';
import { AnimatedScaleButton } from '../components/UI';

// Enable LayoutAnimation for Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

const { width, height } = Dimensions.get('window');

const OBLIGATORY = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const SUNNAH = ['Sunrise', 'Imsak', 'Sunset', 'Midnight', 'Lastthird'];

export default function SalahScreen({ navigate }) {
  // Logic State
  const [loading, setLoading] = useState(true);
  const [locationName, setLocationName] = useState('Unknown Location');
  const [timings, setTimings] = useState(null);
  
  // -- ADVANCED HISTORY LOGIC --
  const [history, setHistory] = useState({});
  const [selectedDate, setSelectedDate] = useState(() => new Date().toDateString());
  const [expandedPrayer, setExpandedPrayer] = useState(null);
  
  // Generate Past 14 Days
  const datesList = useRef(Array.from({length: 14}).map((_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (13 - i));
    return d;
  })).current;
  
  // Interaction State
  const [searchCity, setSearchCity] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [suggestions, setSuggestions] = useState([]);
  const [salatActive, setSalatActive] = useState('Maghrib');
  const [timeRemaining, setTimeRemaining] = useState('--:--:--');

  // Animation Values
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const progressAnim = useRef(new Animated.Value(0)).current;
  const scrollY = useRef(new Animated.Value(0)).current;
  const searchBarWidth = useRef(new Animated.Value(0)).current;

  const updateCountdown = (t = timings) => {
    if (!t) return;
    const now = new Date();
    const currentSeconds = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
    
    const timeToSeconds = (str) => {
      if (!str) return 0;
      const timePart = str.split(' ')[0];
      const [h, m] = timePart.split(':').map(Number);
      return (h || 0) * 3600 + (m || 0) * 60;
    };

    const pSecs = {
      Fajr: timeToSeconds(t.Fajr), Dhuhr: timeToSeconds(t.Dhuhr),
      Asr: timeToSeconds(t.Asr), Maghrib: timeToSeconds(t.Maghrib), Isha: timeToSeconds(t.Isha),
      Midnight: timeToSeconds(t.Midnight)
    };

    let midSecs = pSecs.Midnight;
    if (midSecs < pSecs.Isha) midSecs += 86400;

    const schedule = [
      { name: 'Isha', sec: pSecs.Isha - 86400, label: 'Isha' },
      { name: 'Tahajjud', sec: midSecs - 86400, label: 'Tahajjud' },
      { name: 'Fajr', sec: pSecs.Fajr, label: 'Fajr' },
      { name: 'Dhuhr', sec: pSecs.Dhuhr, label: 'Dhuhr' },
      { name: 'Asr', sec: pSecs.Asr, label: 'Asr' },
      { name: 'Maghrib', sec: pSecs.Maghrib, label: 'Maghrib' },
      { name: 'Isha', sec: pSecs.Isha, label: 'Isha' },
      { name: 'Tahajjud', sec: midSecs, label: 'Tahajjud' },
      { name: 'Fajr', sec: pSecs.Fajr + 86400, label: 'Fajr' }
    ];

    let nextP = schedule[1];
    for (let i = 0; i < schedule.length - 1; i++) {
       if (currentSeconds >= schedule[i].sec && currentSeconds < schedule[i + 1].sec) {
           nextP = schedule[i + 1];
           break;
       }
    }

    setSalatActive(nextP.label);
    let diff = nextP.sec - currentSeconds;
    const h = Math.floor(diff / 3600);
    const m = Math.floor((diff % 3600) / 60);
    const s = Math.floor(diff % 60);
    setTimeRemaining(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`);
  };

  useEffect(() => {
    const loadData = async () => {
      const locData = await getUserLocation();
      if (locData && locData.timings) {
        setTimings(locData.timings);
        setLocationName(locData.name || 'Current Location');
        updateCountdown(locData.timings);
      }

      try {
        const savedHistory = await AsyncStorage.getItem('deen360_salah_history');
        if (savedHistory) {
             const parsedHist = JSON.parse(savedHistory);
             setHistory(parsedHist);
             
             // Sync new history back to legacy `deen360_salah_tracker` for Home Screen dots if today exists
             const todayObj = parsedHist[new Date().toDateString()];
             if (todayObj) {
                 const legacyData = {};
                 OBLIGATORY.forEach(p => {
                    // Check if Fard was marked as jamat, single, or qaza (considered complete)
                    legacyData[p] = (todayObj[p]?.fard === 'jamat' || todayObj[p]?.fard === 'single' || todayObj[p]?.fard === 'qaza');
                 });
                 await AsyncStorage.setItem('deen360_salah_tracker', JSON.stringify({
                     date: new Date().toDateString(),
                     data: legacyData
                 }));
             }
        }
      } catch (e) {}

      setLoading(false);
      Animated.timing(fadeAnim, { toValue: 1, duration: 600, useNativeDriver: true }).start();
    };
    loadData();
  }, []);

  useEffect(() => {
    if (!timings) return;
    const interval = setInterval(() => updateCountdown(timings), 1000);
    return () => clearInterval(interval);
  }, [timings]);

  // Derive Daily Progress based on minimum Fard requirement
  useEffect(() => {
    const todayData = history[selectedDate] || {};
    let fardCompletedCount = 0;
    OBLIGATORY.forEach(p => {
        if (todayData[p] && (todayData[p].fard === 'jamat' || todayData[p].fard === 'single' || todayData[p].fard === 'qaza')) {
            fardCompletedCount++;
        }
    });

    Animated.spring(progressAnim, {
      toValue: fardCompletedCount / 5,
      useNativeDriver: false,
      tension: 20,
      friction: 5
    }).start();
  }, [history, selectedDate]);

  useEffect(() => {
    if (searchCity.trim().length < 3) {
      setSuggestions([]);
      return;
    }
    const delayDebounceFn = setTimeout(async () => {
      try {
        const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(searchCity)}&count=5&language=en&format=json`;
        const res = await fetch(url);
        const data = await res.json();
        if (data && data.results) setSuggestions(data.results);
        else setSuggestions([]);
      } catch (e) {}
    }, 500);
    return () => clearTimeout(delayDebounceFn);
  }, [searchCity]);

  const toggleSearch = (show) => {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setIsSearching(show);
    Animated.timing(searchBarWidth, {
      toValue: show ? 1 : 0, duration: 300, useNativeDriver: false
    }).start();
  };

  const handleSuggestionSelect = async (item) => {
    setLoading(true);
    toggleSearch(false);
    const t = await getSalahTimingsByCoordinates(item.latitude, item.longitude);
    if (t) {
        setTimings(t);
        setLocationName(item.name);
        saveUserLocation({ lat: item.latitude, lng: item.longitude, name: item.name, timings: t });
        setSearchCity('');
        setSuggestions([]);
    }
    setLoading(false);
  };

  const handleCitySearch = async () => {
    if (!searchCity.trim()) return;
    setLoading(true);
    const city = searchCity.trim();
    const t = await getSalahTimingsByCity(city);
    if (t) {
       setTimings(t);
       setLocationName(city);
       saveUserLocation({ city, name: city, timings: t });
       toggleSearch(false);
       setSearchCity('');
       setSuggestions([]);
    }
    setLoading(false);
  };

  // -- HISTORY LOGIC HANDLERS --
  const handleUpdateLayer = async (prayer, layer, value) => {
    const newHistory = { ...history };
    if (!newHistory[selectedDate]) newHistory[selectedDate] = {};
    if (!newHistory[selectedDate][prayer]) newHistory[selectedDate][prayer] = {};
    
    // Toggle logic for booleans or direct set for enums
    if (layer === 'fard') {
       if (newHistory[selectedDate][prayer][layer] === value) delete newHistory[selectedDate][prayer][layer];
       else newHistory[selectedDate][prayer][layer] = value;
    } else {
       newHistory[selectedDate][prayer][layer] = !newHistory[selectedDate][prayer][layer];
    }
    
    setHistory(newHistory);
    try {
      await AsyncStorage.setItem('deen360_salah_history', JSON.stringify(newHistory));
      
      // If updating today, sync to HomeScreen legacy dot tracker
      const todayStr = new Date().toDateString();
      if (selectedDate === todayStr) {
          const legacyData = {};
          OBLIGATORY.forEach(p => {
             legacyData[p] = (newHistory[todayStr][p]?.fard === 'jamat' || newHistory[todayStr][p]?.fard === 'single' || newHistory[todayStr][p]?.fard === 'qaza');
          });
          await AsyncStorage.setItem('deen360_salah_tracker', JSON.stringify({
             date: todayStr,
             data: legacyData
          }));
      }
    } catch(e) {}
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
  };

  const renderHeader = () => {
    const headerTranslateY = scrollY.interpolate({
      inputRange: [0, 200], outputRange: [0, -100], extrapolate: 'clamp'
    });

    return (
      <Animated.View style={[styles.heroHeader, { transform: [{ translateY: headerTranslateY }] }]}>
        <LinearGradient colors={[THEME.primary, THEME.primaryDark]} style={styles.heroGradient}>
            <SafeAreaView style={styles.heroSafe}>
                <View style={styles.heroNav}>
                    <AnimatedScaleButton onPress={() => navigate('home')} style={styles.backBtn}>
                        <Feather name="arrow-left" size={24} color="#FFF" />
                    </AnimatedScaleButton>
                    
                    {!isSearching ? (
                      <AnimatedScaleButton onPress={() => toggleSearch(true)} style={styles.locationContainer}>
                          <Feather name="map-pin" size={14} color="#FFF" style={{marginRight: 6}} />
                          <Text style={styles.locationText} numberOfLines={1}>{locationName}</Text>
                      </AnimatedScaleButton>
                    ) : (
                      <View style={{ flex: 1 }}>
                        <Animated.View style={[styles.searchContainer, { width: width * 0.75 }]}>
                            <TextInput 
                                style={styles.searchInput}
                                placeholder="Search city..."
                                placeholderTextColor="rgba(255,255,255,0.6)"
                                value={searchCity}
                                onChangeText={setSearchCity}
                                onSubmitEditing={handleCitySearch}
                                autoFocus
                            />
                            <TouchableOpacity onPress={() => { toggleSearch(false); setSuggestions([]); }}>
                                <Feather name="x" size={20} color="#FFF" />
                            </TouchableOpacity>
                        </Animated.View>
                        
                        {suggestions.length > 0 && (
                          <View style={styles.suggestionsContainer}>
                            {suggestions.map((item, idx) => (
                              <TouchableOpacity key={idx} style={styles.suggestionItem} onPress={() => handleSuggestionSelect(item)}>
                                <Text style={styles.suggestionText}>{item.name}, <Text style={styles.suggestionSubText}>{item.admin1 || item.country}</Text></Text>
                              </TouchableOpacity>
                            ))}
                          </View>
                        )}
                      </View>
                    )}
                </View>

                <View style={styles.heroContent}>
                    <Text style={styles.countTitle}>{salatActive === 'Tahajjud' ? 'Isha Expires In:' : `Next Prayer: ${salatActive}`}</Text>
                    <Text style={styles.countTimer}>{timeRemaining}</Text>
                    <Text style={styles.countSub}>Let's prepare for the blessing</Text>
                </View>

                <View style={styles.progressContainer}>
                    <View style={styles.progressBarBg}>
                        <Animated.View style={[styles.progressBarFill, { 
                            width: progressAnim.interpolate({
                              inputRange: [0, 1], outputRange: ['0%', '100%']
                            }) 
                        }]} />
                    </View>
                    <Text style={styles.progressLabel}>Fard Completion Status</Text>
                </View>
            </SafeAreaView>
        </LinearGradient>
      </Animated.View>
    );
  };

  const renderDateScroller = () => {
    // Dynamic full date string calculation
    const formattedDateTitle = new Date(selectedDate).toLocaleDateString('en-US', {
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric'
    });

    return (
      <View style={styles.calendarContainer}>
         <Text style={styles.calendarHeader}>{formattedDateTitle}</Text>
         <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.calendarScroll}>
            {datesList.map((d, i) => {
               const dayStr = d.toDateString();
               const isSelected = dayStr === selectedDate;
               const isToday = dayStr === new Date().toDateString();
               const dayName = d.toLocaleDateString('en-US', { weekday: 'short' });
               const dayNum = d.getDate();
               
               // Check if past day has missing Fard
               const isPast = d.getTime() < new Date(new Date().toDateString()).getTime();
               let hasMissed = false;
               if (isPast) {
                   for (let p of OBLIGATORY) {
                       const fRecord = history[dayStr]?.[p]?.fard;
                       if (fRecord !== 'jamat' && fRecord !== 'single' && fRecord !== 'qaza') {
                           hasMissed = true;
                           break;
                       }
                   }
               }

               return (
                 <TouchableOpacity 
                   key={i} 
                   style={[
                     styles.dateCard, 
                     isSelected && styles.dateCardActive,
                     (!isSelected && hasMissed) && { borderColor: THEME.error, borderWidth: 1.5, backgroundColor: THEME.error + '10' }
                   ]}
                   onPress={() => {
                     LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                     setSelectedDate(dayStr);
                     setExpandedPrayer(null);
                   }}
                 >
                    <Text style={[styles.dateName, isSelected && {color: 'white'}, (!isSelected && hasMissed) && {color: THEME.error}]}>{isToday ? 'TODAY' : dayName.toUpperCase()}</Text>
                    <Text style={[styles.dateNum, isSelected && {color: 'white'}, (!isSelected && hasMissed) && {color: THEME.error}]}>{dayNum}</Text>
                    {isSelected ? (
                       <View style={styles.dateDot} />
                    ) : (
                       hasMissed && <View style={[styles.dateDot, { backgroundColor: THEME.error }]} />
                    )}
                 </TouchableOpacity>
               );
            })}
         </ScrollView>
      </View>
    );
  };

  const renderMissedBanner = () => {
    const isPast = new Date(selectedDate).getTime() < new Date(new Date().toDateString()).getTime();
    if (!isPast) return null;

    const missed = OBLIGATORY.filter(p => {
        const fRecord = history[selectedDate]?.[p]?.fard;
        return fRecord !== 'jamat' && fRecord !== 'single' && fRecord !== 'qaza';
    });

    if (missed.length === 0) return null;

    return (
        <View style={styles.missedBanner}>
            <Feather name="alert-octagon" size={18} color="white" style={{marginRight: 8}} />
            <Text style={styles.missedBannerText}>
                Fard Left: {missed.join(', ')}
            </Text>
        </View>
    );
  };

  const renderPrayerList = () => {
    const dayData = history[selectedDate] || {};

    return (
      <View style={styles.listSection}>
          {renderDateScroller()}
          {renderMissedBanner()}
          <View style={{height: 10}} />
          
          {OBLIGATORY.map((prayer) => {
              const isExpanded = expandedPrayer === prayer;
              const pData = dayData[prayer] || {};
              const fardSet = pData.fard; // 'jamat' | 'single' | 'qaza' | undefined
              const isComplete = fardSet === 'jamat' || fardSet === 'single' || fardSet === 'qaza';
              const time = timings ? timings[prayer] : '--:--';
              
              return (
                <View key={prayer} style={styles.prayerCard}>
                    <TouchableOpacity 
                      style={styles.prayerRow}
                      activeOpacity={0.7}
                      onPress={() => {
                        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                        setExpandedPrayer(isExpanded ? null : prayer);
                      }}
                    >
                          <View style={styles.prayerInfo}>
                              <View style={[styles.customCheck, isComplete && styles.customCheckActive]}>
                                  {isComplete && <Feather name="check" size={20} color="#FFF" />}
                              </View>
                              <View>
                                  <Text style={[styles.prayerName, isComplete && styles.prayerNameChecked]}>{prayer}</Text>
                                  <Text style={styles.prayerSub}>{isComplete ? fardSet.toUpperCase() : 'Not Yet Prayed'}</Text>
                              </View>
                          </View>
                          <View style={styles.timeLabel}>
                              <Text style={styles.timeText}>{time.split(' ')[0]}</Text>
                              <Feather name={isExpanded ? "chevron-up" : "chevron-down"} size={20} color={THEME.textLight} style={{marginTop: 4}} />
                          </View>
                    </TouchableOpacity>

                    {isExpanded && (
                       <View style={styles.expandedContent}>
                           <View style={styles.expSection}>
                               <Text style={styles.expLabel}>FARD (Obligatory)</Text>
                               <View style={styles.expOptions}>
                                   <TouchableOpacity 
                                     style={[styles.miniBtn, fardSet === 'jamat' && styles.miniBtnActive]}
                                     onPress={() => handleUpdateLayer(prayer, 'fard', 'jamat')}
                                   >
                                      <Text style={[styles.miniBtnText, fardSet === 'jamat' && {color: 'white'}]}>Jama'at</Text>
                                   </TouchableOpacity>
                                   <TouchableOpacity 
                                     style={[styles.miniBtn, fardSet === 'single' && styles.miniBtnActive]}
                                     onPress={() => handleUpdateLayer(prayer, 'fard', 'single')}
                                   >
                                      <Text style={[styles.miniBtnText, fardSet === 'single' && {color: 'white'}]}>Single</Text>
                                   </TouchableOpacity>
                                   <TouchableOpacity 
                                     style={[styles.miniBtn, fardSet === 'qaza' && styles.miniBtnActive]}
                                     onPress={() => handleUpdateLayer(prayer, 'fard', 'qaza')}
                                   >
                                      <Text style={[styles.miniBtnText, fardSet === 'qaza' && {color: 'white'}]}>Qaza (Made Up)</Text>
                                   </TouchableOpacity>
                               </View>
                           </View>
                           
                           <View style={styles.expDivider} />

                           <View style={styles.expRow}>
                                <Text style={styles.expLabel}>SUNNAH PRAYED?</Text>
                                <TouchableOpacity 
                                     style={[styles.toggleBtn, pData.sunnah && styles.toggleBtnActive]}
                                     onPress={() => handleUpdateLayer(prayer, 'sunnah', null)}
                                >
                                     {pData.sunnah ? <Feather name="check" size={16} color="#FFF" /> : <View />}
                                </TouchableOpacity>
                           </View>

                           <View style={styles.expDivider} />

                           <View style={styles.expRow}>
                                <Text style={styles.expLabel}>NAFL PRAYED?</Text>
                                <TouchableOpacity 
                                     style={[styles.toggleBtn, pData.nafl && styles.toggleBtnActive]}
                                     onPress={() => handleUpdateLayer(prayer, 'nafl', null)}
                                >
                                     {pData.nafl ? <Feather name="check" size={16} color="#FFF" /> : <View />}
                                </TouchableOpacity>
                           </View>
                           
                           {prayer === 'Isha' && (
                             <>
                               <View style={styles.expDivider} />
                               <View style={styles.expRow}>
                                    <Text style={styles.expLabel}>WAJIB (WITR) PRAYED?</Text>
                                    <TouchableOpacity 
                                         style={[styles.toggleBtn, pData.wajib && styles.toggleBtnActive]}
                                         onPress={() => handleUpdateLayer(prayer, 'wajib', null)}
                                    >
                                         {pData.wajib ? <Feather name="check" size={16} color="#FFF" /> : <View />}
                                    </TouchableOpacity>
                               </View>
                             </>
                           )}
                       </View>
                    )}
                </View>
              );
          })}

          <View style={styles.sunnahSection}>
              <Text style={styles.sectionSubtitle}>Sunnah Timings Output</Text>
              {SUNNAH.map((item) => (
                  <View key={item} style={styles.sunnahRow}>
                      <Text style={styles.sunnahName}>{item}</Text>
                      <Text style={styles.sunnahTime}>{timings ? timings[item].split(' ')[0] : '--:--'}</Text>
                  </View>
              ))}
          </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar translucent backgroundColor="transparent" barStyle="light-content" />
      {renderHeader()}
      
      {loading ? (
        <View style={styles.loadingBox}>
          <ActivityIndicator size="large" color={THEME.primary} />
          <Text style={styles.loadingText}>Calibrating timings...</Text>
        </View>
      ) : (
        <Animated.ScrollView 
          onScroll={Animated.event(
            [{ nativeEvent: { contentOffset: { y: scrollY } } }],
            { useNativeDriver: true }
          )}
          scrollEventThrottle={16}
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
        >
          <View style={{ height: 400 }} />
          {renderPrayerList()}
          <View style={{ height: 100 }} />
        </Animated.ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: THEME.background },
  loadingBox: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingText: { marginTop: 12, fontWeight: '700', color: THEME.primary },
  
  heroHeader: { position: 'absolute', top: 0, left: 0, right: 0, height: 400, zIndex: 10 },
  heroGradient: { flex: 1, borderBottomLeftRadius: 40, borderBottomRightRadius: 40, ...SHADOWS.premium },
  heroSafe: { flex: 1, paddingHorizontal: 20 },
  heroNav: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: Platform.OS === 'ios' ? 10 : StatusBar.currentHeight + 10 },
  backBtn: { width: 44, height: 44, borderRadius: 22, backgroundColor: 'rgba(255,255,255,0.2)', justifyContent: 'center', alignItems: 'center' },
  locationContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.2)', paddingHorizontal: 16, paddingVertical: 10, borderRadius: 20, maxWidth: width * 0.6 },
  locationText: { color: 'white', fontSize: 13, fontWeight: '800' },
  
  searchContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.2)', borderRadius: 22, paddingHorizontal: 16, height: 44, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)' },
  searchInput: { flex: 1, color: 'white', fontWeight: '700', fontSize: 16 },
  suggestionsContainer: { position: 'absolute', top: 55, left: 0, right: 0, backgroundColor: 'rgba(15, 23, 42, 0.96)', borderRadius: 15, padding: 8, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)', zIndex: 1000, ...SHADOWS.premium },
  suggestionItem: { paddingVertical: 14, paddingHorizontal: 15, borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.05)' },
  suggestionText: { color: '#FFF', fontSize: 14, fontWeight: '800' },
  suggestionSubText: { color: 'rgba(255,255,255,0.5)', fontSize: 12, fontWeight: '600' },

  heroContent: { alignItems: 'center', marginTop: 30 },
  countTitle: { color: 'rgba(255,255,255,0.8)', fontSize: 16, fontWeight: '700', marginBottom: 8 },
  countTimer: { color: 'white', fontSize: 64, fontWeight: '900', letterSpacing: -2 },
  countSub: { color: 'rgba(255,255,255,0.7)', fontSize: 14, fontWeight: '500' },

  progressContainer: { position: 'absolute', bottom: 40, left: 20, right: 20 },
  progressBarBg: { height: 10, backgroundColor: 'rgba(255,255,255,0.2)', borderRadius: 5, overflow: 'hidden' },
  progressBarFill: { height: '100%', backgroundColor: 'white', borderRadius: 5 },
  progressLabel: { color: 'white', fontSize: 10, fontWeight: '800', textTransform: 'uppercase', marginTop: 8, letterSpacing: 1 },

  scroll: { flex: 1 },
  scrollContent: { paddingHorizontal: 20 },
  
  // -- Calendar Widget --
  calendarContainer: { marginTop: -10 },
  calendarHeader: { fontSize: 20, fontWeight: '900', color: THEME.text, marginBottom: 12, paddingHorizontal: 4 },
  calendarScroll: { paddingVertical: 5 },
  dateCard: { width: 60, height: 85, borderRadius: 20, backgroundColor: '#FFFFFF', justifyContent: 'center', alignItems: 'center', marginRight: 12, borderWidth: 1, borderColor: THEME.border, ...SHADOWS.subtle },
  dateCardActive: { backgroundColor: THEME.primary, borderColor: THEME.primary, ...SHADOWS.medium },
  dateName: { fontSize: 11, fontWeight: '800', color: THEME.textLight, marginBottom: 4 },
  dateNum: { fontSize: 22, fontWeight: '900', color: THEME.text },
  dateDot: { width: 4, height: 4, borderRadius: 2, backgroundColor: 'white', position: 'absolute', bottom: 10 },

  missedBanner: { flexDirection: 'row', backgroundColor: THEME.error, padding: 16, borderRadius: 16, alignItems: 'center', marginTop: 15, marginBottom: 5 },
  missedBannerText: { color: 'white', fontWeight: '800', fontSize: 15, flex: 1 },

  // -- Tracker List --
  listSection: { marginTop: 10 },
  prayerCard: { backgroundColor: '#FFFFFF', borderRadius: 24, marginBottom: 12, borderWidth: 1, borderColor: THEME.border, overflow: 'hidden', ...SHADOWS.subtle },
  prayerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 20 },
  prayerInfo: { flexDirection: 'row', alignItems: 'center' },
  customCheck: { width: 46, height: 46, borderRadius: 16, backgroundColor: THEME.inputBg, marginRight: 16, justifyContent: 'center', alignItems: 'center', borderWidth: 2, borderColor: 'transparent' },
  customCheckActive: { backgroundColor: THEME.primary, borderColor: THEME.primary },
  
  prayerName: { fontSize: 18, fontWeight: '800', color: THEME.text },
  prayerNameChecked: { color: THEME.primary },
  prayerSub: { fontSize: 12, color: THEME.textLight, marginTop: 2, fontWeight: '700' },
  
  timeLabel: { alignItems: 'flex-end', justifyContent: 'center' },
  timeText: { fontSize: 18, fontWeight: '900', color: THEME.text },

  // -- Accordion Content --
  expandedContent: { paddingHorizontal: 20, paddingBottom: 20, paddingTop: 5, backgroundColor: '#FAFAFA' },
  expSection: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginVertical: 10 },
  expRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginVertical: 8 },
  expLabel: { fontSize: 13, fontWeight: '800', color: THEME.textLight },
  expOptions: { flexDirection: 'row', backgroundColor: THEME.inputBg, borderRadius: 12, padding: 4 },
  miniBtn: { paddingHorizontal: 16, paddingVertical: 8, borderRadius: 8 },
  miniBtnActive: { backgroundColor: THEME.primary, ...SHADOWS.subtle },
  miniBtnText: { fontSize: 12, fontWeight: '800', color: THEME.textLight },
  toggleBtn: { width: 32, height: 32, borderRadius: 10, backgroundColor: THEME.border, justifyContent: 'center', alignItems: 'center' },
  toggleBtnActive: { backgroundColor: THEME.primary },
  expDivider: { height: 1, backgroundColor: THEME.border, width: '100%', marginVertical: 8 },

  sunnahSection: { marginTop: 20, backgroundColor: THEME.inputBg, borderRadius: 24, padding: 20 },
  sectionSubtitle: { fontSize: 16, fontWeight: '800', color: THEME.text, marginBottom: 15 },
  sunnahRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 10 },
  sunnahName: { color: THEME.textLight, fontWeight: '700' },
  sunnahTime: { color: THEME.text, fontWeight: '800' }
});
