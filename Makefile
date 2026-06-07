.PHONY: verify build test format lint clean

verify:
	./scripts/verify.sh

build:
	swift build

test:
	./scripts/swift-test.sh

format:
	swiftformat .

lint:
	./scripts/swiftlint.sh --strict

clean:
	swift package clean
