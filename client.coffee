tag = (name, text, attrs) ->
  parts = (name ? 'div').split /(?=[.#])/
  tagName = "div"
  classes = []
  id = undefined
  for p in parts when p.length
    switch p[0]
      when '#' then id = p.substr 1 if p.length > 1
      when '.' then classes.push p.substr 1 if p.length > 1
      else tagName = p
  element = document.createElement tagName
  element.id = id if id?
  element.classList.add c for c in classes
  element.setAttribute k,v for k,v of attrs if attrs?
  if typeof text is 'string' or typeof text is 'number'
    element.textContent = text
  else if text?.length?
    element.appendChild e for e in text
  else if text
    element.appendChild text
  element

xhr =
  query: (method, url, data, cb) ->
    req = new XMLHttpRequest
    req.timeout = 50000
    req.onload = ->
      cb null, this.responseText
    req.onerror = ->
      cb 'network error'
    req.ontimeout = ->
      cb 'network timeout'
    req.onabort = ->
      cb 'network abort'
    req.open method, url, true
    #req.setRequestHeader 'Authorization', 'Basic dFQzdVlVUmlLM0tCa3pLOk1xMzZ1clVoQUd3aEJZZQ=='
    req.setRequestHeader 'Content-Type', 'application/json'
    req.send data
  get: (url, cb) ->
    this.query 'get', url, undefined, cb
  post: (url, data, cb) ->
    this.query 'post', url, JSON.stringify(data), cb
  put: (url, data, cb) ->
    this.query 'put', url, JSON.stringify(data), cb
  delete: (url, cb) ->
    this.query 'delete', url, undefined, cb




world = null
me = 'seph'

render = (message) ->
  p = world.players[me]

  window.numactions.textContent = "You have #{p.actions} actions remaining today"

  if message?
    window.message.textContent = message

  desc = 'Unknown'
  switch p.location
    when 'intro'
      desc = """
Your ship has crash landed on mars. The air is thin and dusty around you. Your head hurts from the landing."""
      actions = ['Get up']
  
    when 'base'
      desc = """
You are in a dusty plain."""

      desc += "Your crashed lander is behind you" if world.base.lander

      actions = []

      if p.actions
        actions.push 'Explore'
        #actions.push 'Train'
        actions.push 'Scavenge wreck' # scavenge wreck
        actions.push 'Create farm'

    when 'expedition'
      desc = """You are exploring. You are at #{p.explore_location}"""
      actions = ['Left', 'Right', 'Return to base']

    else
      desc = "Unknown location '#{p.location}'"

  window.locationdesc.textContent = desc

  actionsEl = window.actions
  actionsEl.innerHTML = ''
  if actions? then for a in actions
    b = tag 'button', a
    b.onclick = do (a) -> ->
      xhr.post '/act', {player:me, action:a}, (error, data) ->
        throw error if error
        {world, message} = JSON.parse data
        render message

    actionsEl.appendChild b

xhr.get '/world', (err, _world) ->
  world = JSON.parse _world
  console.log 'world is ', world

  render()


