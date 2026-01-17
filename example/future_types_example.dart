import 'package:odu_core/odu_core.dart';

// Example: Simulated User model
class User {
  final String id;
  final String name;
  final String email;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isActive = true,
  });

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, isActive: $isActive)';
}

// Example: Simulated database
class Database {
  final Map<String, User> _users = {
    '1': const User(id: '1', name: 'Alice', email: 'alice@example.com'),
    '2': const User(id: '2', name: 'Bob', email: 'bob@example.com', isActive: false),
    '3': const User(id: '3', name: 'Charlie', email: 'charlie@example.com'),
  };

  Future<User?> findById(String id) async {
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate latency
    return _users[id];
  }

  Future<User?> findByEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate latency
    for (final user in _users.values) {
      if (user.email == email) return user;
    }
    return null;
  }
}

final database = Database();

// ============================================================================
// FutureResult Examples
// ============================================================================

/// Fetches a user by ID, returning a Result
FutureResult<User> fetchUser(String id) async {
  try {
    final user = await database.findById(id);
    if (user != null) {
      return Ok(user);
    }
    return Err(Exception('User not found with id: $id'));
  } catch (e, stackTrace) {
    return Err(e is Exception ? e : Exception(e.toString()), stackTrace);
  }
}

/// Fetches a user's name, with error recovery
FutureResult<String> getUserName(String id) {
  return fetchUser(id)
      .map((user) => user.name)
      .recover((error) => 'Unknown User');
}

/// Chains multiple async operations
FutureResult<String> getUserEmail(String id) async {
  return fetchUser(id)
      .map((user) => user.email)
      .mapAsync((email) async {
        // Simulate email validation
        await Future.delayed(const Duration(milliseconds: 5));
        return email.toLowerCase();
      });
}

/// Demonstrates flatMap for conditional logic
FutureResult<User> getActiveUser(String id) {
  return fetchUser(id).flatMap((user) {
    if (user.isActive) {
      return Ok(user);
    }
    return Err(Exception('User ${user.id} is inactive'));
  });
}

/// Demonstrates error handling with recovery
FutureResult<User> getUserOrFallback(String id, User fallback) {
  return fetchUser(id).recoverWith((error) => Ok(fallback));
}

// ============================================================================
// FutureOption Examples
// ============================================================================

/// Finds a user by email, returning an Option
FutureOption<User> findUserByEmail(String email) async {
  final user = await database.findByEmail(email);
  return user != null ? Some(user) : const None();
}

/// Filters users by active status
FutureOption<User> findActiveUserByEmail(String email) {
  return findUserByEmail(email).filter((user) => user.isActive);
}

/// Converts Option to Result
FutureResult<User> getUserByEmailOrError(String email) {
  return findUserByEmail(email).okOr(Exception('No user found with email: $email'));
}

/// Demonstrates flatMap with Option
FutureOption<String> getActiveUserName(String email) {
  return findUserByEmail(email).flatMap((user) {
    return user.isActive ? Some(user.name) : const None();
  });
}

// ============================================================================
// Parallel Operations with FutureResultList
// ============================================================================

/// Fetches multiple users in parallel
Future<Result<List<User>>> fetchMultipleUsers(List<String> ids) {
  final futures = ids.map((id) => fetchUser(id)).toList();
  return FutureResultList.waitAllOrError(futures);
}

/// Gets the first available user from multiple IDs
Future<Result<User>> getFirstAvailableUser(List<String> ids) {
  final futures = ids.map((id) => fetchUser(id)).toList();
  return FutureResultList.any(futures);
}

// ============================================================================
// Main function demonstrating all examples
// ============================================================================

void main() async {
  print('=== FutureResult Examples ===\n');

  // Example 1: Basic fetch
  print('1. Fetching user with ID "1":');
  final result1 = await fetchUser('1');
  switch (result1) {
    case Ok(value: final user):
      print('   Success: $user');
    case Err(value: final error):
      print('   Error: $error');
  }

  // Example 2: Fetch with error
  print('\n2. Fetching non-existent user with ID "999":');
  final result2 = await fetchUser('999');
  switch (result2) {
    case Ok(value: final user):
      print('   Success: $user');
    case Err(value: final error):
      print('   Error: $error');
  }

  // Example 3: Transform with map
  print('\n3. Getting user name for ID "1":');
  final result3 = await getUserName('1');
  print('   Result: $result3');

  // Example 4: Error recovery
  print('\n4. Getting user name with recovery for ID "999":');
  final result4 = await getUserName('999');
  print('   Result: $result4');

  // Example 5: Async transformation
  print('\n5. Getting lowercase email for ID "1":');
  final result5 = await getUserEmail('1');
  switch (result5) {
    case Ok(value: final email):
      print('   Email: $email');
    case Err(value: final error):
      print('   Error: $error');
  }

  // Example 6: Conditional logic with flatMap
  print('\n6. Getting active user with ID "2" (inactive):');
  final result6 = await getActiveUser('2');
  switch (result6) {
    case Ok(value: final user):
      print('   Success: $user');
    case Err(value: final error):
      print('   Error: $error');
  }

  print('\n=== FutureOption Examples ===\n');

  // Example 7: Find by email
  print('7. Finding user by email "alice@example.com":');
  final option1 = await findUserByEmail('alice@example.com');
  switch (option1) {
    case Some(value: final user):
      print('   Found: $user');
    case None():
      print('   Not found');
  }

  // Example 8: Filter by active status
  print('\n8. Finding active user by email "bob@example.com":');
  final option2 = await findActiveUserByEmail('bob@example.com');
  switch (option2) {
    case Some(value: final user):
      print('   Found: $user');
    case None():
      print('   Not found (user may be inactive)');
  }

  // Example 9: Convert Option to Result
  print('\n9. Getting user by email or error:');
  final result7 = await getUserByEmailOrError('charlie@example.com');
  switch (result7) {
    case Ok(value: final user):
      print('   Success: $user');
    case Err(value: final error):
      print('   Error: $error');
  }

  print('\n=== Parallel Operations ===\n');

  // Example 10: Fetch multiple users
  print('10. Fetching multiple users in parallel:');
  final result8 = await fetchMultipleUsers(['1', '2', '3']);
  switch (result8) {
    case Ok(value: final users):
      print('    Fetched ${users.length} users:');
      for (final user in users) {
        print('    - $user');
      }
    case Err(value: final error):
      print('    Error: $error');
  }

  // Example 11: Get first available user
  print('\n11. Getting first available user from IDs [999, 1, 2]:');
  final result9 = await getFirstAvailableUser(['999', '1', '2']);
  switch (result9) {
    case Ok(value: final user):
      print('    First available: $user');
    case Err(value: final error):
      print('    Error: $error');
  }

  print('\n=== Chaining Example ===\n');

  // Example 12: Complex chaining
  print('12. Complex chaining with error handling:');
  final result10 = await fetchUser('1')
      .map((user) => user.name)
      .mapAsync((name) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return name.toUpperCase();
      })
      .inspect((name) => print('    Transformed name: $name'))
      .recover((error) => 'UNKNOWN');

  switch (result10) {
    case Ok(value: final name):
      print('    Final result: $name');
    case Err(value: final error):
      print('    Error: $error');
  }
}
