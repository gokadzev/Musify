import express from 'express';
import cors from 'cors';
import ytSearch from 'yt-search';
import ytDlp from 'yt-dlp-exec';
import { getProxyForYtdlp, markProxyAsFailed } from './proxyManager.js';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use(express.static('public'));

app.get('/api', (req, res) => {
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
    const searchResult = await ytSearch({ videoId: ytid });

    res.json({
      ytid: searchResult.videoId,
      title: searchResult.title,
      artist: searchResult.author?.name,
      duration: searchResult.seconds,
      thumbnail: searchResult.thumbnail,
      viewCount: searchResult.views
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

    let attempts = 0;
    while(attempts < 10) {
        attempts++;
        const proxyUrl = await getProxyForYtdlp();

        try {
            const options = {
                dumpJson: true,
                format: 'bestaudio',
            };
            if (proxyUrl) {
                options.proxy = proxyUrl;
            }

            const output = await ytDlp(`https://www.youtube.com/watch?v=${ytid}`, options);

            if (output && output.url) {
                return res.json({
                    ytid: ytid,
                    url: output.url,
                    mimeType: `audio/${output.ext}`,
                    bitrate: output.abr
                });
            } else {
                 console.error(`Attempt ${attempts} failed: No URL in output`);
            }
        } catch (error) {
            console.error(`Attempt ${attempts} failed with proxy ${proxyUrl}:`, error.message);
            await markProxyAsFailed(proxyUrl);
        }
    }

    return res.status(429).json({ error: 'Failed to fetch stream URL due to YouTube rate limits (429) or bot blocks.' });

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
    const searchResult = await ytSearch({ videoId: ytid });

    const searchResults = await ytSearch(searchResult.author?.name || searchResult.title);

    const relatedVideos = searchResults.videos.slice(0, 10).map(video => ({
      ytid: video.videoId,
      title: video.title,
      artist: video.author?.name,
      duration: video.timestamp,
      thumbnail: video.thumbnail,
      viewCount: video.views
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
