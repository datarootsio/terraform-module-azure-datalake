package test

import (
	"math/rand"
)

var randomStringSource = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func randSeq(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = randomStringSource[rand.Intn(len(randomStringSource))]
	}
	return string(b)
}
