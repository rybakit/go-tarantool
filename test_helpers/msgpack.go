//go:build !go_tarantool_msgpack_v5
// +build !go_tarantool_msgpack_v5

package test_helpers

import (
	"gopkg.in/vmihailenco/msgpack.v2"
)

type encoder = msgpack.Encoder