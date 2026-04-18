import React, { useRef } from 'react';
import { View, Text, TouchableOpacity, TextInput, StyleSheet, Animated } from 'react-native';
import { THEME, SPACING, RADIUS, SHADOWS, GRADIENTS } from './theme';

// 1. Fully Rounded Pill Button (Used for "Next", "Save")
export const PillButton = ({ title, onPress, style, textStyle, color = THEME.primary, darkText = false }) => (
  <TouchableOpacity 
    style={[styles.pillButton, { backgroundColor: color }, style]} 
    onPress={onPress}
    activeOpacity={0.8}
    delayPressIn={100}
  >
    <Text style={[styles.pillButtonText, { color: darkText ? THEME.text : THEME.white }, textStyle]}>
      {title}
    </Text>
  </TouchableOpacity>
);

// 2. Cardless Flat List Item (For Surahs, Settings, Duas)
export const FlatListItem = ({ title, subtitle, icon, rightElement, onPress, hideDivider = false }) => (
  <TouchableOpacity 
    style={[styles.flatListItem, !hideDivider && styles.flatListDivider]} 
    onPress={onPress}
    activeOpacity={0.7}
    disabled={!onPress}
    delayPressIn={100}
  >
    {icon && <View style={styles.flatListIconContainer}>{icon}</View>}
    <View style={styles.flatListContent}>
      <Text style={styles.flatListTitle}>{title}</Text>
      {subtitle && <Text style={styles.flatListSubtitle}>{subtitle}</Text>}
    </View>
    {rightElement && <View>{rightElement}</View>}
  </TouchableOpacity>
);

// 3. Form Input Field (Pill-like, no border, light gray bg)
export const FormInput = ({ label, value, onChangeText, placeholder, secureTextEntry }) => (
  <View style={styles.inputContainer}>
    {label && <Text style={styles.inputLabel}>{label}</Text>}
    <TextInput
      style={styles.inputField}
      value={value}
      onChangeText={onChangeText}
      placeholder={placeholder}
      placeholderTextColor={THEME.textMuted}
      secureTextEntry={secureTextEntry}
    />
  </View>
);

// 4. Floating Overlay Card (Used in Map View, Hero overlaps)
export const FloatingOverlayCard = ({ children, style }) => (
  <View style={[styles.floatingCard, style]}>
    {children}
  </View>
);

// 5. Animated Playful Button (Scales down on press)
export const AnimatedScaleButton = ({ children, onPress, style }) => {
  const scale = useRef(new Animated.Value(1)).current;

  const handlePressIn = () => {
    Animated.spring(scale, {
      toValue: 0.92,
      useNativeDriver: true,
      speed: 20,
      bounciness: 10
    }).start();
  };

  const handlePressOut = () => {
    Animated.spring(scale, {
      toValue: 1,
      useNativeDriver: true,
      speed: 20,
      bounciness: 10
    }).start();
  };

  return (
    <TouchableOpacity 
      activeOpacity={1} 
      onPressIn={handlePressIn} 
      onPressOut={handlePressOut}
      onPress={onPress}
      delayPressIn={100}
    >
      <Animated.View style={[style, { transform: [{ scale }] }]}>
        {children}
      </Animated.View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  // Pill Button
  pillButton: {
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: RADIUS.pill,
    alignItems: 'center',
    justifyContent: 'center',
    ...SHADOWS.soft,
  },
  pillButtonText: {
    fontSize: 16,
    fontWeight: '800',
  },
  
  // Flat List Item
  flatListItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: SPACING.lg,
    backgroundColor: 'transparent',
  },
  flatListDivider: {
    borderBottomWidth: 1,
    borderBottomColor: THEME.border,
  },
  flatListIconContainer: {
    marginRight: SPACING.md,
  },
  flatListContent: {
    flex: 1,
  },
  flatListTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: THEME.text,
  },
  flatListSubtitle: {
    fontSize: 12,
    color: THEME.textLight,
    marginTop: 4,
  },
  
  // Form Input
  inputContainer: {
    marginBottom: SPACING.md,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: THEME.textLight,
    marginBottom: 6,
    marginLeft: 4,
  },
  inputField: {
    backgroundColor: THEME.inputBg,
    borderRadius: RADIUS.input,
    paddingHorizontal: SPACING.md,
    paddingVertical: 16,
    fontSize: 16,
    color: THEME.text,
    fontWeight: '500',
  },
  
  // Floating Card
  floatingCard: {
    backgroundColor: THEME.card,
    borderRadius: RADIUS.card,
    padding: SPACING.lg,
    ...SHADOWS.floating,
  }
});
