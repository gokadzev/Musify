import axios from 'axios';

let workingProxies = [];
let lastFetch = 0;

async function fetchProxies() {
  try {
    console.log("Fetching new proxies for yt-dlp...");
    const url = 'https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&proxy_format=protocolipport&format=json&protocol=http&ssl=yes';
    const response = await axios.get(url, { timeout: 10000 });

    if (response.data && response.data.proxies) {
      const newProxies = response.data.proxies
        .filter(p => p.alive)
        .map(p => `http://${p.ip}:${p.port}`);

      workingProxies = [...new Set([...workingProxies, ...newProxies])];
      lastFetch = Date.now();
      console.log(`Successfully fetched proxies. Pool size: ${workingProxies.length}`);
    }
  } catch (err) {
    console.error("Failed to fetch proxies from ProxyScrape:", err.message);
  }
}

export function getRandomProxy() {
  if (workingProxies.length === 0) return null;
  const randomIndex = Math.floor(Math.random() * workingProxies.length);
  return workingProxies[randomIndex];
}

async function discardProxy(proxy) {
    workingProxies = workingProxies.filter(p => p !== proxy);
    console.log(`Discarded broken proxy: ${proxy}. Remaining: ${workingProxies.length}`);
    if (workingProxies.length < 5) {
        await fetchProxies();
    }
}

export async function getProxyForYtdlp() {
  if (workingProxies.length < 5 || Date.now() - lastFetch > 30 * 60 * 1000) {
    await fetchProxies();
  }

  const proxyUrl = getRandomProxy();
  return proxyUrl;
}

export async function markProxyAsFailed(proxyUrl) {
    if (proxyUrl) {
        await discardProxy(proxyUrl);
    }
}
