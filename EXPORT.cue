package plus

// EXPORT.cue is the finalized configuration file that gets read by a GitOPS
// tool to import and sync configuration with a remote deployed Grey Matter
// instance.

// You may specify which array of configs you'd like to sync or bundle them all
// in one. We recommend splitting out your configs through namespaces such as
// core services, business applications, etc...

// example evaluation commands:
// cue eval -c EXPORT.cue --out json -e greymatter_configs
// cue eval -c EXPORT.cue --out yaml -e service_configs
// cue eval -c EXPORT.cue --out json -e configs

// This package name refers to your target mesh. We are attempting to write
// configs for the "gitops-plus" Grey Matter mesh so we all our top level
// package "gitops-plus". This does not need to match the cue module name.
import (
	// NOTE: import paths must be aliased to their respective folders under the
	// services package otherwise CUE will not evaluate properly. An example
	// import path:
	// alias_name "<cue_module>/{path}:<name_of_directory_package>"

	observables "greymatter.io.plus/services/observables:services"
	edge "greymatter.io.plus/services/edge:services"
	opa "greymatter.io.plus/services/opa:services"
	ratelimit "greymatter.io.plus/services/ratelimiter:services"
)

configs:
	// The edge config must come first because services create routes
	// that reference the edge domain.
	edge.Edge.config + observables.ObservablesApp.config + opa.OPA.config + ratelimit.RateLimit.config
