import { describe, it, expect, beforeEach, vi } from 'vitest';
import './api-config.js'; // Ensure global constants like API_CONFIG are available
import './api-service.js';

// Mock localStorage
const localStorageMock = (() => {
    let store = {};
    return {
        getItem: vi.fn(key => store[key] || null),
        setItem: vi.fn((key, value) => { store[key] = value.toString(); }),
        removeItem: vi.fn(key => { delete store[key]; }),
        clear: vi.fn(() => { store = {}; })
    };
})();
Object.defineProperty(window, 'localStorage', { value: localStorageMock });

// Mock fetch
global.fetch = vi.fn();

describe('ApiService', () => {
    const ApiService = window.ApiService;

    beforeEach(() => {
        vi.clearAllMocks();
        localStorageMock.clear();
    });

    it('should set and get token', () => {
        ApiService.setToken('test-token');
        expect(localStorageMock.setItem).toHaveBeenCalledWith('mediminder_token', 'test-token');
        expect(ApiService.getToken()).toBe('test-token');
    });

    it('should remove token', () => {
        ApiService.setToken('test-token');
        ApiService.removeToken();
        expect(localStorageMock.removeItem).toHaveBeenCalledWith('mediminder_token');
        expect(ApiService.getToken()).toBeNull();
    });

    describe('HTTP Requests', () => {
        it('should perform a successful GET request', async () => {
            const mockData = { success: true };
            fetch.mockResolvedValueOnce({
                ok: true,
                text: () => Promise.resolve(JSON.stringify(mockData))
            });

            const result = await ApiService.get('/test-endpoint');

            expect(fetch).toHaveBeenCalledWith(
                expect.stringContaining('/test-endpoint'),
                expect.objectContaining({ method: 'GET' })
            );
            expect(result).toEqual(mockData);
        });

        it('should throw error on failed request', async () => {
            fetch.mockResolvedValueOnce({
                ok: false,
                status: 401,
                json: () => Promise.resolve({ error: 'Unauthorized' })
            });

            await expect(ApiService.get('/secure')).rejects.toThrow('Unauthorized');
        });
    });
});
