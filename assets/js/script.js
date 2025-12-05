const checkApiUrl =
  'https://api.github.com/repos/gokadzev/Musify/releases/latest'
const versionElement = document.getElementById('version')
const downloadElement = document.getElementById('download')
const changelogElement = document.getElementById('changelog_element')
const featuresElement = document.getElementById('features_element')

function makeHttpRequest(url, callback) {
  const xmlHttp = new XMLHttpRequest()
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
      callback(xmlHttp.responseText)
    }
  }
  xmlHttp.open('GET', url, true)
  xmlHttp.send(null)
}
document.addEventListener('DOMContentLoaded', function () {
  new Splide('#screenshot-carousel', {
    type: 'loop',
    perPage: 3,
    gap: '2rem',
    pagination: true,
    arrows: false,
    breakpoints: {
      1200: { perPage: 3, gap: '2rem' },
      699: { perPage: 2, gap: '1.5rem' },
      560: { perPage: 1, gap: '1rem' },
    },
  }).mount()
})

window.onload = function () {
  assignNavClass()
  window.addEventListener('resize', assignNavClass)

  fetchAppMetadata(checkApiUrl)

  fetchAppFeatures(
    'https://raw.githubusercontent.com/gokadzev/Musify/refs/heads/master/fastlane/metadata/android/en-US/full_description.txt'
  )
}

function fetchAppMetadata(apiUrl) {
  makeHttpRequest(apiUrl, (res) => {
    try {
      const response = JSON.parse(res)

      const appUrl = response.assets.find(
        (asset) => asset.name === 'Musify.apk'
      )?.browser_download_url
      const appVersion = response.tag_name

      if (appUrl && appVersion) {
        versionElement.textContent += `V${appVersion}`
        downloadElement.setAttribute('href', appUrl)
        parseChangelog(response.body)
      } else {
        console.error('App URL or version not found in the response.')
      }
    } catch (error) {
      console.error('Error parsing app metadata:', error)
    }
  })
}

function fetchAppFeatures(featuresUrl) {
  const featureIcons = [
    'music_note',
    'cloud_download',
    'queue_music',
    'lyrics',
    'high_quality',
    'search',
    'playlist_add',
    'equalizer',
    'language',
    'palette',
    'timer',
    'headphones',
    'library_music',
    'recommend',
    'sync',
    'auto_awesome',
  ]

  makeHttpRequest(featuresUrl, (res) => {
    try {
      const lines = res.split(/\r?\n/).filter((line) => line.trim() !== '')

      const features = lines
        .slice(1)
        .map((line) =>
          line
            .trim()
            .replace(/^\*\s*/, '')
            .trim()
        )
        .filter((line) => line.length > 0)

      if (features.length > 0) {
        features.forEach((feature, index) => {
          const card = document.createElement('article')
          card.className = 'feature-card'

          const icon = document.createElement('i')
          icon.textContent = featureIcons[index % featureIcons.length]

          const text = document.createElement('span')
          text.textContent = feature

          card.appendChild(icon)
          card.appendChild(text)
          featuresElement.appendChild(card)
        })

        const extraCard = document.createElement('article')
        extraCard.className = 'feature-card'
        extraCard.innerHTML = '<i>more_horiz</i><span>And much more...</span>'
        featuresElement.appendChild(extraCard)
      } else {
        console.warn('No features found in the response.')
      }
    } catch (error) {
      console.error('Error processing app features:', error)
    }
  })
}

function parseChangelog(text) {
  const lines = text.split('\r\n').filter((line) => line.trim() !== '')

  lines.forEach((line) => {
    const itemMatch = line.match(/^\*\s+(.+)$/)
    if (itemMatch) {
      const processedText = itemMatch[1].replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')

      const listItem = document.createElement('p')
      listItem.innerHTML = `• ${processedText}`
      changelogElement.appendChild(listItem)
    }
  })
}

function assignNavClass() {
  const nav = document.getElementById('navigation-bar')
  if (window.innerWidth > 760) {
    nav.classList.remove('bottom')
    nav.classList.add('left')
  } else {
    nav.classList.remove('left')
    nav.classList.add('bottom')
  }
}
