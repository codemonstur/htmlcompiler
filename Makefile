.DEFAULT_GOAL := help
.PHONY: help clean build test coverage install validate release-notes deploy

NAME=htmlcompiler
VERSION=`xmllint --xpath "//project/version/text()" pom.xml`
PREVIOUS_TAG=`git tag | sort -r | head -n 1`

# Blue [INFO] prefix before every message, NO_COLOR=1 prints it plain
ifneq ($(NO_COLOR),)
INFO = printf '[INFO] %s\n'
else
INFO = printf '[\033[1;34mINFO\033[m] %s\n'
endif

help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_.-]+:' $(MAKEFILE_LIST) | grep -vE '^[a-zA-Z0-9_.-]+:=' | \
		awk 'BEGIN {FS = ":"} /^\./ {next} {name = $$1; sub(/[[:blank:]]+$$/, "", name); doc = $$0; sub(/^[^#]*## /, "", doc); if (doc == $$0) sub(/^[^:]*:[[:blank:]]*/, "", doc); printf "  \033[36m%-20s\033[0m %s\n", name, doc}'

clean: ## Delete everything in ./target
	@$(INFO) "Cleaning"
	@mvn clean

build: ## Builds the jar
	@mvn -DskipTests clean package

test: ## Runs the tests
	@mvn clean test

coverage: ## Run tests and generate a jacoco coverage report
	@$(INFO) "Running tests and generating coverage report"
	@mvn -Dstyle.color=always org.jacoco:jacoco-maven-plugin:0.8.15:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.15:report
	@$(INFO) "Coverage report written to target/site/jacoco/index.html"
	@output=$$(java src/build/CoverageSummary.java target/site/jacoco/jacoco.csv) || exit $$?; \
	printf '%s\n' "$$output" | while IFS= read -r line; do $(INFO) "$$line"; done

install: ## Compile, package, and install jar in local repository
	@mvn clean install -DskipTests

validate: ## Check dependency versions, cves, licenses, and code quality
	@mvn com.github.codemonstur:maven-check-pom:1.0.0:check validate
	@mvn com.github.codemonstur:maven-check-pom:1.0.0:reorder
	@mvn versions:display-dependency-updates "-Dmaven.version.ignore=(?i).*(alpha|beta|rc|-m[0-9]+|snapshot).*"
	@mvn versions:display-plugin-updates
	@mvn verify -P vulnerabilities,licenses -DskipTests -T 1C
	@mvn validate -P codequality

release-notes: ## Write release notes in src/docs/releases for the current version
	@mkdir -p src/docs/releases
	@$(INFO) "Writing release notes to src/docs/releases/release-$(VERSION).txt"
	@echo "$(VERSION)" >> src/docs/releases/release-$(VERSION).txt
	@echo "" >> src/docs/releases/release-$(VERSION).txt
	@git log --pretty="%s" $(PREVIOUS_TAG)... master >> src/docs/releases/release-$(VERSION).txt

deploy: ## Clean, build and deploy a version to Github and Maven Central
	@$(INFO) "Installing core (needed to build the plugin)"
	@mvn -q -pl htmlcompiler-core clean install -DskipTests
	@$(INFO) "Uploading maven-plugin to maven central"
	@mvn -pl htmlcompiler-maven-plugin clean deploy
	@$(INFO) "Building bobplugin for github release"
	@mvn -q -pl htmlcompiler-bobplugin package
	@$(INFO) "Creating github release"
	@gh release create $(NAME)-$(VERSION) \
		htmlcompiler-maven-plugin/target/$(NAME)-$(VERSION).jar \
		htmlcompiler-maven-plugin/target/$(NAME)-$(VERSION)-javadoc.jar \
		htmlcompiler-maven-plugin/target/$(NAME)-$(VERSION)-sources.jar \
		htmlcompiler-bobplugin/target/htmlcompiler-bobplugin.jar \
		htmlcompiler-bobplugin/target/htmlcompiler-bobplugin-$(VERSION)-javadoc.jar \
		htmlcompiler-bobplugin/target/htmlcompiler-bobplugin-$(VERSION)-sources.jar \
		-F src/docs/releases/release-$(VERSION).txt
	@$(INFO) "Tagging and pushing to github"
	@git tag $(NAME)-$(VERSION)
	@git push && git push --tags
