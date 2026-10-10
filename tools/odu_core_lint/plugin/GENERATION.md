# Generation conventions

All current and future Odu code generators target Dart 3.13.2 or later.

Generated Dart source must:

- support positional, named, private, named, mutable, constant, and
  super-forwarding primary constructors;
- distinguish declaring parameters (`final` or `var`) from ordinary and
  `super` parameters;
- inspect resolved elements instead of reconstructing fields from source text;
- use dot shorthand when the surrounding context determines the omitted type;
- emit source accepted by `dart format` and the repository analyzer settings;
- include regression tests for each syntax form it consumes.

When a generator has no valid contextual type for a dot shorthand, it should
emit the explicit type rather than manufacture context or weaken inference.
