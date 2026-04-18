import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function ProfileScreen({ navigate }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Profile</Text>
      <Text style={styles.subtitle}>Guest</Text>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Deen360 User</Text>
        <Text style={styles.cardSubtitle}>demo@example.com</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16 },
  title: { fontSize: 28, fontWeight: '700', color: '#111' },
  subtitle: { fontSize: 14, color: '#666', marginBottom: 16 },
  card: { padding: 16, borderRadius: 12, backgroundColor: '#f5f5f5' },
  cardTitle: { fontSize: 16, fontWeight: '700' },
  cardSubtitle: { fontSize: 12, color: '#555' },
});
