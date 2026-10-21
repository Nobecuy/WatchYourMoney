// Finance tool definitions and parameter validation.

import 'dart:convert';

/// Tool parameter schemas for validation.
class FinanceToolSchemas {
  static const Map<String, Map<String, dynamic>> schemas = {
    'get_financial_summary': {
      'type': 'object',
      'properties': {
        'period': {'type': 'string', 'enum': ['week', 'month', 'all']},
      },
      'required': ['period'],
    },
    'get_transactions': {
      'type': 'object',
      'properties': {
        'date_from': {'type': 'string', 'format': 'date'},
        'date_to': {'type': 'string', 'format': 'date'},
        'category': {'type': 'string'},
        'type': {'type': 'string', 'enum': ['income', 'expense']},
        'payment_method': {'type': 'string', 'enum': ['card', 'cash']},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200, 'default': 50},
      },
      'required': [],
    },
    'get_spending_analysis': {
      'type': 'object',
      'properties': {
        'period': {'type': 'string', 'enum': ['week', 'month', 'all']},
        'group_by': {'type': 'string', 'enum': ['category', 'payment_method'], 'default': 'category'},
      },
      'required': ['period'],
    },
    'calculate_savings_plan': {
      'type': 'object',
      'properties': {
        'target_amount': {'type': 'integer', 'minimum': 1},
        'monthly_saving': {'type': 'integer', 'minimum': 1},
        'current_savings': {'type': 'integer', 'minimum': 0, 'default': 0},
      },
      'required': ['target_amount', 'monthly_saving'],
    },
    'propose_transaction': {
      'type': 'object',
      'properties': {
        'type': {'type': 'string', 'enum': ['income', 'expense']},
        'amount': {'type': 'integer', 'minimum': 1},
        'category_id': {'type': 'string', 'minLength': 1},
        'note': {'type': 'string'},
        'date': {'type': 'string', 'format': 'date'},
        'payment_method': {'type': 'string', 'enum': ['card', 'cash'], 'default': 'cash'},
      },
      'required': ['type', 'amount', 'category_id'],
    },
    'confirm_transaction': {
      'type': 'object',
      'properties': {
        'idempotency_key': {'type': 'string', 'minLength': 1},
      },
      'required': ['idempotency_key'],
    },
    'propose_transaction_update': {
      'type': 'object',
      'properties': {
        'transaction_id': {'type': 'string', 'minLength': 1},
        'amount': {'type': 'integer', 'minimum': 1},
        'category_id': {'type': 'string'},
        'note': {'type': 'string'},
        'date': {'type': 'string', 'format': 'date'},
        'payment_method': {'type': 'string', 'enum': ['card', 'cash']},
      },
      'required': ['transaction_id'],
    },
    'confirm_transaction_update': {
      'type': 'object',
      'properties': {
        'idempotency_key': {'type': 'string', 'minLength': 1},
      },
      'required': ['idempotency_key'],
    },
  };

  /// Validate tool arguments against schema.
  static (bool, String?) validate(String toolName, Map<String, dynamic> args) {
    final schema = schemas[toolName];
    if (schema == null) {
      return (false, 'Unknown tool: $toolName');
    }

    // Check required fields
    final required = schema['required'] as List? ?? [];
    for (final field in required) {
      if (!args.containsKey(field) || args[field] == null) {
        return (false, 'Missing required field: $field');
      }
    }

    // Type validation for known fields
    final properties = schema['properties'] as Map<String, dynamic>;
    for (final entry in args.entries) {
      final propSchema = properties[entry.key];
      if (propSchema == null) continue;

      final expectedType = propSchema['type'] as String?;
      if (expectedType != null && !_checkType(entry.value, expectedType)) {
        return (false, 'Invalid type for ${entry.key}: expected $expectedType, got ${entry.value.runtimeType}');
      }

      // Enum validation
      final enumValues = propSchema['enum'] as List?;
      if (enumValues != null && !enumValues.contains(entry.value)) {
        return (false, 'Invalid value for ${entry.key}: must be one of $enumValues');
      }

      // Minimum validation for integers
      if (expectedType == 'integer') {
        final min = propSchema['minimum'] as int?;
        if (min != null && (entry.value as num) < min) {
          return (false, '${entry.key} must be >= $min');
        }
        final max = propSchema['maximum'] as int?;
        if (max != null && (entry.value as num) > max) {
          return (false, '${entry.key} must be <= $max');
        }
      }
    }

    return (true, null);
  }

  static bool _checkType(dynamic value, String expectedType) {
    switch (expectedType) {
      case 'string':
        return value is String;
      case 'integer':
        return value is int || (value is num && value == value.toInt());
      case 'number':
        return value is num;
      case 'boolean':
        return value is bool;
      default:
        return true; // Unknown type, skip validation
    }
  }
}

/// Tool call representation for the LLM.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arguments': arguments,
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String,
        name: json['name'] as String,
        arguments: Map<String, dynamic>.from(json['arguments'] as Map),
      );

  /// Validate this tool call.
  (bool, String?) validate() => FinanceToolSchemas.validate(name, arguments);
}

/// Tool result for returning to the LLM.
class ToolResult {
  final String toolCallId;
  final String name;
  final dynamic result;
  final bool isError;

