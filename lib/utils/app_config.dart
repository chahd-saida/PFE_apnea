class AppConfig {
  // Serveur FastAPI local avec Groq intégré
  static const String serverBaseUrl = 'http://192.168.1.18:8000';
    // Serveur FastAPI local avec Groq intégré
  //static const String serverBaseUrl = 'http://localhost:8000';
  
  // Endpoints chatbot
  static const String chatEndpoint        = '/chatbot/chat';
  static const String resumeNuitEndpoint  = '/chatbot/resume_nuit';
  static const String analyseAlarmeEndpoint = '/chatbot/analyse_alarme';
  static const String statutChatEndpoint  = '/chatbot/statut';
  static const String analyseNuitEndpoint = '/chatbot/analyse_nuit';
  static const String casCritiquesEndpoint = '/chatbot/cas_critiques';
}