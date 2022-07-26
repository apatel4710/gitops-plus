package services

import (
	greymatter "greymatter.io/api"
)

let Name = "opa" // Name needs to match the greymatter.io/cluster value in the Kubernetes deployment
let OPAIngressName = "\(Name)_local"
let EgressToRedisName = "\(Name)_egress_to_redis"

OPA: {
	name:   Name
	config: opa_config
}

opa_config: [

	// HTTP/2 ingress
	#domain & {domain_key: OPAIngressName},
	#listener & {
		listener_key:          OPAIngressName
		_spire_self:           Name
		_gm_observables_topic: Name
		_is_ingress:           true
	},
	#cluster & {
        cluster_key: OPAIngressName, 
        _upstream_port: defaults.ports.opa_grpc_port
        http2_protocol_options: {
            allow_connect: true
        }
    },
	#route & {route_key:     OPAIngressName},

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
		domain_keys: [OPAIngressName, EgressToRedisName]
		listener_keys: [OPAIngressName, EgressToRedisName]
	},


	// Grey Matter Catalog service entry.
	greymatter.#CatalogService & {
		name:                      "Open Policy Agent"
		mesh_id:                   mesh.metadata.name
		service_id:                "opa"
		version:                   "0.0.1"
		description:               "A general-purpose policy engine unifying policy enforcement across a cloudnative environment"
		api_endpoint:              ""
		business_impact:           "critical"
		enable_instance_metrics:   true
		enable_historical_metrics: false
	},
]
