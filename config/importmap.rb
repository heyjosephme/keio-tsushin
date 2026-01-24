# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Dexie from esm.sh (browser-friendly, no Node.js polyfills)
pin "dexie", to: "https://esm.sh/dexie@4.0.11"
# pdfjs-dist loaded via CDN in application layout (needs web worker support)
