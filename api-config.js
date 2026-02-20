/* ============================================
   MediMinder – Backend API Configuration
   Replaces Supabase with Spring Boot Backend
   ============================================ */

// API Base URL - Change this to your backend URL
const API_BASE_URL = 'http://localhost:8080/api';

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
