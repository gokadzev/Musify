import express from 'express';
import cors from 'cors';
import ytdl from '@distube/ytdl-core';
import ytSearch from 'yt-search';
import { getYtdlAgent, markProxyAsFailed } from './proxyManager.js';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Musify Express API is running');
});

// Search endpoint
app.get('/api/search', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ error: 'Search query "q" is required' });
    }

    const searchResults = await ytSearch(query);

    // Map to a simplified Musify-like structure
    const results = searchResults.videos.slice(0, 20).map(video => ({
      ytid: video.videoId,
      title: video.title,
      artist: video.author?.name,
      duration: video.timestamp,
      thumbnail: video.thumbnail,
      viewCount: video.views
    }));

    res.json(results);
  } catch (error) {
    console.error('Error during search:', error);
    res.status(500).json({ error: 'Failed to perform search' });
  }
});

// Get song details
app.get('/api/song/:ytid/details', async (req, res) => {
  try {
    const ytid = req.params.ytid;
    const info = await ytdl.getBasicInfo(ytid);

    res.json({
      ytid: info.videoDetails.videoId,
      title: info.videoDetails.title,
      artist: info.videoDetails.author?.name,
      duration: info.videoDetails.lengthSeconds,
      thumbnail: info.videoDetails.thumbnails?.[0]?.url,
      viewCount: info.videoDetails.viewCount
    });
  } catch (error) {
    console.error('Error fetching song details:', error);
    res.status(500).json({ error: 'Failed to fetch song details' });
  }
});

// Get stream URL (CDN link)
app.get('/api/song/:ytid/stream', async (req, res) => {
  try {
    const ytid = req.params.ytid;

    // Retry loop for proxies
    let attempts = 0;
    while (attempts < 5) {
       attempts++;
       const { agent, proxyUrl } = await getYtdlAgent();

       try {
           const info = await ytdl.getInfo(ytid, { agent });
           const format = ytdl.chooseFormat(info.formats, { quality: 'highestaudio' });

           if (!format) {
              return res.status(404).json({ error: 'No suitable audio format found' });
           }

           return res.json({
             ytid: ytid,
             url: format.url,
             mimeType: format.mimeType,
             bitrate: format.audioBitrate
           });

       } catch (e) {
           console.error(`Attempt ${attempts} failed with proxy ${proxyUrl}: ${e.message}`);
           if (e.message.includes('429') || e.message.includes('socket') || e.message.includes('timeout') || e.message.includes('fetch')) {
               await markProxyAsFailed(proxyUrl);
           } else if (e.statusCode === 410) {
               return res.status(410).json({ error: 'Video is unavailable (410 Gone). It might be age-restricted or private.' });
           } else {
               // If it's a completely different error, stop retrying
               throw e;
           }
       }
    }

    return res.status(429).json({ error: 'Failed to fetch stream URL due to proxy limits (429). Please try again later.' });

  } catch (error) {
    console.error('Error fetching stream:', error);
    res.status(500).json({ error: 'Failed to fetch stream URL', details: error.message });
  }
});

// Get Playlist
app.get('/api/playlist/:playlistId', async (req, res) => {
  try {
    const playlistId = req.params.playlistId;
    const playlist = await ytSearch({ listId: playlistId });

    if (!playlist || !playlist.videos) {
       return res.status(404).json({ error: 'Playlist not found or empty' });
    }

    const videos = playlist.videos.map(video => ({
      ytid: video.videoId,
      title: video.title,
      artist: video.author?.name,
      duration: video.duration?.seconds,
      thumbnail: video.thumbnail
    }));

    res.json({
      id: playlist.listId,
      title: playlist.title,
      author: playlist.author?.name,
      videos: videos
    });
  } catch (error) {
    console.error('Error fetching playlist:', error);
    res.status(500).json({ error: 'Failed to fetch playlist' });
  }
});

// Get related videos
app.get('/api/song/:ytid/related', async (req, res) => {
  try {
    const ytid = req.params.ytid;
    const info = await ytdl.getBasicInfo(ytid);

    const relatedVideos = info.related_videos.map(video => ({
      ytid: video.id,
      title: video.title,
      artist: video.author?.name || (typeof video.author === 'string' ? video.author : 'Unknown'),
      duration: video.length_seconds,
      thumbnail: video.thumbnails?.[0]?.url,
      viewCount: video.view_count
    }));

    res.json(relatedVideos);
  } catch (error) {
    console.error('Error fetching related videos:', error);
    res.status(500).json({ error: 'Failed to fetch related videos' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
