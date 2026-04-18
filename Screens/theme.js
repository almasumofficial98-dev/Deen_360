export const THEME = {
  primary: '#10B981',       // Vivid Emerald from Main App
  primaryDark: '#059669',   // Darker Emerald for Gradients
  primaryLight: '#ECFDF5',  // Soft Mint background
  
  // Qwik Deen Library Palette (For Hadiths)
  qwikGreen: '#1E7F3D',     // Solid dark green background
  qwikCream: '#FDF8EE',     // Pale cream/yellow for cards
  qwikNavy: '#1E293B',      // Dark navy text
  qwikYellow: '#FCD34D',    // Mustard yellow buttons

  // Standard Colors
  background: '#FFFFFF',
  surface: '#F9FAFB',
  card: '#FFFFFF',
  
  // Text Colors
  text: '#111827',          // Dark slate black
  textLight: '#6B7280',     // Muted gray
  textMuted: '#9CA3AF',
  
  // UI Elements
  border: '#E5E7EB',        // Thin 1px dividers
  inputBg: '#F3F4F6',       // Form input backgrounds
  
  // Status Colors
  success: '#10B981',
  error: '#EF4444',         // Red used for Log Out
  white: '#FFFFFF',
};

export const SHADOWS = {
  soft: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 15,
    elevation: 2,
  },
  // Used sparingly for prominent floating buttons
  floating: {
    shadowColor: THEME.primaryDark,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.2,
    shadowRadius: 20,
    elevation: 8,
  },
};

export const GRADIENTS = {
  primary: ['#10B981', '#059669'],          // Default Emerald Gradient
  qwik: ['#1E7F3D', '#166534'],             // Qwik Deen Gradient Variant
  sunset: ['#F59E0B', '#EF4444'],           // For dynamic Next Prayer Screen
  night: ['#1E1B4B', '#312E81'],            // Indigo Night Gradient
  dawn: ['#0EA5E9', '#38BDF8'],             // Bright Sky Blue
};

export const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const RADIUS = {
  card: 24,         // Bubble aesthetic for cards
  modal: 32,        // Bottom sheets
  pill: 100,        // Fully rounded buttons
  input: 16,        // Smooth inputs
};

export const TYPOGRAPHY = {
  heading: {
    fontSize: 28,
    fontWeight: '800',
    color: THEME.text,
  },
  subheading: {
    fontSize: 20,
    fontWeight: '700',
    color: THEME.text,
  },
  body: {
    fontSize: 16,
    fontWeight: '500',
    color: THEME.text,
  },
  caption: {
    fontSize: 14,
    fontWeight: '500',
    color: THEME.textLight,
  },
  small: {
    fontSize: 12,
    fontWeight: '500',
    color: THEME.textMuted,
  },
};