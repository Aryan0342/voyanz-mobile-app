/// Centralised French, English and Spanish string table.
///
/// Every entry supplies all three languages via [_l]. When adding a
/// string, never use a two-way `_fr ? .. : ..` ternary — Spanish would
/// silently fall back to English.
class AppTranslations {
  final String lang;
  const AppTranslations(this.lang);

  bool get _fr => lang == 'fr';
  bool get _es => lang == 'es';

  String _l(String fr, String en, String es) => _fr ? fr : (_es ? es : en);

  // ── Branding ───────────────────────────────────────────────────────────────
  String get tagline => _l(
    'Votre voyage spirituel commence ici',
    'Your spiritual journey begins here',
    'Tu viaje espiritual comienza aquí',
  );

  // ── Auth – login ────────────────────────────────────────────────────────────
  String get welcomeBack =>
      _l('Bon retour', 'Welcome Back', 'Bienvenido de nuevo');
  String get email => _l('E-mail', 'Email', 'Correo electrónico');
  String get loginOrEmail => _l(
    'Identifiant ou e-mail',
    'Login or email',
    'Usuario o correo electrónico',
  );
  String get loginRequired => _l(
    "L'identifiant ou l'e-mail est requis",
    'Login or email is required',
    'El usuario o correo electrónico es obligatorio',
  );
  String get emailRequired => _l(
    "L'e-mail est requis",
    'Email is required',
    'El correo es obligatorio',
  );
  String get password => _l('Mot de passe', 'Password', 'Contraseña');
  String get passwordRequired => _l(
    'Le mot de passe est requis',
    'Password is required',
    'La contraseña es obligatoria',
  );
  String get logIn => _l('Connexion', 'Log In', 'Iniciar sesión');
  String get noAccount => _l(
    'Pas de compte ? ',
    "Don't have an account? ",
    '¿No tienes una cuenta? ',
  );
  String get signUp => _l("S'inscrire", 'Sign Up', 'Registrarse');
  String get forgotPassword => _l(
    'Mot de passe oublié ?',
    'Forgot Password?',
    '¿Olvidaste tu contraseña?',
  );
  String get resetPasswordSubtitle => _l(
    "Saisissez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.",
    "Enter your email address and we'll send you a link to reset your password.",
    'Introduce tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
  );
  String get sendResetLink => _l(
    'Envoyer le lien',
    'Send Reset Link',
    'Enviar enlace',
  );
  String get resetLinkSent => _l(
    'Un e-mail vous a été envoyé pour réinitialiser votre mot de passe.',
    'An email has been sent to reset your password.',
    'Te hemos enviado un correo para restablecer tu contraseña.',
  );
  String get noAccountWithEmail => _l(
    'Aucun compte trouvé avec cette adresse e-mail.',
    'No account found with this email address.',
    'No se encontró ninguna cuenta con este correo electrónico.',
  );
  String resetLinkFailed(String err) => _l(
    "Échec de l'envoi du lien : $err",
    'Failed to send reset link: $err',
    'No se pudo enviar el enlace: $err',
  );
  String get backToLogin => _l(
    'Retour à la connexion',
    'Back to Login',
    'Volver al inicio de sesión',
  );

  // ── Auth – register ─────────────────────────────────────────────────────────
  String get createAccount =>
      _l('Créer un compte', 'Create Account', 'Crear una cuenta');
  String get joinCommunity => _l(
    'Rejoignez notre communauté de chercheurs',
    'Join our community of seekers',
    'Únete a nuestra comunidad de buscadores',
  );
  String get customer => _l('Client', 'Customer', 'Cliente');
  String get professional => _l('Professionnel', 'Professional', 'Profesional');
  String get iIdentifyAs => _l(
    'Je suis',
    'I identify as',
    'Me identifico como',
  );
  String get male => _l('Homme', 'Male', 'Hombre');
  String get female => _l('Femme', 'Female', 'Mujer');
  String get other => _l('Autre', 'Other', 'Otro');
  String get firstName => _l('Prénom', 'First name', 'Nombre');
  String get lastName => _l('Nom', 'Last name', 'Apellidos');
  String get displayName => _l(
    "Nom d'affichage",
    'Display name',
    'Nombre para mostrar',
  );
  String get dateOfBirth => _l(
    'Date de naissance',
    'Date of birth',
    'Fecha de nacimiento',
  );
  // Placeholder pattern: the letters stand for year/month/day, so they are
  // translated too (AAAA-MM-JJ in French, AAAA-MM-DD in Spanish).
  String get dateOfBirthHint => _l('AAAA-MM-JJ', 'YYYY-MM-DD', 'AAAA-MM-DD');
  String get country => _l('Pays', 'Country', 'País');
  String get mobile => _l('Mobile', 'Mobile', 'Móvil');
  String get confirmPassword => _l(
    'Confirmer le mot de passe',
    'Confirm password',
    'Confirmar contraseña',
  );
  String get passwordsNoMatch => _l(
    'Les mots de passe ne correspondent pas',
    'Passwords do not match',
    'Las contraseñas no coinciden',
  );
  String get min6Chars => _l(
    '6 caractères minimum',
    'Min 6 characters',
    'Mínimo 6 caracteres',
  );
  String get invalidEmail => _l(
    "Format d'e-mail invalide",
    'Invalid email format',
    'Formato de correo electrónico no válido',
  );
  String get invalidPhone => _l(
    'Numero de telephone invalide',
    'Invalid phone number',
    'Número de teléfono no válido',
  );
  String get passwordRules => _l(
    'Le mot de passe ne respecte pas les exigences de securite.',
    'Password does not meet the security requirements.',
    'La contraseña no cumple los requisitos de seguridad.',
  );
  String get required => _l('Requis', 'Required', 'Obligatorio');
  List<String> get countryList => _fr
      ? [
          'France',
          'Belgique',
          'Canada',
          'Suisse',
          'Royaume-Uni',
          'États-Unis',
          'Autre',
        ]
      : _es
      ? [
          'Francia',
          'Bélgica',
          'Canadá',
          'Suiza',
          'Reino Unido',
          'Estados Unidos',
          'Otro',
        ]
      : [
          'France',
          'Belgium',
          'Canada',
          'Switzerland',
          'United Kingdom',
          'United States',
          'Other',
        ];

  String get acceptCgu => _l(
    "J'accepte les Conditions Générales d'Utilisation (CGU)",
    'I accept the Terms of Use (CGU)',
    'Acepto las Condiciones Generales de Uso (CGU)',
  );
  String get acceptCgs => _l(
    "J'accepte les Conditions Générales de Service (CGS)",
    'I accept the Terms of Service (CGS)',
    'Acepto las Condiciones Generales de Servicio (CGS)',
  );
  String get pleaseAcceptCguCgs => _l(
    'Veuillez accepter les CGU et CGS pour continuer.',
    'Please accept CGU and CGS to continue.',
    'Acepta las CGU y las CGS para continuar.',
  );
  String get legalStructure => _l(
    'Structure legale',
    'Legal structure',
    'Forma jurídica',
  );
  String get legalIndividual => _l('Individuel', 'Individual', 'Autónomo');
  String get legalCompany => _l('Societe', 'Company', 'Sociedad');
  String get legalAssociation => _l('Association', 'Association', 'Asociación');
  String get acceptCharter => _l(
    "J'accepte la charte professionnelle",
    'I accept the professional charter',
    'Acepto la carta profesional',
  );
  String get pleaseAcceptCharter => _l(
    'Veuillez accepter la charte professionnelle pour continuer.',
    'Please accept the professional charter to continue.',
    'Acepta la carta profesional para continuar.',
  );
  String get invalidLegalStructure => _l(
    'Structure legale invalide.',
    'Invalid legal structure.',
    'Forma jurídica no válida.',
  );
  String get siretNumber => _l(
    'Numéro d\'immatriculation (SIRET / RNE)',
    'Registration number (SIRET / RNE)',
    'Número de registro (SIRET / RNE)',
  );
  String get invalidSiret => _l(
    'Un numéro d\'immatriculation valide est obligatoire.',
    'A valid registration number is required.',
    'Es obligatorio un número de registro válido.',
  );
  String get companyName => _l(
    'Nom de la société',
    'Company name',
    'Nombre de la empresa',
  );
  String get societyRequired => _l(
    'Le nom de la société est obligatoire pour une société.',
    'A company name is required for a company.',
    'El nombre de la empresa es obligatorio para una sociedad.',
  );
  String get emailAlreadyRegistered => _l(
    'Cette adresse e-mail est deja inscrite.',
    'This email is already registered.',
    'Este correo electrónico ya está registrado.',
  );
  String get phoneAlreadyRegistered => _l(
    'Ce numero de telephone est deja inscrit.',
    'This phone number is already registered.',
    'Este número de teléfono ya está registrado.',
  );
  String get signupRecaptchaRequired => _l(
    'La verification anti-spam est requise pour creer ce compte.',
    'Anti-spam verification is required to create this account.',
    'Se requiere la verificación antispam para crear esta cuenta.',
  );
  String get accountCreated => _l(
    'Compte cree ! Bienvenue.',
    'Account created! Welcome.',
    '¡Cuenta creada! Te damos la bienvenida.',
  );
  String createAccountFailed(String err) => _l(
    'Échec de la création du compte : $err',
    'Failed to create account: $err',
    'No se pudo crear la cuenta: $err',
  );
  String loginFailed(String err) => _l(
    'Échec de la connexion : $err',
    'Login failed: $err',
    'Error al iniciar sesión: $err',
  );
  String get invalidLoginCredentials => _l(
    'E-mail ou mot de passe incorrect.',
    'Incorrect email or password.',
    'Correo electrónico o contraseña incorrectos.',
  );
  String get alreadyHaveAccount => _l(
    'Vous avez déjà un compte ? ',
    'Already have an account? ',
    '¿Ya tienes una cuenta? ',
  );

