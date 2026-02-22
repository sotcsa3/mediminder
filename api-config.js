/* ============================================
   MediMinder – Backend API Configuration
   Replaces Supabase with Spring Boot Backend
   ============================================ */

// Configuration constants
// For production, change these values or use environment variables
// API version v1 - all endpoints are versioned
const API_BASE_URL = window.API_BASE_URL || (window.location.protocol === 'https:' ? '/api/v1' : 'http://localhost:8080/api/v1');

// Google OAuth Client ID - REQUIRED for Google login
// Get your own client ID from Google Cloud Console
// See: https://developers.google.com/identity/sign-in/web/getting-started
const GOOGLE_CLIENT_ID = window.GOOGLE_CLIENT_ID || '82374151917-ari80p75dqshq1hs9idjf9sm9efl4pdl.apps.googleusercontent.com';

// Token storage key
const TOKEN_KEY = 'mediminder_token';

// API Configuration
const API_CONFIG = {
    baseUrl: API_BASE_URL,
    googleClientId: GOOGLE_CLIENT_ID,
    timeout: 10000, // 10 seconds
    retries: 3
};

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.API_CONFIG = API_CONFIG;
    window.TOKEN_KEY = TOKEN_KEY;
}
