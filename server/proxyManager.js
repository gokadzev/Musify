import axios from 'axios';
import { ProxyAgent } from 'undici';
import ytdl from '@distube/ytdl-core';

let workingProxies = [];
let lastFetch = 0;

// Replicate Musify's logic of grabbing proxies from ProxyScrape
async function fetchProxies() {
  try {
    console.log("Fetching new proxies...");
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

function getRandomProxy() {
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

export async function getYtdlAgent() {
  if (workingProxies.length < 5 || Date.now() - lastFetch > 30 * 60 * 1000) {
    await fetchProxies();
  }

  const proxyUrl = getRandomProxy();
  if (!proxyUrl) {
     console.warn("No proxies available, falling back to direct connection.");
     return { agent: ytdl.createAgent(), proxyUrl: null };
  }

  console.log(`Creating ytdl dispatcher with proxy: ${proxyUrl}`);
  const dispatcher = new ProxyAgent({ uri: proxyUrl });
  const agent = ytdl.createAgent(undefined, { fetchOptions: { dispatcher } });

  return { agent, proxyUrl };
}

export async function markProxyAsFailed(proxyUrl) {
    if (proxyUrl) {
        await discardProxy(proxyUrl);
    }
}