  // ── Bottom nav tabs ─────────────────────────────────────────────────────────
  String get tabExplore => _l('Explorer', 'Explore', 'Explorar');
  String get tabChat => _l('Chat', 'Chat', 'Chat');
  String get tabHistory => _l('Historique', 'History', 'Historial');
  String get tabReviews => _l('Avis', 'Reviews', 'Reseñas');
  String get tabProfile => _l('Profil', 'Profile', 'Perfil');
  String get tabHome => _l('Accueil', 'Home', 'Inicio');
  String get tabSlots => _l('Créneaux', 'Slots', 'Horarios');
  String get tabClients => _l('Avis', 'Reviews', 'Reseñas');

  // ── Professional dashboard ──────────────────────────────────────────────────
  String get dashboard => _l(
    'Tableau de bord',
    'Dashboard',
    'Panel de control',
  );
  String welcomeBackName(String name) => _l(
    'Bienvenue, $name',
    'Welcome back, $name',
    'Bienvenido de nuevo, $name',
  );
  String get yourProDashboard => _l(
    'Votre tableau de bord professionnel',
    'Your professional dashboard',
    'Tu panel profesional',
  );
  String get totalSessions => _l(
    'Sessions totales',
    'Total Sessions',
    'Sesiones totales',
  );
  String get avgRating => _l('Note moyenne', 'Avg Rating', 'Valoración media');
  String get upcomingSessions => _l(
    'Sessions à venir',
    'Upcoming Sessions',
    'Próximas sesiones',
  );
  String get recentSessions => _l(
    'Sessions récentes',
    'Recent Sessions',
    'Sesiones recientes',
  );
  String get noSessionsYet => _l(
    'Pas encore de sessions',
    'No sessions yet',
    'Aún no hay sesiones',
  );
  String get failedLoadSessions => _l(
    'Impossible de charger les sessions',
    'Failed to load sessions',
    'No se pudieron cargar las sesiones',
  );

  // ── Profile screen ──────────────────────────────────────────────────────────
  String get guestUser => _l(
    'Utilisateur invité',
    'Guest User',
    'Usuario invitado',
  );
  String welcomeUser(String name) => _l(
    'Bienvenue $name',
    'Welcome $name',
    'Bienvenido/a $name',
  );
  String get settings => _l('Paramètres', 'Settings', 'Ajustes');
  String get editProfile => _l(
    'Modifier le profil',
    'Edit Profile',
    'Editar perfil',
  );
  String get updateInfo => _l(
    'Mettre à jour vos informations',
    'Update your information',
    'Actualiza tus datos',
  );
  String get editProfileComingSoon => _l(
    'Modification du profil bientôt disponible',
    'Edit Profile Coming Soon',
    'Edición de perfil disponible próximamente',
  );
  String get descriptionOptional => _l(
    'Description (optionnel)',
    'Description (optional)',
    'Descripción (opcional)',
  );
  String get saveChanges => _l(
    'Enregistrer les modifications',
    'Save Changes',
    'Guardar cambios',
  );
  String get profileUpdated => _l(
    'Profil mis à jour avec succès',
    'Profile updated successfully',
    'Perfil actualizado correctamente',
  );
  String profileUpdateFailed(String err) => _l(
    'Échec de la mise à jour du profil : $err',
    'Failed to update profile: $err',
    'No se pudo actualizar el perfil: $err',
  );
  String get paymentMethods => _l(
    'Moyens de paiement',
    'Payment Methods',
    'Métodos de pago',
  );
  String get cardsBilling => _l(
    'Cartes et facturation',
    'Cards and billing',
    'Tarjetas y facturación',
  );
  String get support => _l('Assistance', 'Support', 'Asistencia');
  String get helpCenter => _l(
    "Centre d'aide",
    'Help Center',
    'Centro de ayuda',
  );
  String get faqsGuides => _l(
    'FAQ et guides',
    'FAQs and guides',
    'Preguntas frecuentes y guías',
  );
  String get termsOfUse => _l(
    'Conditions d\'utilisation (CGU)',
    'Terms of Use (CGU)',
    'Condiciones de uso (CGU)',
  );
  String get termsOfService => _l(
    'Conditions de service (CGS)',
    'Terms of Service (CGS)',
    'Condiciones del servicio (CGS)',
  );
  String get legalNotice => _l(
    'Mentions légales',
    'Legal Notice',
    'Aviso legal',
  );
  String get legalNoticeSubtitle => _l(
    'Informations légales et éditeur du service',
    'Legal and publisher information',
    'Información legal y del editor del servicio',
  );
  String get contactSupport => _l(
    'Contacter le support',
    'Contact Support',
    'Contactar con soporte',
  );
  String get contactSupportSubtitle => _l(
    'Assistance par e-mail ou formulaire',
    'Help via email or contact form',
    'Ayuda por correo o formulario de contacto',
  );
  String get trustQuality => _l(
    'Confiance & qualité',
    'Trust & Quality',
    'Confianza y calidad',
  );
  String get trustQualitySubtitle => _l(
    'Professionnels vérifiés et avis',
    'Verified professionals and reviews',
    'Profesionales verificados y reseñas',
  );
  String get sessionsLabel => _l('Sessions', 'Sessions', 'Sesiones');
  String get totalTime => _l('Temps total', 'Total Time', 'Tiempo total');
  String get rating => _l('Note', 'Rating', 'Valoración');
  String get logout => _l('Se déconnecter', 'Log Out', 'Cerrar sesión');
  String get logoutConfirmTitle => _l(
    'Se déconnecter ?',
    'Log out?',
    '¿Cerrar sesión?',
  );
  String get logoutConfirmMessage => _l(
    'Êtes-vous sûr de vouloir vous déconnecter ?',
    'Are you sure you want to log out?',
    '¿Seguro que quieres cerrar sesión?',
  );

