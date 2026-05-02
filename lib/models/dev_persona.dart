enum DevPersona {
  architect,
  bugFixer,
  hacker,
  fullstack;

  String get displayName {
    switch (this) {
      case DevPersona.architect: return 'System Architect';
      case DevPersona.bugFixer: return 'Specialist BugFixer';
      case DevPersona.hacker: return 'Rapid Hacker';
      case DevPersona.fullstack: return 'Fullstack Ninja';
    }
  }

  String get personaDescription {
    switch (this) {
      case DevPersona.architect:
        return 'Writes clean, enterprise-grade code with extensive comments and design patterns.';
      case DevPersona.bugFixer:
        return 'Focuses on performance, technical debt, and robust error handling.';
      case DevPersona.hacker:
        return 'Experimental, rapid prototyping style. Uses advanced tricks and terse but powerful logic.';
      case DevPersona.fullstack:
        return 'Versatile and efficient. Bridges frontend and backend with modern best practices.';
    }
  }
}
