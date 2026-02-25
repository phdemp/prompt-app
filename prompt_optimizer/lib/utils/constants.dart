const String kApiBaseUrl = 'http://10.0.2.2:3000'; // Android emulator
// const String kApiBaseUrl = 'http://localhost:3000'; // iOS simulator / web

// Optimization types (must match backend VALID_TYPES exactly)
const List<Map<String, String>> kOptimizationTypes = [
  {'value': 'general', 'label': 'General'},
  {'value': 'coding', 'label': 'Coding'},
  {'value': 'creative', 'label': 'Creative'},
  {'value': 'analysis', 'label': 'Analysis'},
  {'value': 'instruction', 'label': 'Instruction'},
];
