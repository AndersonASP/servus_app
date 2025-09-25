// Configuração para Flutter Web
// Este arquivo é carregado externamente para evitar problemas de CSP

(function() {
  'use strict';
  
  // Detectar se estamos em uma página de formulário público
  function isPublicFormPage() {
    const path = window.location.pathname;
    return path.includes('/forms/public/');
  }
  
  // Extrair ID do formulário da URL
  function extractFormId() {
    const path = window.location.pathname;
    const match = path.match(/\/forms\/public\/([a-f0-9]{24})/);
    return match ? match[1] : null;
  }
  
  // Configurar rota inicial se necessário
  if (isPublicFormPage()) {
    const formId = extractFormId();
    if (formId) {
      window.flutter_web_initial_route = `/forms/public/${formId}`;
    }
  }
  
  // Log para debug
  console.log('Flutter Web Config loaded:', {
    currentPath: window.location.pathname,
    isPublicForm: isPublicFormPage(),
    formId: extractFormId(),
    initialRoute: window.flutter_web_initial_route
  });
})();