  // ── Explore / Professionals list ────────────────────────────────────────────
  String get explore => _l('Explorer', 'Explore', 'Explorar');
  String get unableLoadExplore => _l(
    'Impossible de charger les données',
    'Unable to load explore data',
    'No se pudieron cargar los datos',
  );
  String get tryAgain => _l('Réessayer', 'Try Again', 'Reintentar');
  String get noProfessionalsFound => _l(
    'Aucun voyant trouvé',
    'No psychics found',
    'No se encontraron profesionales',
  );
  String get noProfessionalsSubtitle => _l(
    'Les voyants apparaîtront ici une fois disponibles.',
    'Psychics will appear here once available.',
    'Los profesionales aparecerán aquí cuando estén disponibles.',
  );
  String get searchAdvisor => _l(
    'Rechercher des professionnels par nom ou spécialités',
    'Search for professionals by name or specialties',
    'Buscar profesionales por nombre o especialidades',
  );
  String get search => _l('Rechercher', 'Search', 'Buscar');
  String get all => _l('Tous', 'All', 'Todos');
  String get online => _l('En ligne', 'Online', 'En línea');
  String get offline => _l('Hors ligne', 'Offline', 'Desconectado');
  String get recommended => _l('Recommandé', 'Recommended', 'Recomendado');
  String get filters => _l('Filtres', 'Filters', 'Filtros');
  String get reset => _l('Réinitialiser', 'Reset', 'Restablecer');
  String get specialty => _l('Spécialité', 'Specialty', 'Especialidad');
  String get type => _l('Type', 'Type', 'Tipo');
  String get experience => _l('Expérience', 'Experience', 'Experiencia');
  String get price => _l('Prix', 'Price', 'Precio');
  String get language => _l('Langue', 'Language', 'Idioma');
  String get sessionType => _l(
    'Type de session',
    'Session type',
    'Tipo de sesión',
  );
  String get favoritesOnly => _l(
    'Favoris seulement',
    'Favorites only',
    'Solo favoritos',
  );
  String get favoritePsychicsSubtitle => _l(
    'Retrouvez vos voyants favoris',
    'View your favorite psychics',
    'Consulta tus profesionales favoritos',
  );
  String get phone => _l('Téléphone', 'Phone', 'Teléfono');
  String get video => _l('Vidéo', 'Video', 'Vídeo');
  String get moreFilters => _l(
    'Plus de filtres',
    'More Filters',
    'Más filtros',
  );
  String get filterSubtitle => _l(
    'Spécialité, expérience, prix, type de session, langue',
    'Specialty, experience, price, session type, language',
    'Especialidad, experiencia, precio, tipo de sesión, idioma',
  );
  String get specialties => _l('Spécialités', 'Specialties', 'Especialidades');
  String get categories => _l('Catégories', 'Categories', 'Categorías');
  String get pricingEurMin => _l(
    'Prix (EUR/min)',
    'Price (EUR/min)',
    'Precio (EUR/min)',
  );
  String get featuredAdvisors => _l(
    'Nos voyants recommandés',
    'Our recommended psychics',
    'Nuestros profesionales recomendados',
  );
  String get topProsReadyNow => _l(
    'Les meilleurs professionnels en ligne disponibles',
    'Top online professionals ready now',
    'Los mejores profesionales en línea disponibles',
  );
  String get noFeaturedAdvisors => _l(
    'Aucun voyant recommandé pour les filtres actuels.',
    'No recommended psychics for the current filters.',
    'No hay profesionales recomendados para los filtros actuales.',
  );
  String get onlineNow =>
      _l('En ligne maintenant', 'Online now', 'En línea ahora');
  String get allAdvisors =>
      _l('Tous les voyants', 'All psychics', 'Todos los profesionales');
  String nResults(int n) => _l('$n résultats', '$n results', '$n resultados');
  String get noAdvisorsMatch => _l(
    'Aucun voyant ne correspond à votre recherche.',
    'No psychics match your search right now.',
    'Ningún profesional coincide con tu búsqueda.',
  );
  String get clearFiltersAndRetry => _l(
    'Effacer les filtres et réessayer',
    'Clear filters and retry',
    'Borrar filtros y reintentar',
  );
  String get quickSessionTest => _l(
    'Test rapide de session',
    'Quick session test',
    'Prueba rápida de sesión',
  );
  String get quickSessionTestHint => _l(
    'Ouvre directement un profil compatible pour tester le module de session.',
    'Opens a compatible profile directly to test the session module.',
    'Abre directamente un perfil compatible para probar el módulo de sesión.',
  );
  String get noVideoTestCandidate => _l(
    'Aucun professionnel disponible pour un test vidéo.',
    'No professional available for video test.',
    'No hay ningún profesional disponible para la prueba de vídeo.',
  );
  String get noPhoneTestCandidate => _l(
    'Aucun professionnel disponible pour un test téléphone.',
    'No professional available for phone test.',
    'No hay ningún profesional disponible para la prueba de teléfono.',
  );
  String get noChatTestCandidate => _l(
    'Aucun professionnel disponible pour un test chat.',
    'No professional available for chat test.',
    'No hay ningún profesional disponible para la prueba de chat.',
  );
  String get discoverYourGuide =>
      _l('Découvrez votre guide', 'Discover Your Guide', 'Descubre tu guía');
  String nAdvisorsAvailable(int n) => _l(
    '$n voyants disponibles pour chat et vidéo',
    '$n psychics available for chat and video sessions',
    '$n profesionales disponibles para chat y vídeo',
  );
  String specialtyFilterLabel(String s) => _l(
    'Spécialité : $s',
    'Specialty: $s',
    'Especialidad: $s',
  );
  String get results => _l('résultats', 'results', 'resultados');

  // ── Professional detail ─────────────────────────────────────────────────────
  String get startSession => _l(
    'Démarrer une session',
    'Start Session',
    'Iniciar sesión de consulta',
  );
  String get chooseSessionType => _l(
    'Choisir le type de session :',
    'Choose session type:',
    'Elige el tipo de sesión:',
  );
  String get phoneCall => _l(
    'Appel téléphonique',
    'Phone Call',
    'Llamada telefónica',
  );
  String get videoCall => _l('Appel vidéo', 'Video Call', 'Videollamada');
  String get textChat => _l('Chat textuel', 'Text Chat', 'Chat de texto');
  String get available24Hours => _l(
    'Disponible 24H/24',
    'Available 24/7',
    'Disponible 24/7',
  );
  String get free => _l('Gratuit', 'Free', 'Gratis');
  String get cancel => _l('Annuler', 'Cancel', 'Cancelar');
  String get addedFavorites => _l(
    'Ajouté aux favoris ❤️',
    'Added to favorites ❤️',
    'Añadido a favoritos ❤️',
  );
  String get removedFavorites => _l(
    'Retiré des favoris',
    'Removed from favorites',
    'Eliminado de favoritos',
  );
  // Screen-reader labels for the heart button on a professional card.
  String get addToFavorites => _l(
    'Ajouter aux favoris',
    'Add to favorites',
    'Añadir a favoritos',
  );
  String get removeFromFavorites => _l(
    'Retirer des favoris',
    'Remove from favorites',
    'Quitar de favoritos',
  );
  String get couldNotUpdateFavorite => _l(
    'Impossible de mettre à jour les favoris. Réessayez.',
    'Could not update favorite. Please try again.',
    'No se pudo actualizar favoritos. Inténtalo de nuevo.',
  );
  String get unableLoadProfile => _l(
    'Impossible de charger le profil',
    'Unable to load profile',
    'No se pudo cargar el perfil',
  );
  String startingSession(String type, String name) => _l(
    'Démarrage session $type avec $name...',
    'Starting $type session with $name...',
    'Iniciando sesión de $type con $name...',
  );
  String sessionCreated(String seId, String type) => _l(
    'Session #$seId créée (${type.toUpperCase()})',
    'Session #$seId created (${type.toUpperCase()})',
    'Sesión n.º $seId creada (${type.toUpperCase()})',
  );
  String get availableNow =>
      _l('Disponible maintenant', 'Available now', 'Disponible ahora');
  String get viewAvailability =>
      _l('Voir les disponibilités', 'View availability', 'Ver disponibilidad');
  String get profileVerified =>
      _l('Profil vérifié', 'Profile verified', 'Perfil verificado');
  String get emailVerified =>
      _l('E-mail vérifié', 'Email verified', 'Correo verificado');
  String get call => _l('Appel', 'Call', 'Llamada');
  String get noAvailabilityAtMoment => _l(
    'Aucune disponibilité pour le moment',
    'No availability at the moment',
    'Sin disponibilidad por el momento',
  );
  String get bookSession => _l(
    'Réserver une session',
    'Book Session',
    'Reservar sesión',
  );
  String get availableServices => _l(
    'Services disponibles',
    'Available Services',
    'Servicios disponibles',
  );
  String get about => _l('À propos', 'About', 'Acerca de');
  String get expertise => _l('Expertise', 'Expertise', 'Especialización');
  String get languages => _l('Langues', 'Languages', 'Idiomas');
  String get pricePerMinute => _l(
    'Prix par minute',
    'Price per minute',
    'Precio por minuto',
  );
  String get startSessionNow => _l(
    'Démarrer la session',
    'Start Session Now',
    'Iniciar sesión ahora',
  );
  String errorMessage(String err) => _l(
    'Erreur : $err',
    'Error: $err',
    'Error: $err',
  );
  String get verifiedProfile => _l(
    'PROFIL VÉRIFIÉ',
    'VERIFIED PROFILE',
    'PERFIL VERIFICADO',
  );

