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

const swiper = new Swiper('.product-swiper', {
  slidesPerView: 3,
  spaceBetween: 50,
  loop: true,
  pagination: {
    el: '.swiper-pagination',
    clickable: true,
  },
  breakpoints: {
    0: {
      slidesPerView: 1,
      spaceBetween: 20,
    },
    699: {
      slidesPerView: 2,
      spaceBetween: 30,
    },
    1200: {
      slidesPerView: 3,
      spaceBetween: 50,
    },
  },
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
  makeHttpRequest(featuresUrl, (res) => {
    try {
      const lines = res.split(/\r?\n/).filter((line) => line.trim() !== '')

      const features = lines
        .slice(1)
        .map((line) => line.trim().replace(/^\*/, '•').trim())

      if (features.length > 0) {
        features.forEach((feature) => {
          const listItem = document.createElement('p')
          listItem.textContent = feature
          featuresElement.appendChild(listItem)
        })

        const extraItem = document.createElement('p')
        extraItem.textContent = '• And more...'
        featuresElement.appendChild(extraItem)
      } else {
        console.warn('No features found in the response.')
      }
    } catch (error) {
      console.error('Error processing app features:', error)
    }
  })
}

function parseChangelog(text) {
  const lines = text.split('\r\n').filter((line) => line.trim() !== '');

  lines.forEach((line) => {
    const itemMatch = line.match(/^\*\s+(.+)$/);
    if (itemMatch) {
      const processedText = itemMatch[1].replace(/\*\*(.+?)\*\*/g, '<b>$1</b>');

      const listItem = document.createElement('p');
      listItem.innerHTML = `• ${processedText}`;
      changelogElement.appendChild(listItem);
    }
  });
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
