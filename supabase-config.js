/* ============================================
   MediMinder – Supabase Configuration
   ============================================ */

const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

// Initialize Supabase client
const supabase = (window.supabase && window.supabase.createClient)
    ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    : null;

if (!supabase) {
    console.error('Supabase client not initialized. Make sure the SDK script is loaded.');
} else {
    console.log('[Supabase] Initialized');
}
