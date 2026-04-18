import AsyncStorage from '@react-native-async-storage/async-storage';

/**
 * Calculates straight-line distance (haversine) between two coordinates in kilometers.
 */
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2); 
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); 
  const d = R * c; 
  return d;
}

/**
 * Fetches nearby Masjids securely over the free OSM Overpass API.
 * Employs heavy caching to prevent API abuse.
 * 
 * @param {number} lat - Latitude
 * @param {number} lng - Longitude
 * @param {number} radius - Search radius in meters (default 5000)
 */
export const fetchNearbyMasjids = async (lat, lng, radius = 5000) => {
  if (!lat || !lng) return [];

  const timestamp = Date.now();
  // v3 breaks timeout cache
  const cacheKey = `deen360_masjids_v3_${Math.floor(lat * 10)}_${Math.floor(lng * 10)}`;

  try {
    const cachedData = await AsyncStorage.getItem(cacheKey);
    if (cachedData) {
      const { data, timestamp: cacheTime } = JSON.parse(cachedData);
      // Valid cache for 24 hours to deeply respect Overpass zero-cost API guidelines
      if (timestamp - cacheTime < 24 * 60 * 60 * 1000) {
         console.log("Serving Masjids from Secure Cache");
         return processMasjidNodes(data.elements, lat, lng);
      }
    }

    // [out:json];node["amenity"="place_of_worship"]["religion"="muslim"](around:5000,lat,lng);out;
    const query = `
      [out:json][timeout:25];
      (
        nwr["amenity"="place_of_worship"]["religion"="muslim"](around:${radius},${lat},${lng});
        nwr["building"="mosque"](around:${radius},${lat},${lng});
      );
      out center;
    `;

    const response = await fetch('https://overpass-api.de/api/interpreter', {
      method: 'POST',
      body: 'data=' + encodeURIComponent(query),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache',
        'User-Agent': 'Deen360-React-Native-App' // Good practice for OSM Overpass
      }
    });

    if (!response.ok) {
       console.error("Overpass HTTP Error:", response.status);
       return [];
    }

    const json = await response.json();
    
    // Cache the raw elements payload heavily
    await AsyncStorage.setItem(cacheKey, JSON.stringify({ data: json, timestamp }));
    
    return processMasjidNodes(json.elements, lat, lng);
    
  } catch (error) {
    console.error("Masjid locator fetch error:", error);
    return [];
  }
};


/**
 * Normalizes OSM elements mapping distance calculations
 */
const processMasjidNodes = (elements, userLat, userLng, fallbackName = "Mosque") => {
    if (!elements || elements.length === 0) return [];
    
    const masjids = elements.map((item) => {
       const lat = item.lat || item.center?.lat;
       const lon = item.lon || item.center?.lon;
       const name = item.tags?.name || item.tags?.['name:en'] || fallbackName;
       
       const distance = getDistanceFromLatLonInKm(userLat, userLng, lat, lon);
       
       return {
          id: String(item.id),
          name: name,
          lat: lat,
          lon: lon,
          distance: distance, // in km
          tags: item.tags || {},
          address: item.tags?.['addr:full'] || item.tags?.['addr:street'] || item.tags?.['addr:city'] || ""
       };
    }).filter(m => m.lat && m.lon);

    return masjids.sort((a, b) => a.distance - b.distance);
};