  // ── Availability / Slots ────────────────────────────────────────────────────
  String get manageSlots => _l(
    'Gérer les créneaux',
    'Manage Slots',
    'Gestionar horarios',
  );
  String get addSlot => _l('Ajouter un créneau', 'Add Slot', 'Añadir horario');
  String get addAvailabilitySlot => _l(
    'Ajouter un créneau de disponibilité',
    'Add Availability Slot',
    'Añadir horario de disponibilidad',
  );
  String get day => _l('Jour', 'Day', 'Día');
  String get startTime => _l(
    'Heure de début (HH:mm)',
    'Start Time (HH:mm)',
    'Hora de inicio (HH:mm)',
  );
  String get endTime => _l(
    'Heure de fin (HH:mm)',
    'End Time (HH:mm)',
    'Hora de fin (HH:mm)',
  );
  String get save => _l('Enregistrer', 'Save', 'Guardar');
  String get startTimeHint => _l('09:00', '09:00', '09:00');
  String get endTimeHint => _l('10:00', '10:00', '10:00');
  String get startTimeRequired => _l(
    "L'heure de début est requise",
    'Start time is required',
    'La hora de inicio es obligatoria',
  );
  String get use24hFormat => _l(
    'Utiliser le format 24h, ex. 09:00',
    'Use 24h format, e.g. 09:00',
    'Usa el formato de 24 h, p. ej. 09:00',
  );
  String get slotAddedSuccess => _l(
    'Créneau de disponibilité ajouté avec succès',
    'Availability slot added successfully',
    'Horario de disponibilidad añadido correctamente',
  );
  String get slotUpdatedSuccess => _l(
    'Créneau de disponibilité mis à jour avec succès',
    'Availability slot updated successfully',
    'Horario de disponibilidad actualizado correctamente',
  );
  String get slotDeletedSuccess => _l(
    'Créneau de disponibilité supprimé avec succès',
    'Availability slot deleted successfully',
    'Horario de disponibilidad eliminado correctamente',
  );
  String failedAddSlot(String err) => _l(
    "Échec de l'ajout du créneau : $err",
    'Failed to add slot: $err',
    'No se pudo añadir el horario: $err',
  );
  String failedUpdateSlot(String err) => _l(
    "Échec de la mise à jour du créneau : $err",
    'Failed to update slot: $err',
    'No se pudo actualizar el horario: $err',
  );
  String failedDeleteSlot(String err) => _l(
    "Échec de la suppression du créneau : $err",
    'Failed to delete slot: $err',
    'No se pudo eliminar el horario: $err',
  );
  String get editSlot => _l(
    'Modifier le créneau',
    'Edit Slot',
    'Editar horario',
  );
  String get deleteSlot => _l(
    'Supprimer le créneau',
    'Delete Slot',
    'Eliminar horario',
  );
  String get deleteSlotConfirm => _l(
    'Voulez-vous vraiment supprimer ce créneau de disponibilité ?',
    'Are you sure you want to delete this availability slot?',
    '¿Seguro que quieres eliminar este horario de disponibilidad?',
  );
  String get edit => _l('Modifier', 'Edit', 'Editar');
  String get delete => _l('Supprimer', 'Delete', 'Eliminar');
  String get failedLoadAvailability => _l(
    'Impossible de charger les disponibilités',
    'Failed to load availability',
    'No se pudo cargar la disponibilidad',
  );
  String get retry => _l('Réessayer', 'Retry', 'Reintentar');
  String get noSlotsYet => _l(
    'Aucun créneau ajouté',
    'No slots added yet',
    'Aún no has añadido horarios',
  );
  String get tapAddSlot => _l(
    'Appuyez sur "Ajouter un créneau" pour définir vos disponibilités.',
    'Tap "Add Slot" to set your availability.',
    'Pulsa "Añadir horario" para definir tu disponibilidad.',
  );
  String get refresh => _l('Actualiser', 'Refresh', 'Actualizar');
  String get weeklySlots => _l(
    'Créneaux hebdomadaires',
    'Weekly Slots',
    'Horarios semanales',
  );
  String get yourAvailability => _l(
    'Votre disponibilité',
    'Your Availability',
    'Tu disponibilidad',
  );
  String get availabilitySubtitle => _l(
    'Définissez les heures pendant lesquelles vos clients peuvent vous joindre.',
    'Set the hours when your clients can reach you.',
    'Define las horas en las que tus clientes pueden contactarte.',
  );
  String get daysCount => _l('jours', 'days', 'días');
  String get slotsCount => _l('créneaux', 'slots', 'horarios');
  String get managed => _l('gérés', 'managed', 'gestionados');
  String slotsCountFor(int count) => _l(
    '$count créneau${count > 1 ? 'x' : ''}',
    '$count slot${count > 1 ? 's' : ''}',
    '$count horario${count > 1 ? 's' : ''}',
  );

