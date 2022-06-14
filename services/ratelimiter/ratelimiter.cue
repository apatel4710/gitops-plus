package services

import (
	greymatter "greymatter.io/api"
)

let Name = "ratelimit" // Name needs to match the greymatter.io/cluster value in the Kubernetes deployment
let RateLimitIngressName = "\(Name)_local"
let EgressToRedisName = "\(Name)_egress_to_redis"

RateLimit: {
	name:   Name
	config: ratelimit_config
}

ratelimit_config: [
	// HTTP ingress
	#domain & {domain_key: RateLimitIngressName},
	
	#cluster & {cluster_key: RateLimitIngressName, _upstream_port: defaults.ports.ratelimit_port},
    #listener & {
		listener_key:          RateLimitIngressName
		_is_ingress:           true
        _tcp_upstream:         RateLimitIngressName
        _gm_observables_topic: Name
	},
	#route & {route_key:     RateLimitIngressName},

	// egress->redis
	#domain & {domain_key: EgressToRedisName, port: defaults.ports.redis_ingress},
	#cluster & {
		cluster_key:  EgressToRedisName
		name:         defaults.redis_cluster_name
		_spire_self:  Name
		_spire_other: defaults.redis_cluster_name
	},
	// unused route must exist for the cluster to be registered with sidecar
	#route & {route_key: EgressToRedisName},
	#listener & {
		listener_key:  EgressToRedisName
		ip:            "127.0.0.1" // egress listeners are local-only
		port:          defaults.ports.redis_ingress
		_tcp_upstream: defaults.redis_cluster_name
	},


	// shared proxy object
	#proxy & {
		proxy_key: Name
		domain_keys: [RateLimitIngressName, EgressToRedisName]
		listener_keys: [RateLimitIngressName, EgressToRedisName]
	},

	// Edge config for ratelimit_app ingress
	#cluster & {
		cluster_key:  Name
		_spire_other: Name
	},
	#route & {
		domain_key: "edge"
		route_key:  Name
		route_match: {
			path: "/services/ratelimit/"
		}
		redirects: [
			{
				from:          "^/services/ratelimit$"
				to:            route_match.path
				redirect_type: "permanent"
			},
		]
		prefix_rewrite: "/"
	},

	// Grey Matter Catalog service entry
	greymatter.#CatalogService & {
		name:                      "Rate Limit Service"
		mesh_id:                   mesh.metadata.name
		service_id:                "ratelimit"
		version:                   "0.0.1"
		description:               ""
		api_endpoint:              "/services/ratelimit"
		business_impact:           "critical"
		enable_instance_metrics:   true
		enable_historical_metrics: true
	},
]
