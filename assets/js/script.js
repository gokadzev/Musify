const checkApiUrl = 'https://api.github.com/repos/gokadzev/Musify/releases'
let versionElement = document.getElementById('version')
let downloadElement = document.getElementById('download')
let downloadsCount = document.getElementById('downloads_count_element')

function getUpdateInfo(callback) {
  var xmlHttp = new XMLHttpRequest()
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
      callback(xmlHttp.responseText)
  }
  xmlHttp.open('GET', checkApiUrl, true)
  xmlHttp.send(null)
}

function getDownloadsInfo(callback) {
  var xmlHttp = new XMLHttpRequest()
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
      callback(xmlHttp.responseText)
  }
  xmlHttp.open(
    'GET',
    'https://raw.githubusercontent.com/gokadzev/Musify/update/downloads_count.json',
    true
  )
  xmlHttp.send(null)
}

function nFormatter(num) {
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

// Tab Section
var initTabs = function () {
  const tabs = document.querySelectorAll('[data-tab-target]')
  const tabContents = document.querySelectorAll('[data-tab-content]')

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const target = document.querySelector(tab.dataset.tabTarget)
      tabContents.forEach((tabContent) => {
        tabContent.classList.remove('active')
      })
      tabs.forEach((tab) => {
        tab.classList.remove('active')
      })
      tab.classList.add('active')
      target.classList.add('active')
    })
  })
}

// Responsive Navigation with Button
var initHamburgerMenu = function () {
  const hamburger = document.querySelector('.hamburger')
  const navMenu = document.querySelector('.menu-list')

  hamburger.addEventListener('click', mobileMenu)

  function mobileMenu() {
    hamburger.classList.toggle('active')
    navMenu.classList.toggle('responsive')
  }

  const navLink = document.querySelectorAll('.item-anchor')

  navLink.forEach((n) => n.addEventListener('click', closeMenu))

  function closeMenu() {
    hamburger.classList.remove('active')
    navMenu.classList.remove('responsive')
  }
}

var swiper = new Swiper('.product-swiper', {
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
  initTabs()
  initHamburgerMenu()
  getUpdateInfo((res) => {
    const response = JSON.parse(res)
    const appUrl = response[0]['assets'].find((r) => r['name'] == 'Musify.apk')[
      'browser_download_url'
    ]
    const appVersion = response[0]['tag_name']
    versionElement.textContent += 'Current Version: ' + appVersion
    downloadElement.setAttribute('href', appUrl)
  })
  getDownloadsInfo((res) => {
    var response = JSON.parse(res)
    response = nFormatter(response['downloads_count'])
    downloadsCount.textContent = response
  })
}
