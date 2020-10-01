default: lint

tools:
	go install gotest.tools/gotestsum
	terraform init -backend=false test/module_test

fmt:
	terraform fmt
	terraform fmt test/module_test
	go mod tidy
	gofmt -w -s test

lint-tf: tools
	terraform fmt -check
	terraform fmt -check test/module_test
	terraform validate test/module_test
	tflint

lint-go:
	test -z $(gofmt -l -s test)
	go vet ./...

lint: lint-tf lint-go

test: tools lint
	go test -timeout 2h ./...
