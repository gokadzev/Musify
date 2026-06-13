import axios from 'axios';
import { HttpsProxyAgent } from 'https-proxy-agent';
import { HttpProxyAgent } from 'http-proxy-agent';

/**
 * A standalone, robust Proxy Manager class that can be easily dropped into any Node.js project.
 * It fetches free public proxies from multiple sources, validates them before use,
 * and seamlessly rotates them to bypass IP blocks (like 429 errors).
 */
export class ProxyManager {
    constructor(options = {}) {
        this.proxies = new Set();
        this.workingProxies = [];
        this.lastFetch = 0;

        // Configurable options
        this.refreshIntervalMs = options.refreshIntervalMs || 30 * 60 * 1000; // Default 30 mins
        this.validationTimeoutMs = options.validationTimeoutMs || 5000;
        this.validationUrl = options.validationUrl || 'http://httpbin.org/ip';
        this.minProxyPoolSize = options.minProxyPoolSize || 10;
        this.isFetching = false;
    }

    /**
     * Initializes the proxy pool by fetching and validating proxies.
     */
    async init() {
        if (this.workingProxies.length < this.minProxyPoolSize) {
            await this._fetchFromAllSources();
        }
    }

    /**
     * Internal method to fetch proxies from various public lists.
     */
    async _fetchFromAllSources() {
        if (this.isFetching) return;
        this.isFetching = true;
        console.log("[ProxyManager] Fetching new proxies from public sources...");

        try {
            await Promise.allSettled([
                this._fetchProxyScrape(),
                this._fetchSpysMe(),
                this._fetchGeonode(),
                this._fetchOpenProxyList()
            ]);

            this.lastFetch = Date.now();
            console.log(`[ProxyManager] Total unique proxies collected: ${this.proxies.size}`);
        } catch (err) {
            console.error("[ProxyManager] Error fetching proxies:", err.message);
        } finally {
            this.isFetching = false;
        }
    }

    async _fetchProxyScrape() {
        try {
            const url = 'https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&proxy_format=protocolipport&format=json&protocol=http';
            const response = await axios.get(url, { timeout: 10000 });
            if (response.data && response.data.proxies) {
                response.data.proxies.forEach(p => {
                    if (p.alive) this.proxies.add(`http://${p.ip}:${p.port}`);
                });
            }
        } catch (e) { console.warn("[ProxyManager] ProxyScrape fetch failed:", e.message); }
    }

    async _fetchSpysMe() {
        try {
            const response = await axios.get('https://spys.me/proxy.txt', { timeout: 10000 });
            const lines = response.data.split('\n');
            lines.forEach(line => {
                if (line.includes('-S') || line.includes('+S')) { // SSL proxies
                    const ipPort = line.split(' ')[0];
                    if (ipPort && ipPort.includes(':')) {
                        this.proxies.add(`http://${ipPort}`);
                    }
                }
            });
        } catch (e) { console.warn("[ProxyManager] Spys.me fetch failed:", e.message); }
    }

    async _fetchGeonode() {
        try {
            const url = 'https://proxylist.geonode.com/api/proxy-list?limit=100&page=1&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps';
            const response = await axios.get(url, { timeout: 10000 });
            if (response.data && Array.isArray(response.data.data)) {
                response.data.data.forEach(p => {
                    if (p.ip && p.port) this.proxies.add(`http://${p.ip}:${p.port}`);
                });
            }
        } catch (e) { console.warn("[ProxyManager] Geonode fetch failed:", e.message); }
    }

    async _fetchOpenProxyList() {
        try {
            const url = 'https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS.txt';
            const response = await axios.get(url, { timeout: 10000 });
            const lines = response.data.split('\n');
            lines.forEach(line => {
                const ipPort = line.trim();
                if (ipPort.includes(':')) {
                    this.proxies.add(`http://${ipPort}`);
                }
            });
        } catch (e) { console.warn("[ProxyManager] OpenProxyList fetch failed:", e.message); }
    }

    /**
     * Validates a single proxy by making a quick request to the validation URL.
     */
    async _validateProxy(proxyUrl) {
        try {
            const agent = new HttpProxyAgent(proxyUrl);
            await axios.get(this.validationUrl, {
                httpAgent: agent,
                timeout: this.validationTimeoutMs,
                validateStatus: status => status >= 200 && status < 400
            });
            return true;
        } catch (e) {
            return false;
        }
    }

    /**
     * Gets a guaranteed working proxy url.
     * Validates proxies in parallel until it finds a working one.
     */
    async getWorkingProxyUrl() {
        if (this.workingProxies.length < this.minProxyPoolSize || Date.now() - this.lastFetch > this.refreshIntervalMs) {
            this._fetchFromAllSources(); // Async trigger
        }

        // 1. Try to return a proxy from our known working pool
        if (this.workingProxies.length > 0) {
            const randomIndex = Math.floor(Math.random() * this.workingProxies.length);
            return this.workingProxies[randomIndex];
        }

        // 2. If no known working proxies, pull from the raw set and validate
        const proxyArray = Array.from(this.proxies);
        if (proxyArray.length === 0) {
            await this._fetchFromAllSources();
            if (this.proxies.size === 0) return null; // Complete failure
        }

        console.log("[ProxyManager] Validating raw proxies to find a working one...");

        // Take chunks of 10 proxies and validate them in parallel
        for (let i = 0; i < 50; i += 10) {
           const batch = Array.from(this.proxies).slice(0, 10);
           // Remove from raw set
           batch.forEach(p => this.proxies.delete(p));

           const results = await Promise.allSettled(batch.map(p => this._validateProxy(p).then(res => ({url: p, working: res}))));

           const workingBatch = results.filter(r => r.status === 'fulfilled' && r.value.working).map(r => r.value.url);

           if (workingBatch.length > 0) {
               console.log(`[ProxyManager] Found ${workingBatch.length} working proxies.`);
               this.workingProxies.push(...workingBatch);
               return this.workingProxies[Math.floor(Math.random() * this.workingProxies.length)];
           }
        }

        console.warn("[ProxyManager] Failed to find a working proxy after testing 50 proxies.");
        return null;
    }

    /**
     * If a proxy fails during your application's actual request, call this
     * to discard it from the known working pool.
     */
    discardProxy(proxyUrl) {
        if (proxyUrl) {
            const initialLength = this.workingProxies.length;
            this.workingProxies = this.workingProxies.filter(p => p !== proxyUrl);
            if (this.workingProxies.length < initialLength) {
                console.log(`[ProxyManager] Discarded broken proxy: ${proxyUrl}. Remaining working: ${this.workingProxies.length}`);
            }
        }
    }

    /**
     * Generates an axios instance pre-configured with a working proxy.
     */
    async getProxiedAxios() {
        const proxyUrl = await this.getWorkingProxyUrl();
        if (!proxyUrl) {
            console.warn("[ProxyManager] No proxy available. Returning direct axios instance.");
            return axios.create();
        }

        const agent = new HttpProxyAgent(proxyUrl);
        const httpsAgent = new HttpsProxyAgent(proxyUrl);
        return axios.create({ httpAgent: agent, httpsAgent: httpsAgent });
    }
}
