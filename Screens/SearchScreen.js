import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';

export default function SearchScreen({ navigate }) {
  const [q, setQ] = useState('');
  const results = [
    { id: 1, title: 'Al-Fatiha 1:1', type: 'Quran' },
    { id: 2, title: 'Hadith on Prayer', type: 'Hadith' },
  ];
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Search</Text>
      <TextInput placeholder="Search in Quran and Hadith" value={q} onChangeText={setQ} style={styles.input} />
      {results.map((r) => (
        <TouchableOpacity key={r.id} style={styles.result} onPress={() => alert('Open ' + r.title)}>
          <Text style={styles.resultTitle}>{r.title}</Text>
          <Text style={styles.resultType}>{r.type}</Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16 },
  title: { fontSize: 28, fontWeight: '700', color: '#111' },
  input: { marginTop: 12, height: 40, borderColor: '#ddd', borderWidth: 1, borderRadius: 8, paddingHorizontal: 12 },
  result: { paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#eee' },
  resultTitle: { fontSize: 16, fontWeight: '700' },
  resultType: { fontSize: 12, color: '#555' },
});
