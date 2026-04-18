import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated, Text, TouchableOpacity } from 'react-native';
import { THEME } from './theme';

const ANIMATION_SPEED = 1500;

const SkeletonBase = ({ width: w, height: h, borderRadius = 8, style }) => {
  const opacity = useRef(new Animated.Value(0.3)).current;

  useEffect(() => {
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, {
          toValue: 0.8,
          duration: ANIMATION_SPEED / 2,
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0.3,
          duration: ANIMATION_SPEED / 2,
          useNativeDriver: true,
        }),
      ])
    );
    animation.start();
    return () => animation.stop();
  }, [opacity]);

  return (
    <Animated.View
      style={[
        { width: w, height: h, borderRadius, backgroundColor: '#E5E5E0' },
        { opacity },
        style,
      ]}
    />
  );
};

export const SurahListSkeleton = () => (
  <View style={styles.listContainer}>
    {Array.from({ length: 8 }).map((_, i) => (
      <View key={i} style={styles.surahCardSkeleton}>
        <SkeletonBase width={50} height={50} borderRadius={25} />
        <View style={styles.surahInfoSkeleton}>
          <SkeletonBase width="60%" height={20} borderRadius={4} />
          <View style={styles.metaRowSkeleton}>
            <SkeletonBase width={60} height={18} borderRadius={8} />
            <View style={{ width: 8 }} />
            <SkeletonBase width={70} height={18} borderRadius={8} />
          </View>
        </View>
      </View>
    ))}
  </View>
);

export const AyahListSkeleton = () => (
  <View style={styles.listContainer}>
    {Array.from({ length: 6 }).map((_, i) => (
      <View key={i} style={styles.ayahCardSkeleton}>
        <View style={styles.ayahHeaderSkeleton}>
          <SkeletonBase width={60} height={28} borderRadius={12} />
          <SkeletonBase width={36} height={36} borderRadius={18} />
        </View>
        <SkeletonBase width="100%" height={40} borderRadius={4} />
        <View style={{ height: 16 }} />
        <SkeletonBase width="100%" height={24} borderRadius={4} />
        <View style={{ height: 8 }} />
        <SkeletonBase width="80%" height={24} borderRadius={4} />
      </View>
    ))}
  </View>
);

export const HadithChaptersSkeleton = () => (
  <View style={styles.listContainer}>
    {Array.from({ length: 10 }).map((_, i) => (
      <View key={i} style={styles.chapterCardSkeleton}>
        <SkeletonBase width={44} height={44} borderRadius={22} />
        <SkeletonBase width="70%" height={24} borderRadius={4} style={{ marginLeft: 16 }} />
      </View>
    ))}
  </View>
);

export const HadithListSkeleton = () => (
  <View style={styles.listContainer}>
    {Array.from({ length: 4 }).map((_, i) => (
      <View key={i} style={styles.hadithCardSkeleton}>
        <View style={styles.hadithHeaderSkeleton}>
          <SkeletonBase width={120} height={32} borderRadius={16} />
          <SkeletonBase width={80} height={20} borderRadius={4} />
        </View>
        <View style={{ height: 16 }} />
        <SkeletonBase width="100%" height={20} borderRadius={4} />
        <View style={{ height: 8 }} />
        <SkeletonBase width="90%" height={20} borderRadius={4} />
        <View style={{ height: 16 }} />
        <SkeletonBase width="100%" height={48} borderRadius={4} />
        <View style={{ height: 12 }} />
        <SkeletonBase width="100%" height={24} borderRadius={4} />
        <View style={{ height: 8 }} />
        <SkeletonBase width="85%" height={24} borderRadius={4} />
      </View>
    ))}
  </View>
);

export const EmptyState = ({ icon = '📭', title = 'No data available', subtitle = '' }) => (
  <View style={styles.emptyContainer}>
    <Text style={styles.emptyIcon}>{icon}</Text>
    <Text style={styles.emptyTitle}>{title}</Text>
    {subtitle ? <Text style={styles.emptySubtitle}>{subtitle}</Text> : null}
  </View>
);

export const ErrorState = ({ message = 'Something went wrong', onRetry }) => (
  <View style={styles.errorContainer}>
    <Text style={styles.errorIcon}>⚠️</Text>
    <Text style={styles.errorTitle}>{message}</Text>
    {onRetry && (
      <TouchableOpacity style={styles.retryButton} onPress={onRetry}>
        <Text style={styles.retryText}>Try Again</Text>
      </TouchableOpacity>
    )}
  </View>
);

const styles = StyleSheet.create({
  listContainer: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 40,
  },
  surahCardSkeleton: {
    flexDirection: 'row',
    backgroundColor: THEME.card,
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    alignItems: 'center',
  },
  surahInfoSkeleton: {
    flex: 1,
    marginLeft: 16,
  },
  metaRowSkeleton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  ayahCardSkeleton: {
    backgroundColor: THEME.card,
    borderRadius: 24,
    padding: 24,
    marginBottom: 20,
  },
  ayahHeaderSkeleton: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  chapterCardSkeleton: {
    backgroundColor: THEME.card,
    borderRadius: 20,
    padding: 16,
    marginBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  hadithCardSkeleton: {
    backgroundColor: THEME.card,
    borderRadius: 24,
    padding: 24,
    marginBottom: 30,
  },
  hadithHeaderSkeleton: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 60,
    paddingHorizontal: 40,
  },
  emptyIcon: {
    fontSize: 60,
    marginBottom: 20,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: THEME.textLight,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 14,
    color: THEME.textMuted,
    textAlign: 'center',
    marginTop: 8,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 60,
    paddingHorizontal: 40,
  },
  errorIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: THEME.error,
    textAlign: 'center',
  },
  retryButton: {
    marginTop: 20,
    backgroundColor: THEME.primary,
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 16,
  },
  retryText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '700',
  },
});