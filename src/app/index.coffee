_ = require('underscore')
app = require('derby').createApp(module)
  .use(require '../../ui/index.coffee')
  #.use(require 'derby-auth/components/index.coffee')

(require 'derby-ui-boot') app,
  styles: __dirname + '/../../bootstrap-css/bootstrap.min'

# TODO should consider replacing this with async.waterfull
withContexts = (model, contexts, callback) ->
  if contexts.length is 0
    callback()
    return
  contexts[0] model, ->
    withContexts model, contexts[1..contexts.length-1], callback

loggedInUser = (model) ->
  model.get "_session.userId"

withUser = (model, callback) ->
  model.set '_page.registered', true
  userId = loggedInUser model
  unless userId
    callback()
    return
  $user = model.at "auths.#{userId}"
  $username = $user.at "local.username"
  model.subscribe $user, (err) ->
    throw err if err
    model.ref "_page.user.local", $user.at "local"
    model.ref "_page.user.name", $username
    callback()

withAllCollection = (collection, alias=collection) ->
  (model, callback) ->
    itemsQuery = model.query collection, {}
    itemsQuery.subscribe (err) ->
      throw err if err
      itemsQuery.ref "_page.#{alias}"
      callback()

withAllDreams = withAllCollection 'dreams'

# REACTIVE FUNCTIONS #

app.on 'model', (model) ->

# ROUTES #

app.get '/', (page, model) ->
  withContexts model, [withUser], ->
    page.render 'home'

app.get '/dreams', (page, model) ->
  withContexts model, [withAllDreams], ->
    page.render 'dreams'

myAlert = (log, obj) ->
  cache = []
  log JSON.stringify obj, (key, value) ->
    if (typeof value is 'object' and value isnt null)
      return if (cache.indexOf(value) isnt -1)
      cache.push(value)
    return value
  , 4
  cache = null

# CONTROLLER FUNCTIONS #

app.fn 'login.toggle', (e) ->
  @model.set '_page.registered', !(@model.get '_page.registered')

app.fn 'dreams.add', (e, el) ->
  newItem = @model.del '_page.newDream'
  return unless newItem
  @model.add 'dreams', newItem

app.fn 'dreams.remove', (e) ->
  dream = e.get ':dream'
  @model.del 'dreams.' + dream.id


# VIEW FUNCTIONS #


# READY FUNCTION #

app.enter '/dreams', (model) ->
  $ ->

