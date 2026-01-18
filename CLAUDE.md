# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**odu_core** is a Dart library providing core domain-driven design (DDD) building blocks and functional programming utilities. It includes:

- **Entity system**: Base classes with identity, timestamps, change tracking, and ID-based equality
- **Result type**: Railway-oriented programming with sealed `Result<T>` (`Ok`/`Err` variants)
- **Option type**: Type-safe null handling with sealed `Option<T>` (`Some`/`None` variants)
- **Future extensions**: `FutureResult<T>` and `FutureOption<T>` with ergonomic async utilities
- **Optimistic updates**: Stream-based optimistic UI state management with automatic rollback
- **Specification pattern**: Composable business rules with `and`/`or`/`not` operators
- **Setup utilities**: Sequential and parallel initialization task orchestration

## Development Commands

```bash
# Testing
dart test                          # Run all tests
dart test test/entity_test.dart    # Run a single test file

# Analysis & Linting
dart analyze                       # Run static analysis
dart fix --dry-run                 # Preview available fixes
dart fix --apply                   # Apply automatic fixes

# Dependencies
dart pub get                       # Install dependencies
dart pub upgrade                   # Upgrade dependencies

# Running examples
dart run example/odu_core_example.dart
```

## Architecture

### Entity System (`lib/src/entities.dart`)

Three base classes for domain entities with different identity strategies:

| Base Class | ID Type | Use Case |
|------------|---------|----------|
| `Entity<T>` | Generic `T` | Custom ID types (Value Objects, composite keys) |
| `GuidEntity` | `String` (UUID) | Client-generated IDs, distributed systems |
| `SerialEntity` | `int` | Database auto-increment IDs |

Key features:
- **Identity-based equality**: Entities with same ID and type are equal (DDD principle)
- **Timestamps**: `createdAt`, `updatedAt` for audit tracking
- **Change tracking**: `hasChanged` computed from timestamps (`updatedAt > createdAt`)
- **Soft delete**: `isActive` flag with `isDeleted` convenience getter
- **Validation hook**: Override `validate()` to enforce invariants (called in constructor)
- **Debug props**: Override `props` getter for `toString()` output (not used for equality)

Serial entity utilities:
- `SerialEntity.unsavedId` (0) for unpersisted entities
- `isPersisted` / `isNew` convenience getters

GUID entity utilities:
- `GuidEntity.newId()` generates UUID v4

### Failure System (`lib/src/failure.dart`)

Base class for domain failures:
- `Failure` abstract class extending `Exception`
- `EntityFailure` for entity-related validation failures
- Extend these for domain-specific failure types

### Result Type (`lib/src/result.dart`)

Railway-oriented programming pattern:
- `Result<T>` sealed class with `Ok<T>` and `Err<T>` variants
- `Err` holds `Exception` and optional `StackTrace`
- `Unit` type for void-like returns (use `ok` constant for `Ok(unit)`)
- Use pattern matching with switch expressions

Methods: `map`, `mapErr`, `flatMap`, `unwrap`, `unwrapOr`, `unwrapOrElse`, `isOk`, `isFail`

### Option Type (`lib/src/option.dart`)

Type-safe null handling:
- `Option<T>` sealed class with `Some<T>` and `None<T>` variants
- `okOr(Exception)` converts to `Result<T>`

Methods: `map`, `unwrap`, `unwrapOr`, `isSome`, `isNone`

### Future Extensions (`lib/src/future_result.dart`, `lib/src/future_option.dart`)

Type aliases and extension methods for async operations:

**FutureResult<T>** (`Future<Result<T>>`):
- Sync transforms: `map`, `mapErr`, `flatMap`
- Async transforms: `mapAsync`, `mapErrAsync`, `flatMapAsync`
- Recovery: `recover`, `recoverAsync`, `recoverWith`, `recoverWithAsync`
- Extraction: `unwrap`, `unwrapOr`, `unwrapOrElse`, `unwrapOrElseAsync`
- Utilities: `inspect`, `inspectErr`, `toOption`, `withTimeout`
- Factory: `FutureResultFactory.ok()`, `.err()`, `.from()`

**FutureResultList** (combining multiple futures):
- `waitAll` - wait for all, return list of results
- `waitAllOrError` - return `Ok(List)` if all succeed, first `Err` otherwise
- `any` - return first `Ok`, or aggregated error if all fail

**FutureOption<T>** (`Future<Option<T>>`):
- Similar API to FutureResult with `filter`, `filterAsync`, `toNullable`
- Factory: `FutureOptionFactory.some()`, `.none()`, `.from()`

### Optimistic Updates (`lib/src/optmistic_value.dart`)

Stream-based state management with automatic rollback:
- `OptimisticValue<T>` wraps a source stream
- `update(task, updater)` applies updater immediately, runs async task
- Automatically rolls back if task returns `Err`
- `ListReplacer<T>` utility for updating items in lists by predicate

### Specification Pattern (`lib/src/specification.dart`)

Composable business rules:
- `Specification<T>` interface with `isSatisfiedBy(T entity)` method
- Extension methods: `.and()`, `.or()`, `.not()`
- Built-in: `AndSpecification`, `OrSpecification`, `NotSpecification`

### Setup Utilities (`lib/src/setup.dart`)

Initialization task orchestration:
- `SetupTask` interface returning `FutureResult<Unit>`
- `ParallelSetup` runs multiple tasks concurrently
- `setup(List<SetupTask>)` runs tasks sequentially, throws `SetupException` on failure

### Deprecated (`lib/src/task.dart`)

- `Task<T>` - use `FutureResult<T>` instead
- `TaskList` - use `FutureResultList` instead

## Code Style

- Dart SDK: `^3.10.4`
- Linting: `package:lints/recommended.yaml`
- Dependencies: `uuid` (^4.5.2), `collection` (^1.19.1)
- Use `final class` for sealed type variants
- Use `const` constructors for immutable types
- Pattern matching with switch expressions for Result/Option handling

## Entity Creation Rules

See `.claude/rules/entity-creation.md` for detailed guidelines on:
- Choosing identity type (GUID vs Serial vs Custom)
- Private constructor pattern
- Required factory methods (`create`, `fromPersistence`)
- Encapsulation (protecting collections, domain methods)
- Validation and failure handling
- Code smells to avoid
