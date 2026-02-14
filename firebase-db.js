/* ============================================
   MediMinder – Firebase Data Layer
   Replaces localStorage-only DB with Firestore + localStorage cache
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
    _unsubscribers: [],

    isLoggedIn() {
        return !!this._userId;
    },

    _userCollection(collectionName) {
        return db.collection('users').doc(this._userId).collection(collectionName);
    },

    // ── Firestore sync helpers ───────────────
    async _loadFromFirestore(collectionName, localKey) {
        if (!this._userId) return;
        try {
            const snapshot = await this._userCollection(collectionName).get();
            const items = [];
            snapshot.forEach(doc => {
                items.push({ id: doc.id, ...doc.data() });
            });
            this._localSet(localKey, items);
            return items;
        } catch (e) {
            console.error(`[DB] Error loading ${collectionName}:`, e);
            return this._localGet(localKey) || [];
        }
    },

    async _saveToFirestore(collectionName, item) {
        if (!this._userId) return;
        try {
            await this._userCollection(collectionName).doc(item.id).set(item);
        } catch (e) {
            console.error(`[DB] Error saving to ${collectionName}:`, e);
        }
    },

    async _deleteFromFirestore(collectionName, itemId) {
        if (!this._userId) return;
        try {
            await this._userCollection(collectionName).doc(itemId).delete();
        } catch (e) {
            console.error(`[DB] Error deleting from ${collectionName}:`, e);
        }
    },

    async _syncCollectionToFirestore(collectionName, items) {
        if (!this._userId) return;
        try {
            const batch = db.batch();
            const collRef = this._userCollection(collectionName);

            // Delete all existing docs first
            const existing = await collRef.get();
            existing.forEach(doc => batch.delete(doc.ref));

            // Add all current items
            items.forEach(item => {
                batch.set(collRef.doc(item.id), item);
            });

            await batch.commit();
        } catch (e) {
            console.error(`[DB] Error syncing ${collectionName}:`, e);
        }
    },

    // ── Real-time listeners ──────────────────
    _startListening() {
        if (!this._userId) return;

        // Listen for medication changes
        const unsubMeds = this._userCollection('medications')
            .onSnapshot(snapshot => {
                const items = [];
                snapshot.forEach(doc => items.push({ id: doc.id, ...doc.data() }));
                this._localSet(this.KEYS.MEDICATIONS, items);
                this._notifyListeners('medications');
            }, err => console.error('[DB] Medications listener error:', err));

        // Listen for med log changes
        const unsubLogs = this._userCollection('medLogs')
            .onSnapshot(snapshot => {
                const items = [];
                snapshot.forEach(doc => items.push({ id: doc.id, ...doc.data() }));
                this._localSet(this.KEYS.MED_LOGS, items);
                this._notifyListeners('medLogs');
            }, err => console.error('[DB] MedLogs listener error:', err));

        // Listen for appointment changes
        const unsubAppts = this._userCollection('appointments')
            .onSnapshot(snapshot => {
                const items = [];
                snapshot.forEach(doc => items.push({ id: doc.id, ...doc.data() }));
                this._localSet(this.KEYS.APPOINTMENTS, items);
                this._notifyListeners('appointments');
            }, err => console.error('[DB] Appointments listener error:', err));

        this._unsubscribers = [unsubMeds, unsubLogs, unsubAppts];
    },

    _stopListening() {
        this._unsubscribers.forEach(unsub => unsub());
        this._unsubscribers = [];
    },

    _notifyListeners(type) {
        this._listeners.forEach(fn => fn(type));
    },

    onDataChange(callback) {
        this._listeners.push(callback);
    },

    // ── Migration: localStorage → Firestore ─
    async _migrateToFirestore() {
        if (!this._userId) return;

        // Check if user already has data in Firestore
        const medsSnapshot = await this._userCollection('medications').limit(1).get();
        if (!medsSnapshot.empty) {
            console.log('[DB] User already has Firestore data, skipping migration');
            return;
        }

        // Migrate local data to Firestore
        const localMeds = this._localGet(this.KEYS.MEDICATIONS) || [];
        const localLogs = this._localGet(this.KEYS.MED_LOGS) || [];
        const localAppts = this._localGet(this.KEYS.APPOINTMENTS) || [];

        if (localMeds.length === 0 && localLogs.length === 0 && localAppts.length === 0) {
            console.log('[DB] No local data to migrate');
            return;
        }

        console.log(`[DB] Migrating ${localMeds.length} meds, ${localLogs.length} logs, ${localAppts.length} appointments`);

        await Promise.all([
            this._syncCollectionToFirestore('medications', localMeds),
            this._syncCollectionToFirestore('medLogs', localLogs),
            this._syncCollectionToFirestore('appointments', localAppts),
        ]);

        // Save user profile
        const localUser = this._localGet(this.KEYS.USER);
        if (localUser) {
            await db.collection('users').doc(this._userId).set({
                name: localUser.name,
                email: auth.currentUser?.email || ''
            }, { merge: true });
        }

        console.log('[DB] Migration complete!');
    },

    // ── Auth lifecycle ───────────────────────
    async onLogin(userId) {
        this._userId = userId;
        console.log('[DB] User logged in:', userId);

        // Migrate any existing local data
        await this._migrateToFirestore();

        // Load data from Firestore into localStorage cache
        await Promise.all([
            this._loadFromFirestore('medications', this.KEYS.MEDICATIONS),
            this._loadFromFirestore('medLogs', this.KEYS.MED_LOGS),
            this._loadFromFirestore('appointments', this.KEYS.APPOINTMENTS),
        ]);

        // Load user profile
        try {
            const userDoc = await db.collection('users').doc(userId).get();
            if (userDoc.exists) {
                this._localSet(this.KEYS.USER, userDoc.data());
            }
        } catch (e) {
            console.error('[DB] Error loading user profile:', e);
        }

        // Start real-time sync
        this._startListening();
    },

    onLogout() {
        this._stopListening();
        this._userId = null;
        console.log('[DB] User logged out');
    },

    // ── Public API (same interface as before) ─

    getMedications() {
        return this._localGet(this.KEYS.MEDICATIONS) || [];
    },

    saveMedications(meds) {
        this._localSet(this.KEYS.MEDICATIONS, meds);
        if (this._userId) {
            this._syncCollectionToFirestore('medications', meds);
        }
    },

    getMedLogs() {
        return this._localGet(this.KEYS.MED_LOGS) || [];
    },

    saveMedLogs(logs) {
        this._localSet(this.KEYS.MED_LOGS, logs);
        if (this._userId) {
            this._syncCollectionToFirestore('medLogs', logs);
        }
    },

    getAppointments() {
        return this._localGet(this.KEYS.APPOINTMENTS) || [];
    },

    saveAppointments(appts) {
        this._localSet(this.KEYS.APPOINTMENTS, appts);
        if (this._userId) {
            this._syncCollectionToFirestore('appointments', appts);
        }
    },

    getUser() {
        return this._localGet(this.KEYS.USER) || { name: 'Kedves Felhasználó' };
    },

    saveUser(user) {
        this._localSet(this.KEYS.USER, user);
        if (this._userId) {
            db.collection('users').doc(this._userId).set(user, { merge: true })
                .catch(e => console.error('[DB] Error saving user:', e));
        }
    },

    // ── Admin API ────────────────────────────
    async admin_getAllUsers() {
        try {
            const snapshot = await db.collection('users').get();
            const users = [];
            snapshot.forEach(doc => {
                users.push({ uid: doc.id, ...doc.data() });
            });
            return users;
        } catch (e) {
            console.error('[DB Admin] Error loading users:', e);
            return [];
        }
    },

    async admin_getUserMedications(userId) {
        try {
            const snapshot = await db.collection('users').doc(userId).collection('medications').get();
            const items = [];
            snapshot.forEach(doc => items.push({ id: doc.id, ...doc.data() }));
            return items;
        } catch (e) {
            console.error('[DB Admin] Error loading medications:', e);
            return [];
        }
    },

    async admin_getUserMedLogs(userId) {
        try {
            const snapshot = await db.collection('users').doc(userId).collection('medLogs').get();
            const items = [];
            snapshot.forEach(doc => items.push({ id: doc.id, ...doc.data() }));
            return items;
        } catch (e) {
            console.error('[DB Admin] Error loading medLogs:', e);
            return [];
        }
    },

    async admin_getUserAppointments(userId) {
        try {
            const snapshot = await db.collection('users').doc(userId).collection('appointments').get();
            const items = [];
            snapshot.forEach(doc => items.push({ id: doc.id, ...doc.data() }));
            return items;
        } catch (e) {
            console.error('[DB Admin] Error loading appointments:', e);
            return [];
        }
    }
};
