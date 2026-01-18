# Entity Creation Rules

Guidelines for creating domain entities in odu_core. These rules apply to both AI assistants and developers.

## Identity Type Selection

Choose the appropriate base class for your entity:

| Base Class     | ID Type         | Use When                                                                   |
| -------------- | --------------- | -------------------------------------------------------------------------- |
| `GuidEntity`   | `String` (UUID) | IDs are generated client-side, distributed systems, offline-first apps     |
| `SerialEntity` | `int`           | IDs come from database auto-increment, centralized persistence             |
| `Entity<T>`    | Custom `T`      | Domain requires specific ID format (e.g., `Email`, `Slug`, composite keys) |

**Key differences:**

- **GuidEntity**: Use `GuidEntity.newId()` to generate UUID v4 in creation factories
- **SerialEntity**: Use `SerialEntity.unsavedId` (0) for new entities; provides `isPersisted`/`isNew` getters
- **Entity<T>**: For custom ID types; create Value Objects for the ID type

For custom identity types, create a Value Object for the ID and extend `Entity<YourIdType>`.

## Required Structure

### 1. Public Constructor

All entities MUST have a public constructor that receives all fields:

```dart
class Order extends GuidEntity {
  final String customerId;
  final List<OrderItem> _items;
  OrderStatus _status;

  Order({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.isActive,
    required this.customerId,
    required List<OrderItem> items,
    required OrderStatus status,
  }) : _items = items.toList(),
       _status = status;
}
```

**Why public constructor with all fields?**
- Enables reconstituting entities from persistence without needing a separate factory
- All fields must be provided (via required parameters or defaults)
- Validation is enforced via `validate()` hook called by Entity base class

### 2. Creation Factory (Recommended)

Entities SHOULD have factory methods for common creation scenarios:

**For GuidEntity:**
```dart
factory Order.create({required String customerId}) {
  final now = DateTime.now();
  return Order(
    id: GuidEntity.newId(),
    createdAt: now,
    updatedAt: now,
    isActive: true,
    customerId: customerId,
    items: [],
    status: OrderStatus.draft,
  );
}
```

**For SerialEntity:**
```dart
factory Product.create({required String name}) {
  final now = DateTime.now();
  return Product(
    id: SerialEntity.unsavedId,  // 0 for new entities
    createdAt: now,
    updatedAt: now,
    isActive: true,
    name: name,
  );
}
```

**Best practices:**
- Name the primary factory `.create()` for consistency
- Set `isActive: true` by default for new entities
- Initialize `createdAt` and `updatedAt` to the same value (no change on creation)
- Factories are optional since the public constructor can be used directly for persistence

### 3. Multiple Creation Factories (Optional)

When entities have multiple valid creation paths, use named factories:

```dart
factory Order.create({required String customerId}) {
  final now = DateTime.now();
  return Order(
    id: GuidEntity.newId(),
    createdAt: now,
    updatedAt: now,
    isActive: true,
    customerId: customerId,
    items: [],
    status: OrderStatus.draft,
  );
}

factory Order.withItems({
  required String customerId,
  required List<OrderItem> items,
}) {
  final now = DateTime.now();
  return Order(
    id: GuidEntity.newId(),
    createdAt: now,
    updatedAt: now,
    isActive: true,
    customerId: customerId,
    items: items,
    status: OrderStatus.draft,
  );
}
```

**Naming conventions:**
- Use descriptive names that indicate the creation path
- Primary factory should be `.create()`
- Consider `.withX()` for variations with additional data

## Encapsulation Rules

### Protect Internal Collections

NEVER expose mutable collections directly. Return unmodifiable views:

```dart
// BAD: Exposes internal mutable state
class Order {
  final List<OrderItem> _items;
  List<OrderItem> get items => _items;  // External code can call .add()!
}

// GOOD: Return unmodifiable view
class Order {
  final List<OrderItem> _items;
  List<OrderItem> get items => List.unmodifiable(_items);
}
```

### Use Domain Methods for State Changes

Entities SHOULD expose behavior through methods that modify state:

