# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                  Jools                                        ║
# ║                    iOS Client for Google's Jules Coding Agent                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────────

PRODUCT_NAME     := Jools
SCHEME           := Jools
TEST_SCHEME      := JoolsTests
JOOLSKIT_PATH    := JoolsKit
PROJECT          := $(PRODUCT_NAME).xcodeproj
SIMULATOR        := iPhone 17 Pro
DESTINATION      := platform=iOS Simulator,name=$(SIMULATOR)
DEVICE_DEST      := generic/platform=iOS
DERIVED_DATA     := $(HOME)/Library/Developer/Xcode/DerivedData
BUILD_DIR        := .build
COVERAGE_DIR     := $(BUILD_DIR)/coverage

# Tools
BREW             := $(shell command -v brew 2>/dev/null)
SWIFTLINT        := $(shell command -v swiftlint 2>/dev/null)
SWIFTFORMAT      := $(shell command -v swift-format 2>/dev/null)
XCODEGEN         := $(shell command -v xcodegen 2>/dev/null)
LEFTHOOK         := $(shell command -v lefthook 2>/dev/null)
XCPRETTY         := $(shell command -v xcpretty 2>/dev/null)

# Colors
RESET            := \033[0m
BOLD             := \033[1m
RED              := \033[31m
GREEN            := \033[32m
YELLOW           := \033[33m
BLUE             := \033[34m
MAGENTA          := \033[35m
CYAN             := \033[36m
WHITE            := \033[37m
BG_GREEN         := \033[42m
BG_BLUE          := \033[44m
BG_MAGENTA       := \033[45m

# Icons
CHECK            := ✓
CROSS            := ✗
ARROW            := →
GEAR             := ⚙
PACKAGE          := 📦
ROCKET           := 🚀
BROOM            := 🧹
TEST_ICON        := 🧪
LINT_ICON        := 🔍
BUILD_ICON       := 🔨
HOOK_ICON        := 🪝

.PHONY: all help setup deps check-deps install-deps \
        build build-release build-device test test-kit test-app coverage \
        lint lint-fix format clean clean-all \
        xcode generate run \
        kit-build kit-test kit-clean kit-update \
        ci pre-push hooks-install hooks-uninstall \
        status diff log

.DEFAULT_GOAL := help

# ─────────────────────────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────────────────────────

help: ## Show this help
	@echo ""
	@echo "$(BOLD)$(MAGENTA)  ╔═══════════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(BOLD)$(MAGENTA)  ║$(RESET)$(BOLD)                         $(CYAN)Jools$(RESET)$(BOLD)                                 $(MAGENTA)║$(RESET)"
	@echo "$(BOLD)$(MAGENTA)  ║$(RESET)       $(WHITE)iOS Client for Google's Jules Coding Agent$(RESET)          $(MAGENTA)║$(RESET)"
	@echo "$(BOLD)$(MAGENTA)  ╚═══════════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)  Usage:$(RESET) make $(CYAN)<target>$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)  ─── Setup ────────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(setup|deps|install|hooks)' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)$(BLUE)  ─── Build ────────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(build|generate|xcode|run)' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)$(MAGENTA)  ─── Test ─────────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(test|coverage)' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)$(YELLOW)  ─── Quality ──────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(lint|format)' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)$(RED)  ─── Clean ────────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E 'clean' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)$(WHITE)  ─── JoolsKit ─────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E 'kit-' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)$(CYAN)  ─── CI/CD ────────────────────────────────────────────────────────$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(ci|pre-push)' | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ─────────────────────────────────────────────────────────────────────────────────
# Setup & Dependencies
# ─────────────────────────────────────────────────────────────────────────────────

setup: deps hooks-install generate ## Full project setup (deps + hooks + generate)
	@echo ""
	@echo "$(GREEN)$(CHECK) Project setup complete!$(RESET)"
	@echo "$(CYAN)$(ARROW) Run 'make xcode' to open in Xcode$(RESET)"

deps: check-deps ## Install all dependencies
	@echo "$(GREEN)$(CHECK) All dependencies installed$(RESET)"

check-deps: ## Check and install missing dependencies
	@echo "$(BOLD)$(PACKAGE) Checking dependencies...$(RESET)"
ifndef BREW
	$(error "$(RED)$(CROSS) Homebrew not found. Install from https://brew.sh$(RESET)")
endif
ifndef SWIFTLINT
	@echo "$(YELLOW)$(ARROW) Installing swiftlint...$(RESET)"
	@brew install swiftlint
endif
ifndef XCODEGEN
	@echo "$(YELLOW)$(ARROW) Installing xcodegen...$(RESET)"
	@brew install xcodegen
endif
ifndef LEFTHOOK
	@echo "$(YELLOW)$(ARROW) Installing lefthook...$(RESET)"
	@brew install lefthook
endif
ifndef XCPRETTY
	@echo "$(YELLOW)$(ARROW) Installing xcpretty...$(RESET)"
	@gem install xcpretty 2>/dev/null || sudo gem install xcpretty
endif
	@echo "$(GREEN)$(CHECK) swiftlint: $(shell swiftlint version 2>/dev/null || echo 'installing...')$(RESET)"
	@echo "$(GREEN)$(CHECK) xcodegen: $(shell xcodegen version 2>/dev/null || echo 'installing...')$(RESET)"
	@echo "$(GREEN)$(CHECK) lefthook: $(shell lefthook version 2>/dev/null | head -1 || echo 'installing...')$(RESET)"

install-deps: ## Force reinstall all dependencies
	@echo "$(BOLD)$(PACKAGE) Installing dependencies...$(RESET)"
	brew install swiftlint xcodegen lefthook || true
	gem install xcpretty 2>/dev/null || sudo gem install xcpretty || true
	@echo "$(GREEN)$(CHECK) Dependencies installed$(RESET)"

# ─────────────────────────────────────────────────────────────────────────────────
# Git Hooks (Lefthook)
# ─────────────────────────────────────────────────────────────────────────────────

hooks-install: ## Install git hooks via lefthook
	@echo "$(BOLD)$(HOOK_ICON) Installing git hooks...$(RESET)"
	@command -v lefthook >/dev/null 2>&1 || (echo "$(YELLOW)$(ARROW) Installing lefthook...$(RESET)" && brew install lefthook)
	@lefthook install
	@echo "$(GREEN)$(CHECK) Git hooks installed$(RESET)"

hooks-uninstall: ## Uninstall git hooks
	@echo "$(BOLD)$(HOOK_ICON) Uninstalling git hooks...$(RESET)"
	@lefthook uninstall || true
	@echo "$(GREEN)$(CHECK) Git hooks removed$(RESET)"

# ─────────────────────────────────────────────────────────────────────────────────
# Build
# ─────────────────────────────────────────────────────────────────────────────────

generate: ## Generate Xcode project from project.yml
	@echo "$(BOLD)$(GEAR) Generating Xcode project...$(RESET)"
	@xcodegen generate
	@echo "$(GREEN)$(CHECK) Project generated$(RESET)"

build: kit-build ## Build for simulator (debug)
	@echo "$(BOLD)$(BUILD_ICON) Building $(PRODUCT_NAME) for simulator...$(RESET)"
	@set -o pipefail && xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		build 2>&1 | xcpretty || xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		build
	@echo "$(GREEN)$(CHECK) Build succeeded$(RESET)"

build-release: kit-build ## Build for simulator (release)
	@echo "$(BOLD)$(BUILD_ICON) Building $(PRODUCT_NAME) (release)...$(RESET)"
	@set -o pipefail && xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Release \
		build 2>&1 | xcpretty || xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Release \
		build
	@echo "$(GREEN)$(CHECK) Release build succeeded$(RESET)"

build-device: kit-build ## Build for device (requires signing)
	@echo "$(BOLD)$(BUILD_ICON) Building $(PRODUCT_NAME) for device...$(RESET)"
	@xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DEVICE_DEST)" \
		-configuration Release \
		build
	@echo "$(GREEN)$(CHECK) Device build succeeded$(RESET)"

xcode: ## Open project in Xcode
	@echo "$(BOLD)$(ROCKET) Opening Xcode...$(RESET)"
	@open $(PROJECT)

run: build ## Build and run on simulator
	@echo "$(BOLD)$(ROCKET) Launching on simulator...$(RESET)"
	@xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	@open -a Simulator
	@xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		build 2>&1 | tail -1
	@xcrun simctl install booted $(DERIVED_DATA)/$(PRODUCT_NAME)-*/Build/Products/Debug-iphonesimulator/$(PRODUCT_NAME).app 2>/dev/null || true
	@xcrun simctl launch booted com.indrasvat.jools 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────────
# Test
# ─────────────────────────────────────────────────────────────────────────────────

test: test-kit test-app ## Run all tests
	@echo "$(GREEN)$(CHECK) All tests passed$(RESET)"

test-kit: ## Run JoolsKit unit tests
	@echo "$(BOLD)$(TEST_ICON) Testing JoolsKit...$(RESET)"
	@cd $(JOOLSKIT_PATH) && swift test
	@echo "$(GREEN)$(CHECK) JoolsKit tests passed$(RESET)"

test-app: ## Run iOS app tests
	@echo "$(BOLD)$(TEST_ICON) Testing $(PRODUCT_NAME) app...$(RESET)"
	@set -o pipefail && xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		test 2>&1 | xcpretty || xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug \
		test
	@echo "$(GREEN)$(CHECK) App tests passed$(RESET)"

coverage: ## Run tests with coverage report
	@echo "$(BOLD)$(TEST_ICON) Running tests with coverage...$(RESET)"
	@mkdir -p $(COVERAGE_DIR)
	@xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-enableCodeCoverage YES \
		-resultBundlePath $(COVERAGE_DIR)/TestResults.xcresult \
		test 2>&1 | xcpretty || true
	@echo "$(GREEN)$(CHECK) Coverage report: $(COVERAGE_DIR)/TestResults.xcresult$(RESET)"

# ─────────────────────────────────────────────────────────────────────────────────
# Code Quality
# ─────────────────────────────────────────────────────────────────────────────────

lint: ## Run SwiftLint on all Swift files
	@echo "$(BOLD)$(LINT_ICON) Linting code...$(RESET)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint --quiet || (echo "$(RED)$(CROSS) Lint errors found$(RESET)" && exit 1); \
		echo "$(GREEN)$(CHECK) No lint errors$(RESET)"; \
	elif [ -x /opt/homebrew/bin/swiftlint ]; then \
		/opt/homebrew/bin/swiftlint lint --quiet || (echo "$(RED)$(CROSS) Lint errors found$(RESET)" && exit 1); \
		echo "$(GREEN)$(CHECK) No lint errors$(RESET)"; \
	else \
		echo "$(YELLOW)$(ARROW) swiftlint not found, skipping lint$(RESET)"; \
	fi

lint-fix: ## Auto-fix lint issues
	@echo "$(BOLD)$(LINT_ICON) Auto-fixing lint issues...$(RESET)"
	@swiftlint lint --fix --quiet
	@echo "$(GREEN)$(CHECK) Lint fixes applied$(RESET)"

format: ## Format code with swift-format
	@echo "$(BOLD)$(LINT_ICON) Formatting code...$(RESET)"
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format format -i -r Jools $(JOOLSKIT_PATH)/Sources $(JOOLSKIT_PATH)/Tests JoolsTests; \
		echo "$(GREEN)$(CHECK) Code formatted$(RESET)"; \
	else \
		echo "$(YELLOW)$(ARROW) swift-format not installed, skipping$(RESET)"; \
	fi

# ─────────────────────────────────────────────────────────────────────────────────
# Clean
# ─────────────────────────────────────────────────────────────────────────────────

clean: ## Clean build artifacts
	@echo "$(BOLD)$(BROOM) Cleaning build artifacts...$(RESET)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)$(CHECK) Clean complete$(RESET)"

clean-all: clean kit-clean ## Clean everything including DerivedData
	@echo "$(BOLD)$(BROOM) Deep cleaning...$(RESET)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/$(PRODUCT_NAME)-*
	@rm -rf .swiftpm
	@echo "$(GREEN)$(CHECK) Deep clean complete$(RESET)"

# ─────────────────────────────────────────────────────────────────────────────────
# JoolsKit (Swift Package)
# ─────────────────────────────────────────────────────────────────────────────────

kit-build: ## Build JoolsKit package
	@echo "$(BOLD)$(PACKAGE) Building JoolsKit...$(RESET)"
	@cd $(JOOLSKIT_PATH) && swift build
	@echo "$(GREEN)$(CHECK) JoolsKit built$(RESET)"

kit-test: ## Run JoolsKit tests
	@echo "$(BOLD)$(TEST_ICON) Testing JoolsKit...$(RESET)"
	@cd $(JOOLSKIT_PATH) && swift test
	@echo "$(GREEN)$(CHECK) JoolsKit tests passed$(RESET)"

kit-clean: ## Clean JoolsKit build
	@echo "$(BOLD)$(BROOM) Cleaning JoolsKit...$(RESET)"
	@cd $(JOOLSKIT_PATH) && swift package clean
	@echo "$(GREEN)$(CHECK) JoolsKit cleaned$(RESET)"

kit-update: ## Update JoolsKit dependencies
	@echo "$(BOLD)$(PACKAGE) Updating JoolsKit dependencies...$(RESET)"
	@cd $(JOOLSKIT_PATH) && swift package update
	@echo "$(GREEN)$(CHECK) Dependencies updated$(RESET)"

# ─────────────────────────────────────────────────────────────────────────────────
# CI/CD
# ─────────────────────────────────────────────────────────────────────────────────

ci: lint kit-build kit-test build test-app ## Run full CI pipeline (lint → build → test)
	@echo ""
	@echo "$(BG_GREEN)$(BOLD)$(WHITE)                                                                 $(RESET)"
	@echo "$(BG_GREEN)$(BOLD)$(WHITE)   $(CHECK) CI PIPELINE PASSED                                       $(RESET)"
	@echo "$(BG_GREEN)$(BOLD)$(WHITE)                                                                 $(RESET)"
	@echo ""

pre-push: ci ## Pre-push hook target (runs full CI)
	@echo "$(GREEN)$(CHECK) Pre-push checks passed$(RESET)"

# ─────────────────────────────────────────────────────────────────────────────────
# Git Helpers
# ─────────────────────────────────────────────────────────────────────────────────

status: ## Show git status
	@git status -sb

diff: ## Show git diff
	@git diff --stat

log: ## Show recent commits
	@git log --oneline -10
