/* ============================================
   MediMinder – Backend API Configuration
   Replaces Supabase with Spring Boot Backend
   ============================================ */

// Configuration constants
const API_BASE_URL = 'http://localhost:8080/api';
const GOOGLE_CLIENT_ID = '82374151917-ari80p75dqshq1hs9idjf9sm9efl4pdl.apps.googleusercontent.com';

// Token storage key
const TOKEN_KEY = 'mediminder_token';

// API Configuration
const API_CONFIG = {
    baseUrl: API_BASE_URL,
    timeout: 10000, // 10 seconds
    retries: 3
};

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.API_CONFIG = API_CONFIG;
    window.TOKEN_KEY = TOKEN_KEY;
}
