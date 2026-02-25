String? validatePrompt(String? text) {
  if (text == null || text.trim().isEmpty) {
    return 'Please enter a prompt.';
  }
  if (text.trim().length < 10) {
    return 'Prompt must be at least 10 characters.';
  }
  if (text.length > 2000) {
    return 'Prompt must not exceed 2000 characters.';
  }
  return null;
}