  ToolResult({
    required this.toolCallId,
    required this.name,
    required this.result,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'tool_call_id': toolCallId,
        'name': name,
        'content': isError ? 'Error: $result' : json.encode(result),
        'is_error': isError,
      };
}

/// Ollama-compatible tool definitions.
class FinanceToolDefinitions {
  static List<OllamaTool> getToolDefinitions() {
    return [
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'get_financial_summary',
          description: 'Get financial summary for a period (week, month, all)',
          parameters: {
            'type': 'object',
            'properties': {
              'period': {
                'type': 'string',
                'enum': ['week', 'month', 'all'],
                'description': 'Time period for summary',
              },
            },
            'required': ['period'],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'get_transactions',
          description: 'Get transactions with optional filters',
          parameters: {
            'type': 'object',
            'properties': {
              'date_from': {
                'type': 'string',
                'format': 'date',
                'description': 'Start date (YYYY-MM-DD)',
              },
              'date_to': {
                'type': 'string',
                'format': 'date',
                'description': 'End date (YYYY-MM-DD)',
              },
              'category': {
                'type': 'string',
                'description': 'Filter by category',
              },
              'type': {
                'type': 'string',
                'enum': ['income', 'expense'],
                'description': 'Filter by transaction type',
              },
              'payment_method': {
                'type': 'string',
                'enum': ['card', 'cash'],
                'description': 'Filter by payment method',
              },
              'limit': {
                'type': 'integer',
                'minimum': 1,
                'maximum': 200,
                'default': 50,
                'description': 'Maximum number of transactions',
              },
            },
            'required': [],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'get_spending_analysis',
          description: 'Get spending analysis grouped by category or payment method',
          parameters: {
            'type': 'object',
            'properties': {
              'period': {
                'type': 'string',
                'enum': ['week', 'month', 'all'],
                'description': 'Time period for analysis',
              },
              'group_by': {
                'type': 'string',
                'enum': ['category', 'payment_method'],
                'default': 'category',
                'description': 'Group by category or payment method',
              },
            },
            'required': ['period'],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'calculate_savings_plan',
          description: 'Calculate savings plan to reach a target',
          parameters: {
            'type': 'object',
            'properties': {
              'target_amount': {
                'type': 'integer',
                'minimum': 1,
                'description': 'Target amount in rupiah',
              },
              'monthly_saving': {
                'type': 'integer',
                'minimum': 1,
                'description': 'Monthly saving amount in rupiah',
              },
              'current_savings': {
                'type': 'integer',
                'minimum': 0,
                'default': 0,
                'description': 'Current savings amount in rupiah',
              },
            },
            'required': ['target_amount', 'monthly_saving'],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'propose_transaction',
          description: 'Propose a new transaction (requires user confirmation)',
          parameters: {
            'type': 'object',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['income', 'expense'],
                'description': 'Transaction type',
              },
              'amount': {
                'type': 'integer',
                'minimum': 1,
                'description': 'Amount in rupiah',
              },
              'category_id': {
                'type': 'string',
                'minLength': 1,
                'description': 'Category ID',
              },
              'note': {
                'type': 'string',
                'description': 'Optional note',
              },
              'date': {
                'type': 'string',
                'format': 'date',
                'description': 'Transaction date (YYYY-MM-DD)',
              },
              'payment_method': {
                'type': 'string',
                'enum': ['card', 'cash'],
                'default': 'cash',
                'description': 'Payment method',
              },
            },
            'required': ['type', 'amount', 'category_id'],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'confirm_transaction',
          description: 'Confirm and save a proposed transaction',
          parameters: {
            'type': 'object',
            'properties': {
              'idempotency_key': {
                'type': 'string',
                'minLength': 1,
                'description': 'Idempotency key from proposal',
              },
            },
            'required': ['idempotency_key'],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'propose_transaction_update',
          description: 'Propose an update to an existing transaction',
          parameters: {
            'type': 'object',
            'properties': {
              'transaction_id': {
                'type': 'string',
                'minLength': 1,
                'description': 'ID of transaction to update',
              },
              'amount': {
                'type': 'integer',
                'minimum': 1,
                'description': 'New amount in rupiah',
              },
              'category_id': {
                'type': 'string',
                'description': 'New category ID',
              },
              'note': {
                'type': 'string',
                'description': 'New note',
              },
              'date': {
                'type': 'string',
                'format': 'date',
                'description': 'New date (YYYY-MM-DD)',
              },
              'payment_method': {
                'type': 'string',
                'enum': ['card', 'cash'],
                'description': 'New payment method',
              },
            },
            'required': ['transaction_id'],
          },
        ),
      ),
      OllamaTool(
        type: 'function',
        function: OllamaToolFunction(
          name: 'confirm_transaction_update',
          description: 'Confirm and apply a proposed transaction update',
          parameters: {
            'type': 'object',
            'properties': {
              'idempotency_key': {
                'type': 'string',
                'minLength': 1,
                'description': 'Idempotency key from proposal',
              },
            },
            'required': ['idempotency_key'],
          },
        ),
      ),
    ];
  }
}

/// Ollama tool definition classes.
class OllamaTool {
  final String type;
  final OllamaToolFunction function;

  OllamaTool({
    required this.type,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
}

class OllamaToolFunction {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  OllamaToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}