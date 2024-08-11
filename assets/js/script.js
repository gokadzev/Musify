const checkApiUrl =
  'https://api.github.com/repos/gokadzev/Musify/releases/latest'
const versionElement = document.getElementById('version')
const downloadElement = document.getElementById('download')
const downloadsCount = document.getElementById('downloads_count_element')

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

function formatNumberAbbreviation(num) {
  if (num >= 1000000000) {
    return (num / 1000000000).toFixed(1).replace(/\.0$/, '') + 'G'
  }
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1).replace(/\.0$/, '') + 'M'
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'K'
  }
  return num
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

  makeHttpRequest(checkApiUrl, (res) => {
    const response = JSON.parse(res)
    const appUrl = response['assets'].find((r) => r['name'] === 'Musify.apk')[
      'browser_download_url'
    ]
    const appVersion = response['tag_name']
    versionElement.textContent += 'Current Version: ' + appVersion
    downloadElement.setAttribute('href', appUrl)
  })

  makeHttpRequest(
    'https://raw.githubusercontent.com/gokadzev/Musify/update/downloads_count.json',
    (res) => {
      const response = JSON.parse(res)
      const formattedDownloads = formatNumberAbbreviation(
        response['downloads_count']
      )
      downloadsCount.textContent = formattedDownloads
    }
  )
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
