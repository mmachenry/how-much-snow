import { Elm } from './Main.elm'

let app = Elm.Main.init({
  node: document.querySelector('main'),
  flags: { debug: false },
})

if ('geolocation' in navigator) {
  navigator.geolocation.getCurrentPosition((position) => {
    app.ports.updateLocation.send({
      longitude: position.coords.longitude,
      latitude: position.coords.latitude,
      timestamp: position.timestamp
    })
  })
}
