# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**odu_core** is a Dart library providing core domain-driven design (DDD) building blocks and functional programming utilities. It includes:

- **Entity system**: Base class with identity, timestamps, change tracking, and deep equality
- **Result type**: Railway-oriented programming with sealed `Result<T>` (Done/Error variants)
- **Optimistic updates**: Stream-based optimistic UI state management with rollback
- **Specification pattern**: Composable business rules with and/or/not operators

## Development Commands

### Testing
```bash
dart test                    # Run all tests
dart test test/path_test.dart  # Run a single test file
```

### Analysis & Linting
```bash
dart analyze                 # Run static analysis
dart fix --dry-run          # Preview available fixes
dart fix --apply            # Apply automatic fixes
```

### Building & Running
```bash
dart run example/odu_core_example.dart  # Run example
dart pub get                            # Install dependencies
dart pub upgrade                        # Upgrade dependencies
```

## Architecture

### Entity System (`lib/src/entity/`)

The `Entity` base class provides:
- Auto-generated UUIDs (using `package:uuid`)
- Created/updated timestamps
- Change tracking via `markAsChanged()` and `hasChanged`
- Deep equality using `uniqueProps` list (extend Entity and add domain properties here)
- Custom equatable implementation with support for nested iterables, sets, and maps

Key implementation detail: The `equatable.dart` part file contains Jenkins hash functions and deep comparison logic that works with nested collections.

### Result Type (`lib/src/result.dart`)

Railway-oriented programming pattern:
- `Result<T>` is a sealed class with `Done<T>` and `Error<T>` variants
- Use pattern matching with switch statements to handle both cases
- `Task<T>` type alias for `Future<Result<T>>` (common async pattern)
- `Unit` type for void-like returns (use `Result.done` for success with no value)

### Optimistic Updates (`lib/src/optmistic_value.dart`)

Stream-based state management with automatic rollback:
- `OptimisticValue<T>` wraps a source stream and adds optimistic updates
- `update()` applies updater function immediately, then runs async task
- Automatically rolls back to previous state if task returns `Error`
- Uses broadcast streams to merge source and optimistic updates
- `ListReplacer<T>` utility for updating items in lists by predicate

Note: Line 48 has incomplete code (missing `Result` constructor prefix).

### Specification Pattern (`lib/src/specification.dart`)

Composable business rule pattern:
- Implement `Specification<T>` interface with `isSatisfiedBy(T entity)` method
- Chain specifications using `.and()`, `.or()`, and `.not()` extension methods
- Useful for encapsulating complex validation or filtering logic

## Code Style

- Uses `package:lints/recommended.yaml` for linting rules
- Requires Dart SDK ^3.10.3
- Uses `final` classes where appropriate (Result subtypes)
- Part/library system for entity internals
- Const constructors for immutable types (Unit, Result variants)
