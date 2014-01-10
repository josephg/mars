express = require 'express'

app = express()
  .use(express.json())
  .use(express.urlencoded())
  .use(express.static("#{__dirname}/static"))

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'

randomInt = (n) -> Math.floor(Math.random() * n)
randomChoice = (things) -> things[randomInt(things.length)]

# inventory item ideas:
#
# dickens book - action: read the last chapter. At the end is a secret note
# from an admirer, giving you two inspiration points!


# Other locations to add later:
# - Previous crash site
map =
  crash:
    desc: 'You set out from the crash site carrying an oxygen tank and high spirits.'
    left: 'plains'
    right: 'cliffs'
  plains:
    action: 'Go downhill towards the flats'
    desc: "Spreading out before you is an ancient flood plain extending as far as the eye can see. The dirt is red and wispy - you need to keep brushing it from your helmet. How's a gentleman supposed to keep his hat clean without a hat brush!?"
    left: 'deeper'
    right: 'riverbed'
  deeper:
    action: 'Go deeper into the flood plain'
    desc: "You wander deeper into the flood plain. There's nothing but red and gold sand to the horizon. There is a dark patch in the distance to your left, and to your right there are some specks, but its hard to know what they are without your monacle."
    left: 'sinkhole'
    right: 'herd'
  sinkhole:
    label: ''
  herd: {} # Let the player name the herd animals - then they're called that
           # for the rest of the game.
  riverbed:
    left: 'upriver'
    right: 'downriver'
  upriver: {}
  downriver: {}
  cliffs:
    left: 'ridge'
    right: 'cave'
  ridge:
    left: 'over'
    right: 'follow'
  over: {}
  follow: {}
  cave:
    left: 'pool'
    right: 'tunnel'
  pool: {}
  tunnel: {}

world =
  players: {}
  resources:
    food: 2
  base:
    farms: []
    mines: []
    lander: ['stuff']
  map: map
  turn: 0

hungerText = (p) ->
  if p.hunger >= 3
    # 'You are dead.'
  else if p.hunger >= 2.8
    "Your vision is blurry. If you don't eat soon, you will die."
  else if p.hunger >= 2
    randomChoice [
      'You feel faint.'
      'You are ravenous.'
    ]
  else if p.hunger >= 1
    randomChoice [
      'You are hungry.'
      'You are rather peckish'
      'You crave a cucumber sandwich'
    ]

locations =
  intro: (p) ->
    desc: ->
      "Your ship has crash landed on mars. The air is thin and dusty around you."
    actions: ->
      getup:
        text: 'Get up'
        act: (ctx) ->
          p.location = 'base'
          ctx.message = 'Dusting off your top hat, you get up and look around.'

  base: (p) ->
    desc: ->
      m = 'You are in a dusty plain. '
      m += randomChoice [
        'You miss your monacle.'
        "Blast - now you'll never know what happens in that book by the dickens chap!"
      ]

      m += " Your crashed lander is behind you." if world.base.lander
      m
    actions: ->
      return if p.dead

      a = {}
      if world.resources.food > 0 and p.hunger >= 1 then a.eat =
        text: 'Eat some rations'
        act: (ctx) ->
          if world.resources.food > 0
            world.resources.food--
            p.hunger--
            ctx.message = randomChoice [
              'You ate a delectable snack!'
              'Delicious!'
            ]
          else
            ctx.message = 'You went for a snack but all the food was already gone. Alas!'

      return a if !p.actions
      a.explore =
        text: 'Explore'
        act: (ctx) ->
          p.actions--
          p.location = 'expedition'
          p.explore_location = 'crash'
          p.oxygen = 3
          ctx.message = 'You embark on a great expedition.'

      a.scavenge =
        text: 'Scavenge Wreck'
        act: (ctx) ->
          p.actions--
          ctx.message = "You got stuff!"

      a

  expedition: (p) ->
    loc = world.map[p.explore_location]
    desc: ->
      world.map[p.explore_location].desc ? p.explore_location
    actions: ->
      return unless loc
      actions =
        return:
          text: 'Return to base'
          act: (ctx) ->
            delete p.explore_location
            delete p.oxygen
            p.location = 'base'
            ctx.message = 'You return home.'
      if p.oxygen > 0
        actions.left =
          text: world.map[loc.left].action ? loc.left
          act: ->
            p.oxygen--
            p.explore_location = world.map[p.explore_location].left
        actions.right =
          text: world.map[loc.right].action ? loc.right
          act: ->
            p.oxygen--
            p.explore_location = world.map[p.explore_location].right
      return actions



for id in ['seph', 'jeremy']
  world.players[id] =
    actions: 3
    hunger: 1
    location: 'intro'
    skills: {}
    inventory: {}

tick = ->
  world.turn++

  for id, player of world.players when !player.dead
    player.hunger += 0.1

    if player.hunger >= 3
      player.dead = true
      player.actions = 0

    player.actions++
    player.actions = Math.min player.actions, (if player.hunger > 1 then 2 else 3)

app.post '/cheat', (req, res) ->
  tick()
  res.redirect '/'

renderGame = (req, res, message) ->
  playername = req.body?.player ? 'seph'
  player.hungerText = hungerText player for name, player of world.players
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
  renderGame req, res, ctx.message
  
app.get '/act', (req, res) -> res.redirect '/'

app.listen 4433
console.log 'Listening on localhost:4433'
