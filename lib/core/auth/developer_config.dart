/// Developer account configuration.
/// Controls access to Ollama AI and other developer-only features.
library;

/// Set of email addresses that have developer-level access.
/// Add your email here to unlock developer options in the Profile screen.
const developerEmails = {'nobedes32@gmail.com'};

/// Returns true if [email] belongs to a registered developer account.
bool isDeveloper(String? email) =>
    email != null && developerEmails.contains(email.trim().toLowerCase());
