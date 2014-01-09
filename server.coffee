express = require 'express'

app = express()
  .use(express.json())
  .use(express.urlencoded())
#  .use(express.static("#{__dirname}/"))

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'

map = {
  'crash': { left: 'plains', right: 'cliffs' }
  'plains': { left: 'deeper', right: 'riverbed' }
  'deeper': { left: 'sinkhole', right: 'herd' }
  'sinkhole': {}
  'herd': {}
  'riverbed': { left: 'upriver', right: 'downriver' }
  'upriver': {}
  'downriver': {}
  'cliffs': { left: 'ridge', right: 'cave' }
  'ridge': { left: 'over', right: 'follow' }
  'over': {}
  'follow': {}
  'cave': { left: 'pool', right: 'tunnel' }
  'pool': {}
  'tunnel': {}
}
world =
  players: {}
  resources:
    food: 5
    water: 5
  base:
    farms: []
    mines: []
    lander: ['stuff']
  map: map

locations =
  intro: (p) ->
    desc: -> "Your ship has crash landed on mars. The air is thin and dusty around you."
    actions: ->
      getup:
        text: 'Get up'
        act: (ctx) ->
          p.location = 'base'
          ctx.message = "Groggy, you get up"

  base: (p) ->
    desc: ->
      m = "You are in a dusty plain."
      m += "Your crashed lander is behind you" if world.base.lander
      m
    actions: ->
      explore:
        text: 'Explore'
        act: (ctx) ->
          p.actions--
          p.location = 'expedition'
          p.explore_location = 'crash'
          ctx.message = 'You embark on a great expedition.'

      scavenge:
        text: 'Scavenge Wreck'
        act: (ctx) ->
          p.actions--
          ctx.message = "You got stuff!"


  exploring: (p) ->
    desc: ->
      "You are exploring. You are at #{p.explore_location}"

  expedition: (p) ->
    loc = world.map[p.explore_location]
    desc: ->
      "Out on your adventure at #{p.explore_location}"
    actions: ->
      return unless loc
      left:
        text: loc.left
        act: ->
          p.explore_location = world.map[p.explore_location].left
      right:
        text: loc.right
        act: ->
          p.explore_location = world.map[p.explore_location].right
      return:
        text: 'Return to base'
        act: (ctx) ->
          delete p.explore_location
          p.location = 'base'
          ctx.message = 'You return home.'



for id in ['seph', 'jeremy']
  world.players[id] =
    actions: 3
    hunger: 0
    location: 'intro'
    skills: {}

tick = ->
  for player, id of world.players
    player.actions++

app.post '/cheat', (req, res) ->
  tick()
  res.send 'ok'

renderGame = (req, res, message) ->
  playername = req.body?.player ? 'seph'
  res.render 'game', {world, playername, locations, message}

app.get '/', (req, res) -> renderGame req, res

app.get '/world', (req, res) ->
  res.send world

# client sends actions
# we reply with new world state
app.post '/act', (req, res) ->
  data = req.body
  p = world.players[data.player]
  return res.error 'Invalid player' unless p
  return res.error 'Invalid location' unless locations[p.location]

  action = data.act
  message = null

  location = locations[p.location](p)
  ctx = {}
  location.actions?()[action]?.act? ctx
  return renderGame req, res, ctx.message
  


  console.log '->', message, world
  #res.send {world, message}
  res.render 'game', {world, descriptions, player, message}

app.get '/act', (req, res) -> res.redirect '/'

app.listen 4433
console.log 'Listening on localhost:4433'