```dart
// BAD: Anemic model with public mutable data
class Order {
  List<OrderItem> items = [];
  OrderStatus status = OrderStatus.draft;
}

// GOOD: Rich domain model with behavior
class Order {
  final List<OrderItem> _items;
  OrderStatus _status;

  // Domain methods modify internal state
  void addItem(OrderItem item) {
    if (_status != OrderStatus.draft) {
      throw OrderFailure('Cannot add items to non-draft order');
    }
    _items.add(item);
    updatedAt = DateTime.now();
  }

  void removeItem(String itemId) {
    if (_status != OrderStatus.draft) {
      throw OrderFailure('Cannot remove items from non-draft order');
    }
    _items.removeWhere((i) => i.id == itemId);
    updatedAt = DateTime.now();
  }

  void submit() {
    if (!canBeSubmitted) {
      throw OrderFailure('Order cannot be submitted');
    }
    _status = OrderStatus.submitted;
    updatedAt = DateTime.now();
  }
}
```

**Key principles:**
- Domain methods should mutate entity state directly (entities are mutable)
- Always update `updatedAt` when state changes
- Enforce business rules before allowing state changes
- Use private fields with controlled access through methods

## Validation

### Enforce Invariants via validate()

Override `validate()` to enforce business rules. This is called automatically by the Entity constructor:

```dart
@override
void validate() {
  if (customerId.isEmpty) {
    throw OrderFailure('Customer ID cannot be empty');
  }
  if (_items.isEmpty && status == OrderStatus.submitted) {
    throw OrderFailure('Submitted order must have at least one item');
  }
}
```

**Best practices:**

- Validate invariants that MUST always be true
- Throw specific failure types (extend `EntityFailure`)
- Keep validation pure (no side effects)
- Don't validate business rules that are contextual (use domain methods instead)

### Create Specific Failure Types

Each aggregate root SHOULD define its own failure class:

```dart
class OrderFailure extends EntityFailure {
  OrderFailure(super.message);
}
```

**Why specific failures?**

- Enables type-safe error handling
- Makes domain errors explicit and discoverable
- Aligns with Result type error handling patterns

## Props for Debugging

Override `props` to include domain-specific properties in `toString()`:

```dart
@override
List<Object?> get props => [customerId, 'items: ${_items.length}'];
```

Note: `props` is for debugging only and does NOT affect equality. Entities are equal by ID.

## Documentation Guidelines

Document only what is necessary:

- **DO** document non-obvious business rules in `validate()`
- **DO** document factory methods when creation involves complex logic
- **DO** document side effects or constraints on domain methods
- **DON'T** document obvious getters, constructors, or standard patterns
- **DON'T** add redundant `@override` documentation

## Best Practices

1. **Keep entities focused**: One aggregate root per bounded context concern
2. **Prefer composition**: Use Value Objects for complex attributes
3. **Make illegal states unrepresentable**: Use types and validation to prevent invalid states
4. **Update timestamps explicitly**: Always set `updatedAt = DateTime.now()` when modifying entity state
5. **Use `SerialEntity.unsavedId`**: For new serial entities not yet persisted (value is 0)
6. **Use `GuidEntity.newId()`**: For generating new UUIDs in creation factories
7. **Protect collections**: Return unmodifiable views from getters to prevent external mutation
8. **Use domain methods**: Expose behavior through methods, not direct property access
9. **Validate consistently**: Use `validate()` for invariants, domain methods for contextual rules
10. **Entities are mutable**: Change state directly in domain methods; no need for `copyWith`

## Code Smells to Avoid

| Smell                           | Problem                                    | Solution                                   |
| ------------------------------- | ------------------------------------------ | ------------------------------------------ |
| Public setters                  | Breaks encapsulation, allows invalid state | Use domain methods that enforce rules      |
| Public mutable collections      | External code can corrupt internal state   | Return unmodifiable views from getters     |
| Empty `validate()`              | Invariants not enforced                    | Add business rule validation               |
| Logic in getters                | Hidden side effects, hard to test          | Extract to explicit methods                |
| Entity without behavior         | Anemic domain model                        | Add domain methods that modify state       |
| Setters for computed properties | Inconsistent state                         | Make computed props read-only getters      |
| Inheritance for code reuse      | Tight coupling                             | Use composition with Value Objects         |
| ID as primitive in domain logic | Primitive obsession                        | Create ID Value Objects when needed        |
| Using `copyWith` in entities    | Treats entities as immutable               | Mutate state directly in domain methods    |
| Not updating `updatedAt`        | Breaks audit trail                         | Set `updatedAt = DateTime.now()` on changes|
| Private constructor only        | Can't reconstitute from database           | Use public constructor for all fields      |

## Complete Example