  // Days of week
  String get monday => _l('Lundi', 'Monday', 'Lunes');
  String get tuesday => _l('Mardi', 'Tuesday', 'Martes');
  String get wednesday => _l('Mercredi', 'Wednesday', 'Miércoles');
  String get thursday => _l('Jeudi', 'Thursday', 'Jueves');
  String get friday => _l('Vendredi', 'Friday', 'Viernes');
  String get saturday => _l('Samedi', 'Saturday', 'Sábado');
  String get sunday => _l('Dimanche', 'Sunday', 'Domingo');
  List<String> get days => [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  // ── Reviews ─────────────────────────────────────────────────────────────────
  String get reviews => _l('Avis', 'Reviews', 'Reseñas');
  String get myReviews => _l('Mes avis', 'My Reviews', 'Mis reseñas');
  String get failedLoadReviews => _l(
    'Impossible de charger les avis',
    'Failed to load reviews',
    'No se pudieron cargar las reseñas',
  );
  String get noReviewsFound =>
      _l('Aucun avis trouvé', 'No reviews found', 'No se encontraron reseñas');
  String get noReviewsYet =>
      _l('Aucun avis pour le moment', 'No reviews yet', 'Aún no hay reseñas');
  String get beFirstToReview => _l(
    'Soyez le premier à laisser un avis !',
    'Be the first to leave a review!',
    '¡Sé el primero en dejar una reseña!',
  );
  String get writeReview =>
      _l('Écrire un avis', 'Write a review', 'Escribir una reseña');
  String get submitReview =>
      _l('Soumettre un avis', 'Submit review', 'Enviar reseña');
  String get yourRating => _l('Votre note', 'Your rating', 'Tu puntuación');
  String get yourComment =>
      _l('Votre commentaire', 'Your comment', 'Tu comentario');
  String starCount(int count) => _l(
    '$count étoile${count == 1 ? '' : 's'}',
    '$count star${count == 1 ? '' : 's'}',
    '$count estrella${count == 1 ? '' : 's'}',
  );
  String get reviewTargetCoidHint => _l(
    'ID du professionnel (optionnel)',
    'Professional ID (optional)',
    'ID del profesional (opcional)',
  );
  String get reviewSessionIdHint => _l(
    'ID de session (optionnel)',
    'Session ID (optional)',
    'ID de sesión (opcional)',
  );
  String get reviewProfessionalLabel =>
      _l('Professionnel', 'Professional', 'Profesional');
  String get reviewSessionLabel => _l('Session', 'Session', 'Sesión');
  String get selectProfessional => _l(
    'Choisir un professionnel',
    'Select a professional',
    'Seleccionar un profesional',
  );
  String get selectSession =>
      _l('Choisir une session', 'Select a session', 'Seleccionar una sesión');
  String get noProfessionalsAvailable => _l(
    'Aucun professionnel disponible',
    'No professionals available',
    'No hay profesionales disponibles',
  );
  String get noSessionsForProfessional => _l(
    'Aucune session pour ce professionnel',
    'No sessions for this professional',
    'No hay sesiones con este profesional',
  );
  String get ratingRequired => _l(
    'La note est requise',
    'Rating is required',
    'La puntuación es obligatoria',
  );
  String get reviewSubmitted => _l(
    'Avis soumis avec succès',
    'Review submitted successfully',
    'Reseña enviada correctamente',
  );
  String reviewSubmitFailed(String err) => _l(
    'Échec de l\'envoi de l\'avis : $err',
    'Failed to submit review: $err',
    'No se pudo enviar la reseña: $err',
  );
  String nReviews(int count) =>
      _l('$count avis', '$count reviews', '$count reseñas');
  String get reviewsFromClientsWillAppear => _l(
    'Les avis de vos clients\napparaîtront ici',
    'Reviews from your clients\nwill appear here',
    'Las reseñas de tus clientes\naparecerán aquí',
  );
  String get reviewsFromConsultationsWillAppear => _l(
    'Les avis de vos consultations\napparaîtront ici',
    'Reviews from your consultations\nwill appear here',
    'Las reseñas de tus consultas\naparecerán aquí',
  );
  String get anonymous => _l('Anonyme', 'Anonymous', 'Anónimo');

  // ── History ──────────────────────────────────────────────────────────────────
  String get sessionHistory =>
      _l('Historique des sessions', 'Session History', 'Historial de sesiones');
  String get pastConsultations => _l(
    'Vos consultations passées',
    'Your past consultations',
    'Tus consultas anteriores',
  );
  String get failedLoadHistory => _l(
    "Impossible de charger l'historique",
    'Failed to load history',
    'No se pudo cargar el historial',
  );
  String get noSessionsFound => _l(
    'Aucune session trouvée',
    'No sessions found',
    'No se encontraron sesiones',
  );
  String get completed => _l('Terminé', 'Completed', 'Completada');
  String get cancelled => _l('Annulé', 'Cancelled', 'Cancelada');
  String get pending => _l('En attente', 'Pending', 'Pendiente');
  String get noSessionsHistory => _l(
    'Aucune session dans l\'historique',
    'No sessions in history',
    'No hay sesiones en el historial',
  );
  String get noHistoryYet => _l(
    'Vos sessions passées apparaîtront ici.',
    'Your past sessions will appear here.',
    'Tus sesiones anteriores aparecerán aquí.',
  );
  String get noSessionsYetTitle => _l(
    'Aucune session pour le moment',
    'No Sessions Yet',
    'Aún no hay sesiones',
  );
  String get consultationHistoryWillAppear => _l(
    'Votre historique de consultation\napparaîtra ici',
    'Your consultation history will\nappear here',
    'Tu historial de consultas\naparecerá aquí',
  );

  // ── Chat ─────────────────────────────────────────────────────────────────────
  String get messages => _l('Messages', 'Messages', 'Mensajes');
  String get searchConversations => _l(
    'Rechercher des conversations...',
    'Search conversations...',
    'Buscar conversaciones...',
  );
  String get failedLoadConversations => _l(
    'Impossible de charger les conversations',
    'Failed to load conversations',
    'No se pudieron cargar las conversaciones',
  );
  String get noConversationsFound => _l(
    'Aucune conversation trouvée',
    'No conversations found',
    'No se encontraron conversaciones',
  );
  String get noConversationsYet => _l(
    'Aucune conversation pour le moment',
    'No conversations yet',
    'Aún no hay conversaciones',
  );
  String get startChatExplore => _l(
    'Commencez une session avec un professionnel pour discuter.',
    'Start a session with a professional to chat.',
    'Inicia una sesión con un profesional para poder chatear.',
  );
  String get typeMessage =>
      _l('Écrire un message...', 'Type a message...', 'Escribe un mensaje...');
  String get send => _l('Envoyer', 'Send', 'Enviar');
  String sendMessageFailed(String err) => _l(
    'Échec de l\'envoi du message : $err',
    'Failed to send message: $err',
    'No se pudo enviar el mensaje: $err',
  );
  String get conversation => _l('Conversation', 'Conversation', 'Conversación');
  String get activeNow => _l('Actif maintenant', 'Active now', 'Activo ahora');
  String get failedLoadMessages => _l(
    'Impossible de charger les messages',
    'Failed to load messages',
    'No se pudieron cargar los mensajes',
  );
  String get noMessagesYet => _l(
    'Aucun message pour le moment',
    'No messages yet',
    'Aún no hay mensajes',
  );
  String get startConversation => _l(
    'Commencez la conversation !',
    'Start the conversation!',
    '¡Empieza la conversación!',
  );
  String get unknown => _l('Inconnu', 'Unknown', 'Desconocido');
  String get session => _l('Session', 'Session', 'Sesión');

  // ── Pricing ──────────────────────────────────────────────────────────────────
  String get sessionPricing => _l(
    'Tarifs des sessions',
    'Session Pricing',
    'Tarifas de las sesiones',
  );
  String get pricing => _l('Tarifs', 'Pricing', 'Tarifas');
  String get noPricingInfo => _l(
    'Aucune information tarifaire',
    'No pricing information',
    'Sin información de tarifas',
  );
  String get noPricingAvailable => _l(
    'Aucune information tarifaire disponible',
    'No pricing information available',
    'No hay información de tarifas disponible',
  );
  String get consultation => _l('Consultation', 'Consultation', 'Consulta');
  String get credit => _l('Crédit', 'Credit', 'Crédito');
  String get promoCode => _l('Code promo', 'Promo code', 'Código promocional');
  String get applyPromo => _l('Appliquer', 'Apply', 'Aplicar');
  String promoApplied(String code, String discount) => _l(
    'Code $code appliqué : $discount%',
    'Code $code applied: $discount%',
    'Código $code aplicado: $discount%',
  );
  String get promoInvalid => _l(
    'Code promo invalide',
    'Invalid promo code',
    'Código promocional no válido',
  );
  String promoCheckFailed(String err) => _l(
    'Échec de la vérification du code promo : $err',
    'Failed to check promo code: $err',
    'No se pudo verificar el código promocional: $err',
  );
  String get registerAppointment => _l(
    'S\'inscrire à un créneau',
    'Register for appointment',
    'Inscribirse en una cita',
  );
  String get appointmentId => _l(
    'ID de créneau',
    'Appointment ID',
    'ID de cita',
  );
  String get appointmentRegistered => _l(
    'Inscription au créneau réussie',
    'Appointment registration successful',
    'Inscripción en la cita realizada correctamente',
  );
  String appointmentRegistrationFailed(String err) => _l(
    'Échec de l\'inscription au créneau : $err',
    'Appointment registration failed: $err',
    'Error al inscribirse en la cita: $err',
  );
  String get selectAppointment => _l(
    'Sélectionner un créneau',
    'Select appointment',
    'Seleccionar una cita',
  );
  String get searchAppointments => _l(
    'Rechercher un créneau...',
    'Search appointments...',
    'Buscar citas...',
  );
  String get noAppointmentCandidates => _l(
    'Aucun créneau disponible pour inscription.',
    'No appointment slots available to register.',
    'No hay citas disponibles para inscribirse.',
  );
  String get loadingAppointments => _l(
    'Chargement des créneaux...',
    'Loading appointments...',
    'Cargando citas...',
  );
  String get myAppointments =>
      _l('Mes rendez-vous', 'My appointments', 'Mis citas');
  String get upcoming => _l('À venir', 'Upcoming', 'Próximas');
  String get past => _l('Passés', 'Past', 'Anteriores');
  String get noUpcomingAppointments => _l(
    'Aucun rendez-vous à venir.',
    'No upcoming appointments.',
    'No hay citas próximas.',
  );
  String get noPastAppointments => _l(
    'Aucun rendez-vous passé.',
    'No past appointments.',
    'No hay citas anteriores.',
  );
  String get manageAppointmentsSubtitle => _l(
    'Consultez vos rendez-vous à venir et passés',
    'View your upcoming and past appointments',
    'Consulta tus citas próximas y anteriores',
  );
  String get groupCalendar => _l(
    'Calendrier des sessions de groupe',
    'Group-session calendar',
    'Calendario de sesiones grupales',
  );
  String get groupCalendarSubtitle => _l(
    'Découvrez et rejoignez les sessions Club Voyanz',
    'Discover and join Club Voyanz sessions',
    'Descubre y únete a las sesiones Club Voyanz',
  );
  String get groupSession =>
      _l('Session de groupe', 'Group session', 'Sesión grupal');
  String get noGroupSessions => _l(
    'Aucune session de groupe dans les 30 prochains jours.',
    'No group sessions in the next 30 days.',
    'No hay sesiones grupales en los próximos 30 días.',
  );
  String get phoneSession => _l(
    'Session téléphonique',
    'Phone Session',
    'Sesión telefónica',
  );
  String get answerPhoneTitle => _l(
    'Repondez a votre telephone',
    'Answer your phone',
    'Responde a tu teléfono',
  );
  String get phonePstnSessionMessage => _l(
    'Voyanz appelle les deux participants sur leur numero mobile verifie.',
    'Voyanz is calling both participants on their verified mobile numbers.',
    'Voyanz está llamando a ambos participantes a sus números de móvil verificados.',
  );
  String get phonePstnNoInAppAudio => _l(
    'L\'audio se fait par appel telephonique classique, pas dans l\'app.',
    'Audio happens through a regular phone call, not inside the app.',
    'El audio se realiza mediante una llamada telefónica normal, no dentro de la app.',
  );
  String get phonePstnPressKeyInstruction => _l(
    'Quand vous repondez, appuyez sur la touche 1 pour confirmer que vous etes bien la.',
    'When you answer, press key 1 to confirm you are really there.',
    'Cuando respondas, pulsa la tecla 1 para confirmar que estás al aparato.',
  );
  String phonePstnPressKeyCountdown(int seconds) => _l(
    'Confirmez dans $seconds s, sinon la session sera annulee.',
    'Confirm within $seconds s, or the session will be cancelled.',
    'Confirma en $seconds s o la sesión se cancelará.',
  );
  String get phonePstnCallConfirmed => _l(
    'Appel confirme.',
    'Call confirmed.',
    'Llamada confirmada.',
  );
  String get sessionStatusNoStarConfirmLabel => _l(
    'Appel non confirme',
    'Call not confirmed',
    'Llamada no confirmada',
  );
  String get sessionStatusNoStarConfirmMessage => _l(
    'Le professionnel n\'a pas appuye sur la touche 1 pour confirmer. La session a ete annulee.',
    'The professional did not press key 1 to confirm. The session was cancelled.',
    'El profesional no pulsó la tecla 1 para confirmar. La sesión se ha cancelado.',
  );
  String get phoneEndReasonProfessionalUnavailable => _l(
    'La ligne du professionnel n\'a pas repondu (messagerie).',
    'The professional\'s line was unavailable (voicemail).',
    'La línea del profesional no estaba disponible (buzón de voz).',
  );
  String get phoneEndReasonCustomerNoAnswer => _l(
    'Le client n\'a pas repondu. La session a ete annulee.',
    'The customer did not answer. The session was cancelled.',
    'El cliente no respondió. La sesión se ha cancelado.',
  );
  String get chatSession => _l(
    'Session chat',
    'Chat Session',
    'Sesión de chat',
  );
  String get sessionReady => _l(
    'Session prête',
    'Session ready',
    'Sesión lista',
  );
  String get openConversations => _l(
    'Ouvrir les conversations',
    'Open conversations',
    'Abrir conversaciones',
  );
  String get endSession => _l(
    'Terminer la session',
    'End Session',
    'Finalizar sesión',
  );
  String get endSessionConfirmTitle => _l(
    'Terminer la session ?',
    'End session?',
    '¿Finalizar la sesión?',
  );
  String get endSessionConfirmMessage => _l(
    'Voulez-vous vraiment terminer cette session ?',
    'Do you really want to end this session?',
    '¿Seguro que quieres finalizar esta sesión?',
  );
  String get sessionEnded => _l(
    'Session terminée',
    'Session ended',
    'Sesión finalizada',
  );
  String get sessionStatusCallingLabel => _l(
    'Appel en cours',
    'Calling',
    'Llamando',
  );
  String get sessionStatusAcceptedLabel => _l(
    'Acceptée',
    'Accepted',
    'Aceptada',
  );
  String get sessionStatusPendingLabel => _l(
    'En attente',
    'Pending',
    'Pendiente',
  );
  String get sessionStatusInProgressLabel => _l(
    'En cours',
    'In progress',
    'En curso',
  );
  String get sessionStatusCompletedLabel => _l(
    'Terminée',
    'Completed',
    'Finalizada',
  );
  String get sessionStatusRejectedLabel => _l(
    'Refusée',
    'Rejected',
    'Rechazada',
  );
  String get sessionStatusCanceledLabel => _l(
    'Annulée',
    'Canceled',
    'Cancelada',
  );
  String sessionStatusUnknownLabel(String rawStatus) => rawStatus.isEmpty
      ? _l('Inconnu', 'Unknown', 'Desconocido')
      : rawStatus;
  String sessionStatusCallingMessage({required bool isProfessional}) =>
      isProfessional
      ? _l(
          'Le client est en train d\'être connecté. Veuillez rester sur cet écran.',
          'The customer is being connected. Please stay on this screen.',
          'Se está conectando al cliente. Permanece en esta pantalla.',
        )
      : _l(
          'Le professionnel est en train d\'être connecté. Veuillez rester sur cet écran.',
          'The professional is being connected. Please stay on this screen.',
          'Se está conectando al profesional. Permanece en esta pantalla.',
        );
  String sessionStatusAcceptedMessage({required bool isProfessional}) => _l(
    'La demande a été acceptée. La connexion est en cours.',
    'The request was accepted. The connection is in progress.',
    'La solicitud ha sido aceptada. La conexión está en curso.',
  );
  String sessionStatusPendingMessage({required bool isProfessional}) => _l(
    'La session est en attente de confirmation.',
    'The session is waiting for confirmation.',
    'La sesión está pendiente de confirmación.',
  );
  String sessionStatusInProgressMessage({required bool isProfessional}) =>
      isProfessional
      ? _l(
          'La session est active. Vous êtes en consultation avec votre client.',
          'The session is live. You are connected with your customer.',
          'La sesión está activa. Estás en consulta con tu cliente.',
        )
      : _l(
          'La session est active. Vous êtes en consultation avec votre professionnel.',
          'The session is live. You are connected with your professional.',
          'La sesión está activa. Estás en consulta con tu profesional.',
        );
  String get sessionStatusCompletedMessage => _l(
    'Cette session est terminée.',
    'This session has ended.',
    'Esta sesión ha finalizado.',
  );
  String get sessionStatusRejectedMessage => _l(
    'Cette session a été refusée et ne peut pas être rejointe.',
    'This session was rejected and cannot be joined.',
    'Esta sesión fue rechazada y no se puede unir.',
  );
  String get sessionStatusCanceledMessage => _l(
    'Cette session a été annulée.',
    'This session was canceled.',
    'Esta sesión fue cancelada.',
  );
  String sessionStatusChangedMessage(String rawStatus) => _l(
    'Le statut de la session a changé : ${rawStatus.isEmpty ? 'inconnu' : rawStatus}.',
    'Session status changed: ${rawStatus.isEmpty ? 'unknown' : rawStatus}.',
    'El estado de la sesión ha cambiado: ${rawStatus.isEmpty ? 'desconocido' : rawStatus}.',
  );
  String get unableCheckSessionStatus => _l(
    'Impossible de vérifier le statut de la session',
    'Unable to check session status',
    'No se pudo verificar el estado de la sesión',
  );
  String waitingForJoinTitle({required bool isProfessional}) => isProfessional
      ? _l(
          'En attente du client',
          'Waiting for customer to join',
          'Esperando a que se una el cliente',
        )
      : _l(
          'En attente du professionnel',
          'Waiting for professional to join',
          'Esperando a que se una el profesional',
        );
  String get sessionUnavailable => _l(
    'Session indisponible',
    'Session unavailable',
    'Sesión no disponible',
  );
  String get sessionWaitTimedOutMessage => _l(
    'Cela prend plus de temps que prévu. Vous pouvez réessayer maintenant ou créer une nouvelle demande de session.',
    'This is taking longer than expected. You can retry now or create a new session request.',
    'Está tardando más de lo previsto. Puedes reintentarlo ahora o crear una nueva solicitud de sesión.',
  );
  String get refreshNow => _l(
    'Actualiser maintenant',
    'Refresh now',
    'Actualizar ahora',
  );
  String get rebookSession => _l(
    'Reprogrammer la session',
    'Rebook session',
    'Reprogramar la sesión',
  );
  String get retryStatusCheck => _l(
    'Réessayer le statut',
    'Retry status check',
    'Reintentar comprobación',
  );
  String get backToHome => _l(
    'Retour à l\'accueil',
    'Back to home',
    'Volver al inicio',
  );
  String get sessionAlreadyStarted => _l(
    'La session est déjà lancée. Veuillez patienter.',
    'The session is already started. Please wait.',
    'La sesión ya está iniciada. Espera un momento.',
  );
  String get professionalBusyMessage => _l(
    'Ce professionnel est actuellement en consultation. Veuillez réessayer dans quelques minutes, ou prenez un rendez-vous.',
    'This professional is currently in consultation. Please try again in a few minutes, or book a session.',
    'Este profesional está actualmente en consulta. Inténtalo de nuevo en unos minutos o reserva una cita.',
  );
  String get rebookSessionFailed => _l(
    'Impossible de créer une nouvelle demande de session. Veuillez réessayer.',
    'Could not create a new session request. Please try again.',
    'No se pudo crear una nueva solicitud de sesión. Inténtalo de nuevo.',
  );
  String get connectionError => _l(
    'Erreur de connexion',
    'Connection Error',
    'Error de conexión',
  );
  String get goBack => _l('Retour', 'Go Back', 'Volver');
  String get mute => _l('Muet', 'Mute', 'Silenciar');
  String get camera => _l('Caméra', 'Camera', 'Cámara');
  String get unmute => _l('Activer micro', 'Unmute', 'Activar micrófono');
  String get cameraOff => _l('Couper caméra', 'Camera off', 'Apagar cámara');
  String providerLabel(String provider) => _l(
    'Fournisseur : $provider',
    'Provider: $provider',
    'Proveedor: $provider',
  );
  String get connectingVideo => _l(
    'Connexion vidéo en cours...',
    'Connecting video...',
    'Conectando vídeo...',
  );
  String get waitingRemoteParticipant => _l(
    'En attente de l\'autre participant...',
    'Waiting for the other participant...',
    'Esperando al otro participante...',
  );
  String get reconnectingVideo => _l(
    'Reconnexion en cours...',
    'Reconnecting...',
    'Reconectando...',
  );
  String get localPreview => _l('Vous', 'You', 'Tú');
  String get remoteParticipant => _l(
    'Participant distant',
    'Remote participant',
    'Participante remoto',
  );
  String get videoProviderNotSupported => _l(
    'Le fournisseur vidéo reçu n\'est pas Agora.',
    'The received video provider is not Agora.',
    'El proveedor de vídeo recibido no es Agora.',
  );

  // ── Language selector ────────────────────────────────────────────────────────
  String get selectLanguage =>
      _l('Choisir la langue', 'Select Language', 'Seleccionar idioma');
  String get english => _l('Anglais', 'English', 'Inglés');
  String get french => _l('Français', 'French', 'Francés');
  String get spanish => _l('Espagnol', 'Spanish', 'Español');

  // ── Profile / About dialogs ──────────────────────────────────────────────────
  String get privacyPolicy => _l(
    'Politique de confidentialité',
    'Privacy Policy',
    'Política de privacidad',
  );
  String get readOurTerms => _l(
    'Lisez nos conditions',
    'Read our terms',
    'Lee nuestras condiciones',
  );
  String get aboutVoyanz => _l(
    'À propos de Voyanz',
    'About Voyanz',
    'Acerca de Voyanz',
  );
  String get version100 => _l(
    'Version 1.0.0',
    'Version 1.0.0',
    'Versión 1.0.0',
  );
  String get close => _l('Fermer', 'Close', 'Cerrar');
  String get versionLabel => _l('Version', 'Version', 'Versión');
  String get helpCenterContent => _l(
    'Les questions fréquentes et les guides seront bientôt disponibles. Pour une assistance immédiate, veuillez contacter notre équipe.',
    'Frequently asked questions and guides will be available soon. For immediate support, please contact our team.',
    'Las preguntas frecuentes y las guías estarán disponibles próximamente. Para asistencia inmediata, ponte en contacto con nuestro equipo.',
  );
  String get privacyPolicyContent => _l(
    'Notre politique de confidentialité détaille comment nous collectons, utilisons et protégeons vos données. La politique complète sera disponible dans la prochaine mise à jour.',
    'Our privacy policy details how we collect, use, and protect your data. Full policy will be available in the next update.',
    'Nuestra política de privacidad detalla cómo recopilamos, usamos y protegemos tus datos. La política completa estará disponible en la próxima actualización.',
  );
  String get aboutVoyanzContent => _l(
    'Voyanz - Votre plateforme de confiance pour les consultations professionnelles.\n\nVersion : 1.0.0\nConçu avec Flutter & ❤️',
    'Voyanz - Your trusted platform for professional consultations.\n\nVersion: 1.0.0\nBuilt with Flutter & ❤️',
    'Voyanz: tu plataforma de confianza para consultas profesionales.\n\nVersión: 1.0.0\nCreado con Flutter y ❤️',
  );
  String get contactUs => _l('Contactez-nous', 'Contact us', 'Contáctanos');
  String get liveChat => _l('Chat en direct', 'Live chat', 'Chat en directo');
  String get openFullPolicy => _l(
    'Ouvrir la politique complète en ligne',
    'Open the full policy online',
    'Abrir la política completa en línea',
  );
  String get supportChannels => _l(
    'Canaux de contact',
    'Contact channels',
    'Canales de contacto',
  );

  // ── Wallet / Top-Up ──────────────────────────────────────────────────────
  String get wallet => _l('Portefeuille', 'Wallet', 'Monedero');
  String get topUp => _l('Recharger', 'Top Up', 'Recargar');
  String get selectPackHint => _l(
    'Choisissez la meilleure offre pour vos prochaines consultations.',
    'Choose the best value for your future consultations.',
    'Elige la mejor oferta para tus próximas consultas.',
  );
  String get topUpCredit =>
      _l('Recharger mon solde', 'Top Up Balance', 'Recargar saldo');
  String get buyPack => _l('Acheter', 'Buy', 'Comprar');
  String get selectPack =>
      _l('Choisir un pack', 'Select a pack', 'Seleccionar un paquete');
  // First-purchase offer card on Explore. The French title is the website's
  // own wording ("20 € offerts sur votre premier forfait").
  String firstPackOfferTitle(String amount) => _l(
    '$amount offerts sur votre premier forfait',
    '$amount free on your first pack',
    '$amount de regalo en tu primer paquete',
  );
  String get firstPackOfferSubtitle => _l(
    'Crédit ajouté automatiquement à votre portefeuille lors de votre premier achat.',
    'Added automatically to your wallet with your first purchase.',
    'Se añade automáticamente a tu monedero con tu primera compra.',
  );
  String get firstPackOfferCta =>
      _l('Voir les forfaits', 'See packs', 'Ver paquetes');
  String get creditReceived =>
      _l('Crédit reçu', 'Credit received', 'Crédito recibido');
  String get amountToPay =>
      _l('Montant à payer', 'Amount to pay', 'Importe a pagar');
  String get firstTopUpBonus => _l(
    'Bonus première recharge',
    'First top-up bonus',
    'Bonus de primera recarga',
  );
  String get promoDiscount => _l(
    'Réduction promo',
    'Promo discount',
    'Descuento promocional',
  );
  String get payWithCard =>
      _l('Payer par carte', 'Pay with Card', 'Pagar con tarjeta');
  String get processingPayment => _l(
    'Paiement en cours...',
    'Processing payment...',
    'Procesando el pago...',
  );
  String get paymentSuccess =>
      _l('Paiement réussi', 'Payment Successful', 'Pago realizado');
  String get paymentFailed =>
      _l('Paiement échoué', 'Payment Failed', 'Pago fallido');
  String get insufficientBalance =>
      _l('Solde insuffisant', 'Insufficient Balance', 'Saldo insuficiente');
  String get insufficientBalanceMessage => _l(
    'Votre solde est insuffisant. Rechargez votre portefeuille pour continuer.',
    'Your balance is insufficient. Top up your wallet to continue.',
    'Tu saldo es insuficiente. Recarga tu monedero para continuar.',
  );
  String get topUpNow =>
      _l('Recharger maintenant', 'Top Up Now', 'Recargar ahora');
  String get transactionHistory => _l(
    'Historique des transactions',
    'Transaction History',
    'Historial de transacciones',
  );
  String get noTransactionsYet => _l(
    'Aucune transaction',
    'No transactions yet',
    'Aún no hay transacciones',
  );
  String get transactionHistoryEmptySubtitle => _l(
    'Votre activité apparaîtra ici',
    'Your activity will appear here',
    'Tu actividad aparecerá aquí',
  );
  String get availableBalance =>
      _l('SOLDE DISPONIBLE', 'AVAILABLE BALANCE', 'SALDO DISPONIBLE');
  String get currentBalance =>
      _l('SOLDE ACTUEL', 'CURRENT BALANCE', 'SALDO ACTUAL');
  String get bestValue => _l('MEILLEURE OFFRE', 'BEST VALUE', 'MEJOR OFERTA');
  String get termsAndConditions => _l(
    'Conditions générales',
    'Terms & Conditions',
    'Términos y condiciones',
  );
  String get newBalance => _l('Nouveau solde', 'New balance', 'Nuevo saldo');
  String get backToWallet => _l(
    'Retour au portefeuille',
    'Back to Wallet',
    'Volver al monedero',
  );
  String get youPay => _l('Vous payez', 'You pay', 'Pagas');
  String get youReceive => _l('Vous recevez', 'You receive', 'Recibes');

  // ── Professional Stripe Account ──────────────────────────────────────────
  String get stripeAccount => _l(
    'Compte Stripe',
    'Stripe Account',
    'Cuenta de Stripe',
  );
  String get setUpPayments => _l(
    'Configurer les paiements',
    'Set Up Payments',
    'Configurar los pagos',
  );
  String get stripeOnboardingDescription => _l(
    'Connectez votre compte Stripe pour recevoir les paiements de vos sessions. Vous serez redirigé vers Stripe pour finaliser la configuration.',
    'Connect your Stripe account to receive payments for your sessions. You will be redirected to Stripe to complete setup.',
    'Conecta tu cuenta de Stripe para recibir los pagos de tus sesiones. Te redirigiremos a Stripe para completar la configuración.',
  );
  String get startOnboarding => _l(
    'Commencer la configuration',
    'Start Onboarding',
    'Comenzar la configuración',
  );
  String get stripeAccountActive => _l(
    'Compte Stripe actif',
    'Stripe Account Active',
    'Cuenta de Stripe activa',
  );
  String get stripeAccountPending => _l(
    'Configuration en attente',
    'Setup Pending',
    'Configuración pendiente',
  );
  String get stripeAccountError => _l(
    'Erreur de configuration',
    'Setup Error',
    'Error de configuración',
  );
  String get readyToReceivePayments => _l(
    'Vous êtes prêt à recevoir des paiements.',
    'You are ready to receive payments.',
    'Ya puedes recibir pagos.',
  );
  String get completeOnboardingToReceive => _l(
    'Finalisez la configuration Stripe pour recevoir vos paiements.',
    'Complete Stripe setup to receive your payments.',
    'Completa la configuración de Stripe para recibir tus pagos.',
  );
  String get stripeAccountErrorDetail => _l(
    'Une erreur est survenue avec votre compte Stripe. Contactez le support.',
    'An error occurred with your Stripe account. Contact support.',
    'Se ha producido un error con tu cuenta de Stripe. Contacta con soporte.',
  );
  String get accountActive => _l(
    'Compte actif',
    'Active Account',
    'Cuenta activa',
  );
  String get stripeAccountActiveMessage => _l(
    'Votre compte Stripe est connecté et actif. Vous pouvez gérer vos paramètres de paiement depuis le tableau de bord Stripe.',
    'Your Stripe account is connected and active. You can manage your payment settings from the Stripe dashboard.',
    'Tu cuenta de Stripe está conectada y activa. Puedes gestionar tus ajustes de pago desde el panel de Stripe.',
  );
  String get viewDashboard => _l(
    'Voir le tableau de bord Stripe',
    'View Stripe Dashboard',
    'Ver el panel de Stripe',
  );
  String get accountId => _l('ID du compte', 'Account ID', 'ID de la cuenta');
  String get stripeOnboardingInfo => _l(
    'Vous serez redirigé vers Stripe pour configurer votre compte de paiement.',
    'You will be redirected to Stripe to set up your payment account.',
    'Te redirigiremos a Stripe para configurar tu cuenta de pagos.',
  );
  String get failedLoadAccount => _l(
    'Impossible de charger les informations du compte',
    'Failed to load account info',
    'No se pudo cargar la información de la cuenta',
  );
  String get noOnboardingUrlAvailable => _l(
    'Aucune URL d\'onboarding disponible. Réessayez plus tard.',
    'No onboarding URL available. Try again later.',
    'No hay ninguna URL de configuración disponible. Inténtalo más tarde.',
  );
  String get invalidOnboardingUrl => _l(
    'URL d\'onboarding invalide.',
    'Invalid onboarding URL.',
    'URL de configuración no válida.',
  );
  String get failedToOpenUrl => _l(
    'Impossible d\'ouvrir le lien.',
    'Failed to open link.',
    'No se pudo abrir el enlace.',
  );

  // ── Appointment Booking ─────────────────────────────────────────────────
  String get bookAppointment => _l(
    'Prendre rendez-vous',
    'Book Appointment',
    'Reservar cita',
  );
  String get availableSlots => _l(
    'Créneaux disponibles',
    'Available Slots',
    'Horarios disponibles',
  );
  String get noSlotsAvailable => _l(
    'Aucun créneau disponible',
    'No slots available',
    'No hay horarios disponibles',
  );
  String get registerAndPay => _l(
    'S\'inscrire et payer',
    'Register & Pay',
    'Inscribirse y pagar',
  );
  String get appointmentPaidSuccess => _l(
    'Rendez-vous réservé et payé avec succès !',
    'Appointment booked & paid successfully!',
    '¡Cita reservada y pagada correctamente!',
  );
  String get appointmentPayFailed => _l(
    'Le paiement du rendez-vous a échoué',
    'Appointment payment failed',
    'El pago de la cita ha fallado',
  );
  String get appointmentPayPending => _l(
    'Paiement reçu, réservation en cours de confirmation...',
    'Payment received, booking confirmation pending...',
    'Pago recibido, confirmación de la reserva pendiente...',
  );
  String get appointmentRateInfo => _l(
    'Tarif : ~%s/min — facturé selon la durée réelle',
    'Rate: ~%s/min — charged for actual duration',
    'Tarifa: ~%s/min — se factura la duración real',
  );
  String get slotDate => _l('Date', 'Date', 'Fecha');
  String get slotTime => _l('Horaire', 'Time', 'Hora');
  String get confirmBooking => _l(
    'Confirmer la réservation',
    'Confirm Booking',
    'Confirmar la reserva',
  );
  String get processingRegistration => _l(
    'Inscription en cours...',
    'Registering...',
    'Inscribiendo...',
  );
  String get registrationFailed => _l(
    'Échec de l\'inscription au créneau',
    'Slot registration failed',
    'Error al inscribirse en el horario',
  );
  String get alreadyRegistered => _l(
    'Vous êtes déjà inscrit(e) à cette séance.',
    'You are already registered for this session.',
    'Ya estás inscrito en esta sesión.',
  );
  String get consultationSlotInfo => _l(
    'Créneau de consultation 1-à-1 — facturé par minute. Lancez la session depuis le profil.',
    '1-on-1 consultation slot — billed per minute. Start the session from the profile.',
    'Horario de consulta individual: se factura por minuto. Inicia la sesión desde el perfil.',
  );
  String get continueToProfile => _l(
    'Continuer vers le profil',
    'Continue to profile',
    'Continuar al perfil',
  );

  // ── Generic errors & shared labels ──────────────────────────────────────────
  String get pleaseTryAgain =>
      _l('Veuillez réessayer.', 'Please try again.', 'Inténtalo de nuevo.');
  String get genericErrorRetry => _l(
    'Une erreur est survenue. Veuillez réessayer.',
    'An error occurred. Please try again.',
    'Se ha producido un error. Inténtalo de nuevo.',
  );
  String get decline => _l('Refuser', 'Decline', 'Rechazar');
  String get start => _l('Démarrer', 'Start', 'Iniciar');
  String get preparingExperience => _l(
    'Préparation de votre expérience',
    'Preparing your experience',
    'Preparando tu experiencia',
  );
  String get bioOriginalLanguageNote => _l(
    'Les biographies sont rédigées par chaque voyant et peuvent rester dans leur langue d\'origine.',
    'Professional biographies are written by each psychic and may remain in their original language.',
    'Las biografías las redacta cada profesional y pueden permanecer en su idioma original.',
  );
  String get paymentUnavailable => _l(
    'Le paiement est temporairement indisponible. Veuillez réessayer plus tard.',
    'Payment is temporarily unavailable. Please try again later.',
    'El pago no está disponible temporalmente. Inténtalo de nuevo más tarde.',
  );

  // ── Chat list, banners & misc screen copy ───────────────────────────────────
  String get allMessages =>
      _l('Tous les messages', 'All Messages', 'Todos los mensajes');
  String get pinned => _l('Épinglés', 'Pinned', 'Fijados');
  String newChatSessionFrom(String name) => _l(
    'Nouvelle session chat de $name',
    'New chat session from $name',
    'Nueva sesión de chat de $name',
  );
  String get open => _l('Ouvrir', 'Open', 'Abrir');
  String get dismiss => _l('Ignorer', 'Dismiss', 'Descartar');
  /// Lowercase session-type noun, used inside sentences.
  String sessionTypeNoun(String type) {
    switch (type) {
      case 'video':
        return _l('vidéo', 'video', 'de vídeo');
      case 'phone':
        return _l('téléphonique', 'phone', 'telefónica');
      default:
        return _l('chat', 'chat', 'de chat');
    }
  }
  String incomingCallTitle(String type) => _l(
    'Appel ${sessionTypeNoun(type)} entrant',
    'Incoming ${sessionTypeNoun(type)} call',
    'Llamada ${sessionTypeNoun(type)} entrante',
  );
  String get pleaseTryAgainLater => _l(
    'Veuillez réessayer plus tard.',
    'Please try again later.',
    'Inténtalo de nuevo más tarde.',
  );
  String get splashTagline => _l(
    'Sessions en direct et accompagnement expert',
    'Real-time sessions and expert guidance',
    'Sesiones en directo y orientación experta',
  );
  String get acceptTermsNotice => _l(
    'En continuant, vous acceptez nos Conditions Générales',
    'By continuing, you accept our Terms & Conditions',
    'Al continuar, aceptas nuestros Términos y Condiciones',
  );
  String get couldNotLoadHistory => _l(
    'Impossible de charger votre historique. Veuillez réessayer.',
    'Could not load your history. Please try again.',
    'No se pudo cargar tu historial. Inténtalo de nuevo.',
  );
}
