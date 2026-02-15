/* ============================================
   MediMinder – Supabase Configuration
   ============================================ */

const SUPABASE_URL = 'https://unbjzngsvdpedxqfjkpf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVuYmp6bmdzdmRwZWR4cWZqa3BmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExODQ0NDMsImV4cCI6MjA4Njc2MDQ0M30.TybA3SWPy6_8Mmq2GTyD1nQIs3C1euSmITjD7_M0J_E';

// Initialize Supabase client
const supabaseClient = (window.supabase && window.supabase.createClient)
    ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    : null;

if (!supabaseClient) {
    console.error('Supabase client not initialized. Make sure the SDK script is loaded.');
} else {
    console.log('[Supabase] Initialized');
}