```dart
import 'package:odu_core/odu_core.dart';

// Domain-specific failure
class OrderFailure extends EntityFailure {
  OrderFailure(super.message);
}

// Value object for line items
class OrderItem {
  final String productId;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;
}

// Enum for order status
enum OrderStatus { draft, submitted, confirmed, shipped, delivered, cancelled }

// Aggregate root entity (mutable)
class Order extends GuidEntity {
  final String customerId;
  final List<OrderItem> _items;
  OrderStatus _status;

  // Public constructor - can be used directly for persistence
  Order({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.isActive,
    required this.customerId,
    required List<OrderItem> items,
    required OrderStatus status,
  })  : _items = items.toList(),
        _status = status;

  // Factory for creating new orders (optional convenience)
  factory Order.create({required String customerId}) {
    final now = DateTime.now();
    return Order(
      id: GuidEntity.newId(),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      customerId: customerId,
      items: [],
      status: OrderStatus.draft,
    );
  }

  // Read-only access to protected collection
  List<OrderItem> get items => List.unmodifiable(_items);

  // Read-only access to status
  OrderStatus get status => _status;

  // Computed properties
  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get canBeSubmitted => _items.isNotEmpty && _status == OrderStatus.draft;
  bool get isEmpty => _items.isEmpty;

  // Domain methods (mutate state directly)
  void addItem(OrderItem item) {
    if (_status != OrderStatus.draft) {
      throw OrderFailure('Cannot add items to non-draft order');
    }
    _items.add(item);
    updatedAt = DateTime.now();
  }

  void removeItem(String productId) {
    if (_status != OrderStatus.draft) {
      throw OrderFailure('Cannot remove items from non-draft order');
    }
    _items.removeWhere((i) => i.productId == productId);
    updatedAt = DateTime.now();
  }

  void submit() {
    if (!canBeSubmitted) {
      throw OrderFailure('Order cannot be submitted: must have items and be in draft status');
    }
    _status = OrderStatus.submitted;
    updatedAt = DateTime.now();
  }

  void cancel() {
    if (_status == OrderStatus.delivered) {
      throw OrderFailure('Cannot cancel delivered order');
    }
    _status = OrderStatus.cancelled;
    isActive = false;
    updatedAt = DateTime.now();
  }

  void confirm() {
    if (_status != OrderStatus.submitted) {
      throw OrderFailure('Can only confirm submitted orders');
    }
    _status = OrderStatus.confirmed;
    updatedAt = DateTime.now();
  }

  // Validation called by Entity constructor
  @override
  void validate() {
    if (customerId.isEmpty) {
      throw OrderFailure('Customer ID is required');
    }
    if (_status == OrderStatus.submitted && _items.isEmpty) {
      throw OrderFailure('Submitted order must have at least one item');
    }
  }

  // Debug properties (NOT used for equality)
  @override
  List<Object?> get props => [
        customerId,
        _status,
        'items: ${_items.length}',
        'total: \$${total.toStringAsFixed(2)}',
      ];
}
```

**Usage example:**
```dart
void main() {
  // Create new order using factory
  final order = Order.create(customerId: 'cust-123');
  print(order); // Order(id: <uuid>, active: true, cust-123, draft, ...)

  // Add items through domain methods (mutates state)
  final item1 = OrderItem(productId: 'prod-1', quantity: 2, price: 10.00);
  final item2 = OrderItem(productId: 'prod-2', quantity: 1, price: 25.00);
  
  order.addItem(item1);
  order.addItem(item2);
  
  print('Total: \$${order.total}'); // Total: $45.00
  print('Status: ${order.status}'); // Status: OrderStatus.draft

  // Submit order (mutates state)
  order.submit();
  print('Status: ${order.status}'); // Status: OrderStatus.submitted

  // Attempting to add items after submission throws
  try {
    order.addItem(item1); // Throws OrderFailure
  } catch (e) {
    print(e); // Cannot add items to non-draft order
  }

  // Reconstitute from database using public constructor
  final persistedOrder = Order(
    id: '550e8400-e29b-41d4-a716-446655440000',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
    isActive: true,
    customerId: 'cust-456',
    items: [item1],
    status: OrderStatus.confirmed,
  );
  
  print(persistedOrder.total); // $20.00
  
  // Mutate persisted order
  persistedOrder.addItem(item2);
  print(persistedOrder.total); // $45.00
  print(persistedOrder.hasChanged); // true (updatedAt > createdAt)
}
```
