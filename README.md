hubot-elasticsearch
==

A Hubot script for interacting with an [elasticsearch](http://www.elasticsearch.org/) cluster

Installation
---

In hubot project repo, run:

npm install hubot-elasticsearch --save

Then add hubot-etcd to your external-scripts.json:

```
[
  "hubot-elasticsearch"
]
```

Commands
---

* hubot: elasticsearch cluster health [cluster] - Gets the cluster health for the given server or alias
* hubot: elasticsearch cat nodes [cluster] - Gets the information from the cat nodes endpoint for the given server or alias
* hubot: elasticsearch cat indexes [cluster] - Gets the information from the cat indexes endpoint for the given server or alias
* hubot: elasticsearch cat allocation [cluster]  - Gets the information from the cat allocation endpoint for the given server or alias
* hubot: elasticsearch clear cache [cluster] - Clears the cache for the specified cluster
* hubot: elasticsearch cluster settings [cluster] - Gets a list of all of the settings stored for the cluster
* hubot: elasticsearch index settings [cluster] [index] - Gets a list of all of the settings stored for a particular index
* hubot: elasticsearch disable allocation [cluster] - disables shard allocation to allow nodes to be taken offline
* hubot: elasticsearch enable allocation [cluster] - renables shard allocation
* hubot: elasticsearch show aliases - shows the aliases for the list of ElasticSearch instances
* hubot: elasticsearch add alias [alias name] [url] - sets the alias for a given url
* hubot: elasticsearch clear alias [alias name] - please note that this needs to include any port numbers as appropriate
