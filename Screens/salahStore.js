import AsyncStorage from '@react-native-async-storage/async-storage';

export const saveUserLocation = async (locationData) => {
  try {
    await AsyncStorage.setItem('deen360_user_location', JSON.stringify(locationData));
  } catch (e) {
    console.error('Error saving location', e);
  }
};

export const getUserLocation = async () => {
  try {
    const data = await AsyncStorage.getItem('deen360_user_location');
    return data ? JSON.parse(data) : null;
  } catch (e) {
    console.error('Error reading location', e);
    return null;
  }
};

export const getSalahTimingsByCoordinates = async (lat, lng) => {
  try {
    const d = new Date();
    const dateStr = `${d.getDate()}-${d.getMonth() + 1}-${d.getFullYear()}`;
    const res = await fetch(`http://api.aladhan.com/v1/timings/${dateStr}?latitude=${lat}&longitude=${lng}&method=2`);
    if (!res.ok) throw new Error("API failed");
    const json = await res.json();
    return json?.data?.timings || null;
  } catch (err) {
    console.error("Salah By Coordinates error", err);
    return null;
  }
};

export const getSalahTimingsByCity = async (city, country = '') => {
  try {
    const res = await fetch(`http://api.aladhan.com/v1/timingsByCity?city=${encodeURIComponent(city)}&country=${encodeURIComponent(country)}&method=2`);
    if (!res.ok) throw new Error("API failed");
    const json = await res.json();
    return json?.data?.timings || null;
  } catch (err) {
    console.error("Salah By City error", err);
    return null;
  }
};
