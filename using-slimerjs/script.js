const fs = require('fs')
const webpage = require('webpage')
const system = require('system')

const page = webpage.create()
page.settings.javascriptEnabled = false
page.settings.localToRemoteUrlAccessEnabled = false

page.onResourceRequested = function(requestData, networkRequest) {
  const url = requestData.url

  if (url.startsWith('file:') && url.endsWith('/page.html')) {
    // this is the input file. Load it normally.
  } else if (url.startsWith('data:')) {
    // this is a data: URL, which means the content is embedded in the page.
    // Load it normally.
  } else {
    // Aside from page.html and data: URLs, we don't want any other requests.
    // The others would be either network requests (which are slow and
    // unreliable -- nondeterministic, too) or file:// requests (which are
    // insecure).
    networkRequest.abort()
  }
}

page.paperSize = { format: 'Letter', orientation: 'Portrait', margin: '20pt' }
page.open('page.html', function(status) {
  if (status === 'success') {
    page.render('doc.pdf')
    fs.write('doc.txt', page.plainText)
  } else {
    console.log('Error: ' + status)
  }

  slimer.exit()
})
