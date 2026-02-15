/* ============================================
   MediMinder – Supabase Data Layer
   Replaces Firebase Firestore with Supabase (PostgreSQL) + localStorage cache
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
    _channels: [], // Realtime channels

    isLoggedIn() {
        return !!this._userId;
    },

    // ── Supabase sync helpers ────────────────
    async _loadFromSupabase(table, localKey) {
        if (!this._userId) return;
        try {
            const { data, error } = await supabase
                .from(table)
                .select('*')
                .eq('user_id', this._userId);

            if (error) throw error;

            // Normalize data if needed (e.g. handle jsonb fields)
            // Supabase returns objects directly, so we just need to ensure fields match application expectations
            this._localSet(localKey, data || []);
            return data || [];
        } catch (e) {
            console.error(`[DB] Error loading ${table}:`, e);
            return this._localGet(localKey) || [];
        }
    },

    async _saveToSupabase(table, item) {
        if (!this._userId) return;
        try {
            // Ensure user_id is set
            const itemToSave = { ...item, user_id: this._userId };

            const { error } = await supabase
                .from(table)
                .upsert(itemToSave);

            if (error) throw error;
        } catch (e) {
            console.error(`[DB] Error saving to ${table}:`, e);
        }
    },

    async _deleteFromSupabase(table, itemId) {
        if (!this._userId) return;
        try {
            const { error } = await supabase
                .from(table)
                .delete()
                .eq('id', itemId)
                .eq('user_id', this._userId); // Safety check

            if (error) throw error;
        } catch (e) {
            console.error(`[DB] Error deleting from ${table}:`, e);
        }
    },

    async _syncCollectionToSupabase(table, items) {
        if (!this._userId) return;
        if (items.length === 0) return;

        try {
            // Upsert all items
            // Note: Supabase upsert accepts an array
            const itemsToSave = items.map(item => ({ ...item, user_id: this._userId }));

            const { error } = await supabase
                .from(table)
                .upsert(itemsToSave);

            if (error) throw error;
        } catch (e) {
            console.error(`[DB] Error syncing ${table}:`, e);
        }
    },

    // ── Real-time listeners ──────────────────
    _listeners: [],

    _startListening() {
        if (!this._userId) return;
        this._stopListening(); // clean up if needed

        // Subscribe to changes for this user
        // We can use one channel for all tables or separate channels

        ['medications', 'med_logs', 'appointments'].forEach(table => {
            const channel = supabase
                .channel(`public:${table}:${this._userId}`)
                .on('postgres_changes',
                    { event: '*', schema: 'public', table: table, filter: `user_id=eq.${this._userId}` },
                    (payload) => {
                        console.log(`[DB] Change received for ${table}:`, payload);
                        // Refresh local data from server to ensure consistency
                        // Or we could apply the delta. For simplicity, reloading is safer for now.
                        this._reloadTable(table);
                    }
                )
                .subscribe();

            this._channels.push(channel);
        });
    },

    async _reloadTable(table) {
        let localKey = '';
        let type = '';

        if (table === 'medications') { localKey = this.KEYS.MEDICATIONS; type = 'medications'; }
        if (table === 'med_logs') { localKey = this.KEYS.MED_LOGS; type = 'medLogs'; } // Note: medLogs mapping
        if (table === 'appointments') { localKey = this.KEYS.APPOINTMENTS; type = 'appointments'; }

        if (localKey) {
            await this._loadFromSupabase(table, localKey);
            this._notifyListeners(type);
        }
    },

    _stopListening() {
        this._channels.forEach(channel => supabase.removeChannel(channel));
        this._channels = [];
    },

    _notifyListeners(type) {
        this._listeners.forEach(fn => fn(type));
    },

    onDataChange(callback) {
        this._listeners.push(callback);
    },

    // ── Migration: localStorage → Supabase ─
    async _migrateToSupabase() {
        if (!this._userId) return;

        // Check if user already has data in Supabase (check medications)
        const { count, error } = await supabase
            .from('medications')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', this._userId);

        if (count > 0) {
            console.log('[DB] User already has Supabase data, skipping migration');
            return;
        }

        // Migrate local data to Supabase
        const localMeds = this._localGet(this.KEYS.MEDICATIONS) || [];
        const localLogs = this._localGet(this.KEYS.MED_LOGS) || [];
        const localAppts = this._localGet(this.KEYS.APPOINTMENTS) || [];

        if (localMeds.length === 0 && localLogs.length === 0 && localAppts.length === 0) {
            console.log('[DB] No local data to migrate');
            return;
        }

        console.log(`[DB] Migrating ${localMeds.length} meds, ${localLogs.length} logs, ${localAppts.length} appointments`);

        await Promise.all([
            this._syncCollectionToSupabase('medications', localMeds),
            this._syncCollectionToSupabase('med_logs', localLogs),
            this._syncCollectionToSupabase('appointments', localAppts),
        ]);

        console.log('[DB] Migration complete!');
    },

    // ── Auth lifecycle ───────────────────────
    async onLogin(userId) {
        this._userId = userId;
        console.log('[DB] User logged in:', userId);

        // Migrate any existing local data
        await this._migrateToSupabase();

        // Load data from Supabase into localStorage cache
        await Promise.all([
            this._loadFromSupabase('medications', this.KEYS.MEDICATIONS),
            this._loadFromSupabase('med_logs', this.KEYS.MED_LOGS),
            this._loadFromSupabase('appointments', this.KEYS.APPOINTMENTS),
        ]);

        // Load user profile (if we fetch it from a users table or auth metadata)
        // For now, we can just use the auth info directly in app.js, or save a profile

        // Start real-time sync
        this._startListening();
    },

    onLogout() {
        this._stopListening();
        this._userId = null;
        console.log('[DB] User logged out');
    },

    // ── Public API ───────────────────────────

    getMedications() {
        return this._localGet(this.KEYS.MEDICATIONS) || [];
    },

    saveMedications(meds) {
        this._localSet(this.KEYS.MEDICATIONS, meds);
        if (this._userId) {
            // This is a full overwrite of the array in local state
            // But for Supabase upsert, we need to know what to delete if items were removed
            // Simplest strategy for now: Sync all. 
            // Better strategy: Use _saveToSupabase / _deleteFromSupabase for individual items in the UI logic,
            // but the current app logic passes the whole array.

            // To properly handle "saveMedications(allMeds)", we might need to find diffs.
            // Or we just upsert all current. Deleted items won't be deleted from server with upsert.
            // WE NEED TO HANDLE DELETIONS explicitly in the helper methods or modify the API.

            // Re-checking app.js usages:
            // - toggleMedTaken -> calls saveMedLogs(logs)
            // - delete (medications) -> calls saveMedications(remaining)
            // - openMedModal (save) -> calls saveMedications(meds) (pushes new or updates existing)

            // Since the app.js logic replaces the whole array, we have a challenge reconciling with SQL.
            // The Firebase implementation did: `existing.forEach(doc => batch.delete(doc.ref))` then `items.forEach(...)`
            // That wipes the collection for the user and rewrites. It's inefficient but safest for this architecture.

            this._overwriteCollection('medications', meds);
        }
    },

    saveMedLogs(logs) {
        this._localSet(this.KEYS.MED_LOGS, logs);
        if (this._userId) {
            this._overwriteCollection('med_logs', logs);
        }
    },

    getMedLogs() {
        return this._localGet(this.KEYS.MED_LOGS) || [];
    },

    getAppointments() {
        return this._localGet(this.KEYS.APPOINTMENTS) || [];
    },

    saveAppointments(appts) {
        this._localSet(this.KEYS.APPOINTMENTS, appts);
        if (this._userId) {
            this._overwriteCollection('appointments', appts);
        }
    },

    getUser() {
        return this._localGet(this.KEYS.USER) || { name: 'Kedves Felhasználó' };
    },

    saveUser(user) {
        this._localSet(this.KEYS.USER, user);
        // We don't have a users table hook set up strictly, but we can try to update auth metadata or a profiles table
        // For now, ignore server side user profile sync unless we add a 'users' table.
    },

    // Helper to brutally overwrite collection (like the Firebase implementation did)
    async _overwriteCollection(table, items) {
        if (!this._userId) return;

        // 1. Delete all for user (Optimizable: only delete those not in items)
        // But deleting all is risky if the save fails.
        // Let's try to delete items that are NOT in the new list.

        try {
            const currentIds = items.map(i => i.id);

            // Delete items not in the new list
            // "id" not in currentIds
            if (currentIds.length > 0) {
                await supabase
                    .from(table)
                    .delete()
                    .eq('user_id', this._userId)
                    .not('id', 'in', `(${currentIds.join(',')})`);
            } else {
                // If list is empty, delete everything
                await supabase
                    .from(table)
                    .delete()
                    .eq('user_id', this._userId);
            }

            // 2. Upsert all current items
            if (items.length > 0) {
                const itemsToSave = items.map(item => ({ ...item, user_id: this._userId }));
                await supabase.from(table).upsert(itemsToSave);
            }

        } catch (e) {
            console.error(`[DB] Error overwriting ${table}:`, e);
        }
    },

    // ── Admin API ────────────────────────────
    async admin_getAllUsers() {
        // Supabase Client SDK doesn't allow listing all users easily without Service Role Key.
        // We might need an Edge Function or just query the 'users' table if we maintain one.
        // Assuming we have a 'users' table that matchesauth.users via triggers (common Supabase pattern)
        try {
            // Try to fetch from a public profiles table if it exists
            // Or fail gracefully if we can't list users
            const { data, error } = await supabase.from('users').select('*');
            if (error) throw error;
            return data.map(u => ({ uid: u.id, ...u }));
        } catch (e) {
            console.error('[DB Admin] Error loading users:', e);
            return [];
        }
    },

    async admin_getUserMedications(userId) {
        try {
            const { data } = await supabase.from('medications').select('*').eq('user_id', userId);
            return data || [];
        } catch (e) {
            console.error('[DB Admin] Error loading medications:', e);
            return [];
        }
    },

    async admin_getUserMedLogs(userId) {
        try {
            const { data } = await supabase.from('med_logs').select('*').eq('user_id', userId);
            return data || [];
        } catch (e) {
            console.error('[DB Admin] Error loading medLogs:', e);
            return [];
        }
    },

    async admin_getUserAppointments(userId) {
        try {
            const { data } = await supabase.from('appointments').select('*').eq('user_id', userId);
            return data || [];
        } catch (e) {
            console.error('[DB Admin] Error loading appointments:', e);
            return [];
        }
    }
};
