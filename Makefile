default: lint

tools:
	go install gotest.tools/gotestsum
	curl -s https://raw.githubusercontent.com/databrickslabs/databricks-terraform/master/godownloader-databricks-provider.sh | bash -s -- -b ~/.terraform.d/plugins
	terraform init

fmt:
	terraform fmt
	go mod tidy
	gofmt -w -s test

lint-tf: tools
	terraform fmt -check
	terraform validate
	docker run --rm -v $(pwd):/data -t wata727/tflint

lint-go:
	test -z $(gofmt -l -s test)
	go vet ./...

lint: lint-tf lint-go

test: tools lint
	gotestsum -- -timeout 2h ./...