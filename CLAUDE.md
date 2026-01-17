# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**odu_core** is a Dart library providing core domain-driven design (DDD) building blocks and functional programming utilities. It includes:

- **Entity system**: Base class with identity, timestamps, change tracking, and deep equality
- **Result type**: Railway-oriented programming with sealed `Result<T>` (Ok/Err variants)
- **Option type**: Type-safe null handling with sealed `Option<T>` (Some/None variants)
- **Future extensions**: `FutureResult<T>` and `FutureOption<T>` with ergonomic async utilities
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
- `Result<T>` is a sealed class with `Ok<T>` and `Err<T>` variants
- Use pattern matching with switch statements to handle both cases
- `FutureResult<T>` type alias for `Future<Result<T>>` (common async pattern with extension methods)
- `Unit` type for void-like returns (use `ok` constant for success with no value)

### Future Extensions (`lib/src/future_result.dart` and `lib/src/future_option.dart`)

Ergonomic async utilities for Result and Option types:
- `FutureResult<T>` provides methods like `map`, `flatMap`, `recover`, `unwrapOr`, etc.
- `FutureOption<T>` provides methods like `map`, `filter`, `okOr`, `unwrapOr`, etc.
- Both support async transformations (e.g., `mapAsync`, `flatMapAsync`)
- Timeout support with `withTimeout`
- `FutureResultList.waitAll` and `FutureResultList.waitAllOrError` for combining multiple futures

**Note:** The old `Task<T>` type alias is deprecated in favor of `FutureResult<T>`

### Optimistic Updates (`lib/src/optmistic_value.dart`)

Stream-based state management with automatic rollback:
- `OptimisticValue<T>` wraps a source stream and adds optimistic updates
- `update()` applies updater function immediately, then runs async task (returns `FutureResult<R>`)
- Automatically rolls back to previous state if task returns `Err`
- Uses broadcast streams to merge source and optimistic updates
- `ListReplacer<T>` utility for updating items in lists by predicate

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
