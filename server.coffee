express = require 'express'

app = express()
  .use(express.json())
  .use(express.urlencoded())
  .use(express.static("#{__dirname}/"))

world = {players:{}}

for id in ['seph', 'jeremy']
  world.players[id] =
    actions: 3
    hunger: 0
    location: 'base'

tick = ->
  for player, id of world.players
    player.actions++

app.post '/cheat', (req, res) ->
  tick()
  res.send 'ok'


app.get '/world', (req, res) ->
  res.send world

# client sends actions
# we reply with new world state
app.post '/act', (req, res) ->
  


  res.send world

app.listen 4433
console.log 'Listening on localhost:4433'
