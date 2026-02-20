/* ============================================
   MediMinder – Backend API Service
   Replaces Supabase with Spring Boot Backend
   ============================================ */

const ApiService = {
    // ── Token Management ─────────────────────
    getToken() {
        return localStorage.getItem(TOKEN_KEY);
    },

    setToken(token) {
        localStorage.setItem(TOKEN_KEY, token);
    },

    removeToken() {
        localStorage.removeItem(TOKEN_KEY);
    },

    // ── HTTP Helpers ─────────────────────────
    async request(endpoint, options = {}) {
        const url = `${API_CONFIG.baseUrl}${endpoint}`;
        const token = this.getToken();

        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        const config = {
            ...options,
            headers
        };

        try {
            const response = await fetch(url, config);

            if (!response.ok) {
                const error = await response.json().catch(() => ({ error: 'Request failed' }));
                throw new Error(error.error || `HTTP ${response.status}`);
            }

            // Handle empty responses
            const text = await response.text();
            return text ? JSON.parse(text) : null;
        } catch (error) {
            console.error(`[API] Error calling ${endpoint}:`, error);
            throw error;
        }
    },

    async get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    },

    async post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    },

    async put(endpoint, data) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
    },

    async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    },

    // ── Authentication ───────────────────────
    async register(email, password) {
        const response = await this.post('/auth/register', { email, password });
        if (response.token) {
            this.setToken(response.token);
        }
        return response;
    },

    async login(email, password) {
        const response = await this.post('/auth/login', { email, password });
        if (response.token) {
            this.setToken(response.token);
        }
        return response;
    },

    async googleLogin(email, googleId, fullName) {
        const response = await this.post('/auth/google', { email, googleId, fullName });
        if (response.token) {
            this.setToken(response.token);
        }
        return response;
    },

    async getCurrentUser() {
        return this.get('/auth/me');
    },

    logout() {
        this.removeToken();
    },

    // ── Medications ──────────────────────────
    async getMedications() {
        return this.get('/medications');
    },

    async saveMedications(medications) {
        return this.post('/medications', medications);
    },

    async deleteAllMedications() {
        return this.delete('/medications');
    },

    // ── Medication Logs ──────────────────────
    async getMedLogs() {
        return this.get('/med-logs');
    },

    async saveMedLogs(logs) {
        return this.post('/med-logs', logs);
    },

    async deleteAllMedLogs() {
        return this.delete('/med-logs');
    },

    // ── Appointments ─────────────────────────
    async getAppointments() {
        return this.get('/appointments');
    },

    async saveAppointments(appointments) {
        return this.post('/appointments', appointments);
    },

    async deleteAllAppointments() {
        return this.delete('/appointments');
    },

    // ── Health Check ─────────────────────────
    async healthCheck() {
        return this.get('/health');
    }
};

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.ApiService = ApiService;
}
