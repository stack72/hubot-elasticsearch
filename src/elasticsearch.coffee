# Description:
#   Get ElasticSearch Cluster Information
#
# Commands:
#   hubot: elasticsearch cluster health [cluster]               - Gets the cluster health for the given server or alias
#   hubot: elasticsearch cat nodes [cluster]                    - Gets the information from the cat nodes endpoint for the given server or alias
#   hubot: elasticsearch cat indices <like logastsh*> [cluster] - Gets the information from the cat indexes endpoint for the given server or alias
#   hubot: elasticsearch cat allocation [cluster]               - Gets the information from the cat allocation endpoint for the given server or alias
#   hubot: elasticsearch cat recovery [cluster]               - Gets the information from the cat allocation endpoint for the given server or alias
#   hubot: elasticsearch clear cache [cluster]                  - Clears the cache for the specified cluster
#   hubot: elasticsearch cluster settings [cluster]             - Gets a list of all of the settings stored for the cluster
#   hubot: elasticsearch concurrent recoveries [number]         - Sets the number of simultaneous shards to recover
#   hubot: elasticsearch index settings [cluster] [index]       - Gets a list of all of the settings stored for a particular index
#   hubot: elasticsearch disable allocation [cluster]           - disables shard allocation to allow nodes to be taken offline
#   hubot: elasticsearch enable allocation [cluster]            - renables shard allocation
#   hubot: elasticsearch show aliases                           - shows the aliases for the list of ElasticSearch instances
#   hubot: elasticsearch add alias [alias name] [url]           - sets the alias for a given url
#   hubot: elasticsearch clear alias [alias name]               - please note that this needs to include any port numbers as appropriate
#
# Notes:
#   The server must be a fqdn (with the port!) to get to the elasticsearch cluster
#
# Author:
#  Paul Stack

_esAliases = {}

QS = require 'querystring'

module.exports = (robot) ->

  robot.brain.on 'loaded', ->
    if robot.brain.data.elasticsearch_aliases?
      _esAliases = robot.brain.data.elasticsearch_aliases

  formattedSend = (text, msg) ->
    if robot.adapterName == 'slack'
      msg.send("```#{text}```")
    else if robot.adapterName == 'shell'
      msg.send("\n#{text}")
    else
      msg.send("/code #{text}")

  clusterHealth = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.http("#{cluster_url}/_cat/health?v")
        .get() (err, res, body) ->
          formattedSend(body, msg)

  catNodes = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the cat stats for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/nodes?h=host,heapPercent,load,segmentsMemory,fielddataMemory,filterCacheMemory,idCacheMemory,percolateMemory,u,heapMax,nodeRole,master&v")
        .get() (err, res, body) ->
          lines = body.split("\n")
          header = lines.shift()
          list = [header].concat(lines.sort().reverse()).join("\n")
          formattedSend(list, msg)

  catIndexes = (msg, alias, filter) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the cat indices for the cluster: #{cluster_url}")
      if filter
        index_url = "#{cluster_url}/_cat/indices/#{filter}?h=idx,sm,fm,fcm,im,pm,ss,sc,dc&v"
      else
        index_url = "#{cluster_url}/_cat/indices/?h=idx,sm,fm,fcm,im,pm,ss,sc,dc&v"
      msg.http(index_url)
        .get() (err, res, body) ->
          lines = body.split("\n")
          header = lines.shift()
          list = [header].concat(lines.sort().reverse()).join("\n")
          formattedSend(list, msg)

  catAllocation = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the cat allocation for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/allocation/?h=disk.percent,node,shards,disk.used,disk.avail")
        .get() (err, res, body) ->
          lines = body.split("\n")
          header = lines.shift()
          list = [header].concat(lines.sort().reverse()).join("\n")
          formattedSend(list, msg)

  recoveryIsDone = (recovery) ->
    return !recovery.match(/.*\s+\d+\s+\d+\s+[a-z]*\s+done/i)

  catRecovery = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the cat allocation for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/recovery/?v")
        .get() (err, res, body) ->
          lines = body.split("\n")
          header = lines.shift()
          list = [header].concat(lines.filter(recoveryIsDone).sort().reverse()).join("\n")
          formattedSend(list, msg)

  clearCache = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Clearing the cache for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cache/clear")
        .post() (err, res, body) ->
          json = JSON.parse(body)
          shards = json['_shards']['total']
          successful = json['_shards']['successful']
          failure = json['_shards']['failed']
          msg.send "Results: \n Total Shards: #{shards} \n Successful: #{successful} \n Failure: #{failure}"

  concurrentRecoveries = (msg, count, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Disabling Allocation for the cluster #{cluster_url}")

      data = {
        'transient': {
          'cluster.routing.allocation.node_concurrent_recoveries': count
        }
      }

      json = JSON.stringify(data)
      msg.http("#{cluster_url}/_cluster/settings")
        .put(json) (err, res, body) ->
          formattedSend(body, msg)

  disableAllocation = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Disabling Allocation for the cluster #{cluster_url}")

      data = {
        'transient': {
          'cluster.routing.allocation.enable': 'none'
        }
      }

      json = JSON.stringify(data)
      msg.http("#{cluster_url}/_cluster/settings")
        .put(json) (err, res, body) ->
          formattedSend(body, msg)

  enableAllocation = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Enabling Allocation for the cluster #{cluster_url}")

      data = {
        'transient': {
          'cluster.routing.allocation.enable': 'all'
        }
      }

      json = JSON.stringify(data)
      msg.http("#{cluster_url}/_cluster/settings")
        .put(json) (err, res, body) ->
          formattedSend(body, msg)

  showClusterSettings = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the Cluster settings for #{cluster_url}")
      msg.http("#{cluster_url}/_cluster/settings?pretty=true")
        .get() (err, res, body) ->
          formattedSend(body, msg)

  showIndexSettings = (msg, alias, index) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the Index settings for #{index} on #{cluster_url}")
      msg.http("#{cluster_url}/#{index}/_settings?pretty=true")
        .get() (err, res, body) ->
          formattedSend(body, msg)

  showAliases = (msg) ->

    if _esAliases == null
      msg.send("I cannot find any ElasticSearch Cluster aliases")
    else
      for alias of _esAliases
        msg.send("I found '#{alias}' as an alias for the cluster: #{_esAliases[alias]}")

  clearAlias = (msg, alias) ->
    delete _esAliases[alias]
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The cluster alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _esAliases[alias] = url
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The cluster alias #{alias} for #{url} has been added to the brain")

  robot.hear /elasticsearch cat nodes (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    catNodes msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cat (indexes|indices)( like (.*))? (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    catIndexes msg, msg.match[4], msg.match[3], (text) ->
      msg.send text

  robot.hear /elasticsearch cat allocation (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    catAllocation msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cat recovery (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    catRecovery msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cluster settings (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showClusterSettings msg, msg.match[1], (text) ->
      msg.send(text)

  robot.hear /elasticsearch cluster health (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clusterHealth msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch index settings (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showIndexSettings msg, msg.match[1], msg.match[2], (text) ->
      msg.send text

  robot.hear /elasticsearch show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.hear /elasticsearch add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.hear /elasticsearch clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /elasticsearch clear cache (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearCache msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /elasticsearch concurrent recoveries (\d*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    concurrentRecoveries msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.respond /elasticsearch disable allocation (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    disableAllocation msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /elasticsearch enable allocation (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    enableAllocation msg, msg.match[1], (text) ->
      msg.send(text)
