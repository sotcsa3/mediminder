/* ============================================
   MediMinder – Backend Data Layer
   Replaces Supabase with Spring Boot Backend + localStorage cache
   ============================================ */

const DB = {
    KEYS: {
        MEDICATIONS: 'mediminder_medications',
        MED_LOGS: 'mediminder_med_logs',
        APPOINTMENTS: 'mediminder_appointments',
        USER: 'mediminder_user'
    },

    // ── Local cache helpers ──────────────────
    _localGet(key) {
        try {
            const data = localStorage.getItem(key);
            return data ? JSON.parse(data) : null;
        } catch { return null; }
    },

    _localSet(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        } catch (e) {
            console.error('Storage error:', e);
        }
    },

    // ── Auth state ───────────────────────────
    _userId: null,
    _listeners: [],

    isLoggedIn() {
        return !!this._userId && !!ApiService.getToken();
    },

    // ── Backend sync helpers ────────────────
    async _loadFromBackend(endpoint, localKey) {
        if (!this._userId) return;
        try {
            const data = await ApiService.get(endpoint);
            this._localSet(localKey, data || []);
            return data || [];
        } catch (e) {
            console.error(`[DB] Error loading ${endpoint}:`, e);
            return this._localGet(localKey) || [];
        }
    },

    async _saveToBackend(endpoint, items) {
        if (!this._userId) return;
        try {
            await ApiService.post(endpoint, items);
        } catch (e) {
            console.error(`[DB] Error saving to ${endpoint}:`, e);
        }
    },

    // ── Data change listeners ────────────────
    _notifyListeners(type) {
        this._listeners.forEach(fn => fn(type));
    },

    onDataChange(callback) {
        this._listeners.push(callback);
    },

    // ── Auth lifecycle ───────────────────────
    async onLogin(userId) {
        this._userId = userId;
        console.log('[DB] User logged in:', userId);

        // Load data from backend into localStorage cache
        await Promise.all([
            this._loadFromBackend('/medications', this.KEYS.MEDICATIONS),
            this._loadFromBackend('/med-logs', this.KEYS.MED_LOGS),
            this._loadFromBackend('/appointments', this.KEYS.APPOINTMENTS),
        ]);

        console.log('[DB] Data loaded from backend');
    },

    async onLogout() {
        this._userId = null;
        ApiService.logout();
        this._localSet(this.KEYS.MEDICATIONS, []);
        this._localSet(this.KEYS.MED_LOGS, []);
        this._localSet(this.KEYS.APPOINTMENTS, []);
        this._localSet(this.KEYS.USER, null);
        console.log('[DB] User logged out and local data cleared');
    },

    // ── Public API ───────────────────────────

    getMedications() {
        return this._localGet(this.KEYS.MEDICATIONS) || [];
    },

    async saveMedications(meds) {
        this._localSet(this.KEYS.MEDICATIONS, meds);
        if (this._userId) {
            await this._saveToBackend('/medications', meds);
        }
    },

    getMedLogs() {
        return this._localGet(this.KEYS.MED_LOGS) || [];
    },

    async saveMedLogs(logs) {
        this._localSet(this.KEYS.MED_LOGS, logs);
        if (this._userId) {
            await this._saveToBackend('/med-logs', logs);
        }
    },

    getAppointments() {
        return this._localGet(this.KEYS.APPOINTMENTS) || [];
    },

    async saveAppointments(appts) {
        this._localSet(this.KEYS.APPOINTMENTS, appts);
        if (this._userId) {
            await this._saveToBackend('/appointments', appts);
        }
    },

    getUser() {
        return this._localGet(this.KEYS.USER) || { name: 'Kedves Felhasználó' };
    },

    saveUser(user) {
        this._localSet(this.KEYS.USER, user);
    },

    // ── Admin API ────────────────────────────
    // Note: Admin functionality would require additional backend endpoints
    async admin_getAllUsers() {
        console.warn('[DB Admin] Admin API not implemented in backend yet');
        return [];
    },

    async admin_getUserMedications(userId) {
        console.warn('[DB Admin] Admin API not implemented in backend yet');
        return [];
    },

    async admin_getUserMedLogs(userId) {
        console.warn('[DB Admin] Admin API not implemented in backend yet');
        return [];
    },

    async admin_getUserAppointments(userId) {
        console.warn('[DB Admin] Admin API not implemented in backend yet');
        return [];
    }
};

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.DB = DB;
}
