/// Centralised French, English and Spanish string table.
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
  String get resetPasswordSubtitle => _fr
      ? "Saisissez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe."
      : "Enter your email address and we'll send you a link to reset your password.";
  String get sendResetLink => _fr ? 'Envoyer le lien' : 'Send Reset Link';
  String get resetLinkSent => _fr
      ? 'Un e-mail vous a été envoyé pour réinitialiser votre mot de passe.'
      : 'An email has been sent to reset your password.';
  String get noAccountWithEmail => _fr
      ? 'Aucun compte trouvé avec cette adresse e-mail.'
      : 'No account found with this email address.';
  String resetLinkFailed(String err) => _fr
      ? "Échec de l'envoi du lien : $err"
      : 'Failed to send reset link: $err';
  String get backToLogin => _fr ? 'Retour à la connexion' : 'Back to Login';

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
  String get iIdentifyAs => _fr ? 'Je suis' : 'I identify as';
  String get male => _fr ? 'Homme' : 'Male';
  String get female => _fr ? 'Femme' : 'Female';
  String get other => _fr ? 'Autre' : 'Other';
  String get firstName => _fr ? 'Prénom' : 'First name';
  String get lastName => _fr ? 'Nom' : 'Last name';
  String get displayName => _fr ? "Nom d'affichage" : 'Display name';
  String get dateOfBirth => _fr ? 'Date de naissance' : 'Date of birth';
  String get country => _fr ? 'Pays' : 'Country';
  String get mobile => _fr ? 'Mobile' : 'Mobile';
  String get confirmPassword =>
      _fr ? 'Confirmer le mot de passe' : 'Confirm password';
  String get passwordsNoMatch =>
      _fr ? 'Les mots de passe ne correspondent pas' : 'Passwords do not match';
  String get min6Chars => _fr ? '6 caractères minimum' : 'Min 6 characters';
  String get invalidEmail =>
      _fr ? "Format d'e-mail invalide" : 'Invalid email format';
  String get invalidPhone =>
      _fr ? 'Numero de telephone invalide' : 'Invalid phone number';
  String get passwordRules => _fr
      ? 'Le mot de passe ne respecte pas les exigences de securite.'
      : 'Password does not meet the security requirements.';
  String get required => _fr ? 'Requis' : 'Required';
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
      : [
          'France',
          'Belgium',
          'Canada',
          'Switzerland',
          'United Kingdom',
          'United States',
          'Other',
        ];

  String get acceptCgu => _fr
      ? "J'accepte les Conditions Générales d'Utilisation (CGU)"
      : 'I accept the Terms of Use (CGU)';
  String get acceptCgs => _fr
      ? "J'accepte les Conditions Générales de Service (CGS)"
      : 'I accept the Terms of Service (CGS)';
  String get pleaseAcceptCguCgs => _fr
      ? 'Veuillez accepter les CGU et CGS pour continuer.'
      : 'Please accept CGU and CGS to continue.';
  String get legalStructure => _fr ? 'Structure legale' : 'Legal structure';
  String get legalIndividual => _fr ? 'Individuel' : 'Individual';
  String get legalCompany => _fr ? 'Societe' : 'Company';
  String get legalAssociation => _fr ? 'Association' : 'Association';
  String get acceptCharter => _fr
      ? "J'accepte la charte professionnelle"
      : 'I accept the professional charter';
  String get pleaseAcceptCharter => _fr
      ? 'Veuillez accepter la charte professionnelle pour continuer.'
      : 'Please accept the professional charter to continue.';
  String get invalidLegalStructure =>
      _fr ? 'Structure legale invalide.' : 'Invalid legal structure.';
  String get siretNumber => _fr
      ? 'Numéro d\'immatriculation (SIRET / RNE)'
      : 'Registration number (SIRET / RNE)';
  String get invalidSiret => _fr
      ? 'Un numéro d\'immatriculation valide est obligatoire.'
      : 'A valid registration number is required.';
  String get companyName => _fr ? 'Nom de la société' : 'Company name';
  String get societyRequired => _fr
      ? 'Le nom de la société est obligatoire pour une société.'
      : 'A company name is required for a company.';
  String get emailAlreadyRegistered => _fr
      ? 'Cette adresse e-mail est deja inscrite.'
      : 'This email is already registered.';
  String get phoneAlreadyRegistered => _fr
      ? 'Ce numero de telephone est deja inscrit.'
      : 'This phone number is already registered.';
  String get signupRecaptchaRequired => _fr
      ? 'La verification anti-spam est requise pour creer ce compte.'
      : 'Anti-spam verification is required to create this account.';
  String get accountCreated =>
      _fr ? 'Compte cree ! Bienvenue.' : 'Account created! Welcome.';
  String createAccountFailed(String err) => _fr
      ? 'Échec de la création du compte : $err'
      : 'Failed to create account: $err';
  String loginFailed(String err) =>
      _fr ? 'Échec de la connexion : $err' : 'Login failed: $err';
  String get invalidLoginCredentials => _fr
      ? 'E-mail ou mot de passe incorrect.'
      : 'Incorrect email or password.';
  String get alreadyHaveAccount =>
      _fr ? 'Vous avez déjà un compte ? ' : 'Already have an account? ';

  // ── Bottom nav tabs ─────────────────────────────────────────────────────────
  String get tabExplore => _l('Explorer', 'Explore', 'Explorar');
  String get tabChat => _l('Chat', 'Chat', 'Chat');
  String get tabHistory => _l('Historique', 'History', 'Historial');
  String get tabReviews => _l('Avis', 'Reviews', 'Reseñas');
  String get tabProfile => _l('Profil', 'Profile', 'Perfil');
  String get tabHome => _l('Accueil', 'Home', 'Inicio');
  String get tabSlots => _l('Créneaux', 'Slots', 'Horarios');
  String get tabClients => _l('Clients', 'Clients', 'Clientes');

  // ── Professional dashboard ──────────────────────────────────────────────────
  String get dashboard => _fr ? 'Tableau de bord' : 'Dashboard';
  String welcomeBackName(String name) =>
      _fr ? 'Bienvenue, $name' : 'Welcome back, $name';
  String get yourProDashboard => _fr
      ? 'Votre tableau de bord professionnel'
      : 'Your professional dashboard';
  String get totalSessions => _fr ? 'Sessions totales' : 'Total Sessions';
  String get avgRating => _fr ? 'Note moyenne' : 'Avg Rating';
  String get upcomingSessions => _fr ? 'Sessions à venir' : 'Upcoming Sessions';
  String get recentSessions => _fr ? 'Sessions récentes' : 'Recent Sessions';
  String get noSessionsYet =>
      _fr ? 'Pas encore de sessions' : 'No sessions yet';
  String get failedLoadSessions =>
      _fr ? 'Impossible de charger les sessions' : 'Failed to load sessions';

  // ── Profile screen ──────────────────────────────────────────────────────────
  String get guestUser => _fr ? 'Utilisateur invité' : 'Guest User';
  String get settings => _fr ? 'Paramètres' : 'Settings';
  String get editProfile => _fr ? 'Modifier le profil' : 'Edit Profile';
  String get updateInfo =>
      _fr ? 'Mettre à jour vos informations' : 'Update your information';
  String get editProfileComingSoon => _fr
      ? 'Modification du profil bientôt disponible'
      : 'Edit Profile Coming Soon';
  String get descriptionOptional =>
      _fr ? 'Description (optionnel)' : 'Description (optional)';
  String get saveChanges =>
      _fr ? 'Enregistrer les modifications' : 'Save Changes';
  String get profileUpdated =>
      _fr ? 'Profil mis à jour avec succès' : 'Profile updated successfully';
  String profileUpdateFailed(String err) => _fr
      ? 'Échec de la mise à jour du profil : $err'
      : 'Failed to update profile: $err';
  String get paymentMethods => _fr ? 'Moyens de paiement' : 'Payment Methods';
  String get cardsBilling =>
      _fr ? 'Cartes et facturation' : 'Cards and billing';
  String get support => _fr ? 'Assistance' : 'Support';
  String get helpCenter => _fr ? "Centre d'aide" : 'Help Center';
  String get faqsGuides => _fr ? 'FAQ et guides' : 'FAQs and guides';
  String get termsOfUse =>
      _fr ? 'Conditions d\'utilisation (CGU)' : 'Terms of Use (CGU)';
  String get termsOfService =>
      _fr ? 'Conditions de service (CGS)' : 'Terms of Service (CGS)';
  String get legalNotice => _fr ? 'Mentions légales' : 'Legal Notice';
  String get legalNoticeSubtitle => _fr
      ? 'Informations légales et éditeur du service'
      : 'Legal and publisher information';
  String get contactSupport => _fr ? 'Contacter le support' : 'Contact Support';
  String get contactSupportSubtitle => _fr
      ? 'Assistance par e-mail ou formulaire'
      : 'Help via email or contact form';
  String get trustQuality => _fr ? 'Confiance & qualité' : 'Trust & Quality';
  String get trustQualitySubtitle => _fr
      ? 'Professionnels vérifiés et avis'
      : 'Verified professionals and reviews';
  String get sessionsLabel => _fr ? 'Sessions' : 'Sessions';
  String get totalTime => _fr ? 'Temps total' : 'Total Time';
  String get rating => _fr ? 'Note' : 'Rating';
  String get logout => _fr ? 'Se déconnecter' : 'Log Out';
  String get logoutConfirmTitle => _fr ? 'Se déconnecter ?' : 'Log out?';
  String get logoutConfirmMessage => _fr
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to log out?';

  // ── Explore / Professionals list ────────────────────────────────────────────
  String get explore => _l('Explorer', 'Explore', 'Explorar');
  String get unableLoadExplore =>
      _fr ? 'Impossible de charger les données' : 'Unable to load explore data';
  String get tryAgain => _fr ? 'Réessayer' : 'Try Again';
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
  String get filters => _fr ? 'Filtres' : 'Filters';
  String get reset => _fr ? 'Réinitialiser' : 'Reset';
  String get specialty => _fr ? 'Spécialité' : 'Specialty';
  String get type => _fr ? 'Type' : 'Type';
  String get experience => _fr ? 'Expérience' : 'Experience';
  String get price => _fr ? 'Prix' : 'Price';
  String get language => _fr ? 'Langue' : 'Language';
  String get sessionType => _fr ? 'Type de session' : 'Session type';
  String get favoritesOnly => _fr ? 'Favoris seulement' : 'Favorites only';
  String get favoritePsychicsSubtitle => _l(
    'Retrouvez vos voyants favoris',
    'View your favorite psychics',
    'Consulta tus profesionales favoritos',
  );
  String get phone => _fr ? 'Téléphone' : 'Phone';
  String get video => _fr ? 'Vidéo' : 'Video';
  String get moreFilters => _fr ? 'Plus de filtres' : 'More Filters';
  String get filterSubtitle => _fr
      ? 'Spécialité, expérience, prix, type de session, langue'
      : 'Specialty, experience, price, session type, language';
  String get specialties => _fr ? 'Spécialités' : 'Specialties';
  String get categories => _fr ? 'Catégories' : 'Categories';
  String get pricingEurMin => _fr ? 'Prix (EUR/min)' : 'Price (EUR/min)';
  String get featuredAdvisors => _l(
    'Nos voyants recommandés',
    'Our recommended psychics',
    'Nuestros profesionales recomendados',
  );
  String get topProsReadyNow => _fr
      ? 'Les meilleurs professionnels en ligne disponibles'
      : 'Top online professionals ready now';
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
  String get clearFiltersAndRetry =>
      _fr ? 'Effacer les filtres et réessayer' : 'Clear filters and retry';
  String get quickSessionTest =>
      _fr ? 'Test rapide de session' : 'Quick session test';
  String get quickSessionTestHint => _fr
      ? 'Ouvre directement un profil compatible pour tester le module de session.'
      : 'Opens a compatible profile directly to test the session module.';
  String get noVideoTestCandidate => _fr
      ? 'Aucun professionnel disponible pour un test vidéo.'
      : 'No professional available for video test.';
  String get noPhoneTestCandidate => _fr
      ? 'Aucun professionnel disponible pour un test téléphone.'
      : 'No professional available for phone test.';
  String get noChatTestCandidate => _fr
      ? 'Aucun professionnel disponible pour un test chat.'
      : 'No professional available for chat test.';
  String get discoverYourGuide =>
      _l('Découvrez votre guide', 'Discover Your Guide', 'Descubre tu guía');
  String nAdvisorsAvailable(int n) => _l(
    '$n voyants disponibles pour chat et vidéo',
    '$n psychics available for chat and video sessions',
    '$n profesionales disponibles para chat y vídeo',
  );
  String specialtyFilterLabel(String s) =>
      _fr ? 'Spécialité : $s' : 'Specialty: $s';
  String get results => _fr ? 'résultats' : 'results';

  // ── Professional detail ─────────────────────────────────────────────────────
  String get startSession => _fr ? 'Démarrer une session' : 'Start Session';
  String get chooseSessionType =>
      _fr ? 'Choisir le type de session :' : 'Choose session type:';
  String get phoneCall => _fr ? 'Appel téléphonique' : 'Phone Call';
  String get videoCall => _fr ? 'Appel vidéo' : 'Video Call';
  String get textChat => _fr ? 'Chat textuel' : 'Text Chat';
  String get available24Hours => _fr ? 'Disponible 24H/24' : 'Available 24/7';
  String get free => _fr ? 'Gratuit' : 'Free';
  String get cancel => _fr ? 'Annuler' : 'Cancel';
  String get addedFavorites =>
      _fr ? 'Ajouté aux favoris ❤️' : 'Added to favorites ❤️';
  String get removedFavorites =>
      _fr ? 'Retiré des favoris' : 'Removed from favorites';
  String get couldNotUpdateFavorite => _fr
      ? 'Impossible de mettre à jour les favoris. Réessayez.'
      : 'Could not update favorite. Please try again.';
  String get unableLoadProfile =>
      _fr ? 'Impossible de charger le profil' : 'Unable to load profile';
  String startingSession(String type, String name) => _fr
      ? 'Démarrage session $type avec $name...'
      : 'Starting $type session with $name...';
  String sessionCreated(String seId, String type) => _fr
      ? 'Session #$seId créée (${type.toUpperCase()})'
      : 'Session #$seId created (${type.toUpperCase()})';
  String get availableNow =>
      _l('Disponible maintenant', 'Available now', 'Disponible ahora');
  String get viewAvailability =>
      _l('Voir les disponibilités', 'View availability', 'Ver disponibilidad');
  String get profileVerified =>
      _l('Profil vérifié', 'Profile verified', 'Perfil verificado');
  String get emailVerified =>
      _l('E-mail vérifié', 'Email verified', 'Correo verificado');
  String get call => _l('Appel', 'Call', 'Llamada');
  String get noAvailabilityAtMoment => _fr
      ? 'Aucune disponibilité pour le moment'
      : 'No availability at the moment';
  String get bookSession => _fr ? 'Réserver une session' : 'Book Session';
  String get availableServices =>
      _fr ? 'Services disponibles' : 'Available Services';
  String get about => _fr ? 'À propos' : 'About';
  String get expertise => _fr ? 'Expertise' : 'Expertise';
  String get languages => _fr ? 'Langues' : 'Languages';
  String get pricePerMinute => _fr ? 'Prix par minute' : 'Price per minute';
  String get startSessionNow =>
      _fr ? 'Démarrer la session' : 'Start Session Now';
  String errorMessage(String err) => _fr ? 'Erreur : $err' : 'Error: $err';
  String get verifiedProfile => _fr ? 'PROFIL VÉRIFIÉ' : 'VERIFIED PROFILE';

  // ── Availability / Slots ────────────────────────────────────────────────────
  String get manageSlots => _fr ? 'Gérer les créneaux' : 'Manage Slots';
  String get addSlot => _fr ? 'Ajouter un créneau' : 'Add Slot';
  String get addAvailabilitySlot =>
      _fr ? 'Ajouter un créneau de disponibilité' : 'Add Availability Slot';
  String get day => _fr ? 'Jour' : 'Day';
  String get startTime => _fr ? 'Heure de début (HH:mm)' : 'Start Time (HH:mm)';
  String get endTime => _fr ? 'Heure de fin (HH:mm)' : 'End Time (HH:mm)';
  String get save => _fr ? 'Enregistrer' : 'Save';
  String get startTimeHint => _fr ? '09:00' : '09:00';
  String get endTimeHint => _fr ? '10:00' : '10:00';
  String get startTimeRequired =>
      _fr ? "L'heure de début est requise" : 'Start time is required';
  String get use24hFormat =>
      _fr ? 'Utiliser le format 24h, ex. 09:00' : 'Use 24h format, e.g. 09:00';
  String get slotAddedSuccess => _fr
      ? 'Créneau de disponibilité ajouté avec succès'
      : 'Availability slot added successfully';
  String get slotUpdatedSuccess => _fr
      ? 'Créneau de disponibilité mis à jour avec succès'
      : 'Availability slot updated successfully';
  String get slotDeletedSuccess => _fr
      ? 'Créneau de disponibilité supprimé avec succès'
      : 'Availability slot deleted successfully';
  String failedAddSlot(String err) =>
      _fr ? "Échec de l'ajout du créneau : $err" : 'Failed to add slot: $err';
  String failedUpdateSlot(String err) => _fr
      ? "Échec de la mise à jour du créneau : $err"
      : 'Failed to update slot: $err';
  String failedDeleteSlot(String err) => _fr
      ? "Échec de la suppression du créneau : $err"
      : 'Failed to delete slot: $err';
  String get editSlot => _fr ? 'Modifier le créneau' : 'Edit Slot';
  String get deleteSlot => _fr ? 'Supprimer le créneau' : 'Delete Slot';
  String get deleteSlotConfirm => _fr
      ? 'Voulez-vous vraiment supprimer ce créneau de disponibilité ?'
      : 'Are you sure you want to delete this availability slot?';
  String get edit => _fr ? 'Modifier' : 'Edit';
  String get delete => _fr ? 'Supprimer' : 'Delete';
  String get failedLoadAvailability => _fr
      ? 'Impossible de charger les disponibilités'
      : 'Failed to load availability';
  String get retry => _fr ? 'Réessayer' : 'Retry';
  String get noSlotsYet => _fr ? 'Aucun créneau ajouté' : 'No slots added yet';
  String get tapAddSlot => _fr
      ? 'Appuyez sur "Ajouter un créneau" pour définir vos disponibilités.'
      : 'Tap "Add Slot" to set your availability.';
  String get refresh => _fr ? 'Actualiser' : 'Refresh';
  String get weeklySlots => _fr ? 'Créneaux hebdomadaires' : 'Weekly Slots';
  String get yourAvailability =>
      _fr ? 'Votre disponibilité' : 'Your Availability';
  String get availabilitySubtitle => _fr
      ? 'Définissez les heures pendant lesquelles vos clients peuvent vous joindre.'
      : 'Set the hours when your clients can reach you.';
  String get daysCount => _fr ? 'jours' : 'days';
  String get slotsCount => _fr ? 'créneaux' : 'slots';
  String get managed => _fr ? 'gérés' : 'managed';
  String slotsCountFor(int count) => _fr
      ? '$count créneau${count > 1 ? 'x' : ''}'
      : '$count slot${count > 1 ? 's' : ''}';

  // Days of week
  String get monday => _fr ? 'Lundi' : 'Monday';
  String get tuesday => _fr ? 'Mardi' : 'Tuesday';
  String get wednesday => _fr ? 'Mercredi' : 'Wednesday';
  String get thursday => _fr ? 'Jeudi' : 'Thursday';
  String get friday => _fr ? 'Vendredi' : 'Friday';
  String get saturday => _fr ? 'Samedi' : 'Saturday';
  String get sunday => _fr ? 'Dimanche' : 'Sunday';
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
  String get reviewTargetCoidHint =>
      _fr ? 'ID du professionnel (optionnel)' : 'Professional ID (optional)';
  String get reviewSessionIdHint =>
      _fr ? 'ID de session (optionnel)' : 'Session ID (optional)';
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
  String get reviewsFromClientsWillAppear => _fr
      ? 'Les avis de vos clients\napparaîtront ici'
      : 'Reviews from your clients\nwill appear here';
  String get reviewsFromConsultationsWillAppear => _fr
      ? 'Les avis de vos consultations\napparaîtront ici'
      : 'Reviews from your consultations\nwill appear here';
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
  String get noSessionsHistory =>
      _fr ? 'Aucune session dans l\'historique' : 'No sessions in history';
  String get noHistoryYet => _fr
      ? 'Vos sessions passées apparaîtront ici.'
      : 'Your past sessions will appear here.';
  String get noSessionsYetTitle =>
      _fr ? 'Aucune session pour le moment' : 'No Sessions Yet';
  String get consultationHistoryWillAppear => _fr
      ? 'Votre historique de consultation\napparaîtra ici'
      : 'Your consultation history will\nappear here';

  // ── Chat ─────────────────────────────────────────────────────────────────────
  String get messages => _l('Messages', 'Messages', 'Mensajes');
  String get searchConversations => _l(
    'Rechercher des conversations...',
    'Search conversations...',
    'Buscar conversaciones...',
  );
  String get failedLoadConversations => _fr
      ? 'Impossible de charger les conversations'
      : 'Failed to load conversations';
  String get noConversationsFound =>
      _fr ? 'Aucune conversation trouvée' : 'No conversations found';
  String get noConversationsYet =>
      _fr ? 'Aucune conversation pour le moment' : 'No conversations yet';
  String get startChatExplore => _fr
      ? 'Commencez une session avec un professionnel pour discuter.'
      : 'Start a session with a professional to chat.';
  String get typeMessage =>
      _l('Écrire un message...', 'Type a message...', 'Escribe un mensaje...');
  String get send => _l('Envoyer', 'Send', 'Enviar');
  String sendMessageFailed(String err) => _fr
      ? 'Échec de l\'envoi du message : $err'
      : 'Failed to send message: $err';
  String get conversation => _fr ? 'Conversation' : 'Conversation';
  String get activeNow => _fr ? 'Actif maintenant' : 'Active now';
  String get failedLoadMessages =>
      _fr ? 'Impossible de charger les messages' : 'Failed to load messages';
  String get noMessagesYet =>
      _fr ? 'Aucun message pour le moment' : 'No messages yet';
  String get startConversation =>
      _fr ? 'Commencez la conversation !' : 'Start the conversation!';
  String get unknown => _fr ? 'Inconnu' : 'Unknown';
  String get session => _fr ? 'Session' : 'Session';

  // ── Pricing ──────────────────────────────────────────────────────────────────
  String get sessionPricing => _fr ? 'Tarifs des sessions' : 'Session Pricing';
  String get pricing => _fr ? 'Tarifs' : 'Pricing';
  String get noPricingInfo =>
      _fr ? 'Aucune information tarifaire' : 'No pricing information';
  String get noPricingAvailable => _fr
      ? 'Aucune information tarifaire disponible'
      : 'No pricing information available';
  String get consultation => _fr ? 'Consultation' : 'Consultation';
  String get credit => _fr ? 'Crédit' : 'Credit';
  String get promoCode => _fr ? 'Code promo' : 'Promo code';
  String get applyPromo => _fr ? 'Appliquer' : 'Apply';
  String promoApplied(String code, String discount) => _fr
      ? 'Code $code appliqué : $discount%'
      : 'Code $code applied: $discount%';
  String get promoInvalid => _fr ? 'Code promo invalide' : 'Invalid promo code';
  String promoCheckFailed(String err) => _fr
      ? 'Échec de la vérification du code promo : $err'
      : 'Failed to check promo code: $err';
  String get registerAppointment =>
      _fr ? 'S\'inscrire à un créneau' : 'Register for appointment';
  String get appointmentId => _fr ? 'ID de créneau' : 'Appointment ID';
  String get appointmentRegistered => _fr
      ? 'Inscription au créneau réussie'
      : 'Appointment registration successful';
  String appointmentRegistrationFailed(String err) => _fr
      ? 'Échec de l\'inscription au créneau : $err'
      : 'Appointment registration failed: $err';
  String get selectAppointment =>
      _fr ? 'Sélectionner un créneau' : 'Select appointment';
  String get searchAppointments =>
      _fr ? 'Rechercher un créneau...' : 'Search appointments...';
  String get noAppointmentCandidates => _fr
      ? 'Aucun créneau disponible pour inscription.'
      : 'No appointment slots available to register.';
  String get loadingAppointments =>
      _fr ? 'Chargement des créneaux...' : 'Loading appointments...';
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
  String get phoneSession => _fr ? 'Session téléphonique' : 'Phone Session';
  String get answerPhoneTitle =>
      _fr ? 'Repondez a votre telephone' : 'Answer your phone';
  String get phonePstnSessionMessage => _fr
      ? 'Voyanz appelle les deux participants sur leur numero mobile verifie.'
      : 'Voyanz is calling both participants on their verified mobile numbers.';
  String get phonePstnNoInAppAudio => _fr
      ? 'L\'audio se fait par appel telephonique classique, pas dans l\'app.'
      : 'Audio happens through a regular phone call, not inside the app.';
  String get phonePstnPressKeyInstruction => _fr
      ? 'Quand vous repondez, appuyez sur la touche 1 pour confirmer que vous etes bien la.'
      : 'When you answer, press key 1 to confirm you are really there.';
  String phonePstnPressKeyCountdown(int seconds) => _fr
      ? 'Confirmez dans $seconds s, sinon la session sera annulee.'
      : 'Confirm within $seconds s, or the session will be cancelled.';
  String get phonePstnCallConfirmed =>
      _fr ? 'Appel confirme.' : 'Call confirmed.';
  String get sessionStatusNoStarConfirmLabel =>
      _fr ? 'Appel non confirme' : 'Call not confirmed';
  String get sessionStatusNoStarConfirmMessage => _fr
      ? 'Le professionnel n\'a pas appuye sur la touche 1 pour confirmer. La session a ete annulee.'
      : 'The professional did not press key 1 to confirm. The session was cancelled.';
  String get phoneEndReasonProfessionalUnavailable => _fr
      ? 'La ligne du professionnel n\'a pas repondu (messagerie).'
      : 'The professional\'s line was unavailable (voicemail).';
  String get phoneEndReasonCustomerNoAnswer => _fr
      ? 'Le client n\'a pas repondu. La session a ete annulee.'
      : 'The customer did not answer. The session was cancelled.';
  String get chatSession => _fr ? 'Session chat' : 'Chat Session';
  String get sessionReady => _fr ? 'Session prête' : 'Session ready';
  String get openConversations =>
      _fr ? 'Ouvrir les conversations' : 'Open conversations';
  String get endSession => _fr ? 'Terminer la session' : 'End Session';
  String get endSessionConfirmTitle =>
      _fr ? 'Terminer la session ?' : 'End session?';
  String get endSessionConfirmMessage => _fr
      ? 'Voulez-vous vraiment terminer cette session ?'
      : 'Do you really want to end this session?';
  String get sessionEnded => _fr ? 'Session terminée' : 'Session ended';
  String get sessionStatusCallingLabel => _fr ? 'Appel en cours' : 'Calling';
  String get sessionStatusAcceptedLabel => _fr ? 'Acceptée' : 'Accepted';
  String get sessionStatusPendingLabel => _fr ? 'En attente' : 'Pending';
  String get sessionStatusInProgressLabel => _fr ? 'En cours' : 'In progress';
  String get sessionStatusCompletedLabel => _fr ? 'Terminée' : 'Completed';
  String get sessionStatusRejectedLabel => _fr ? 'Refusée' : 'Rejected';
  String get sessionStatusCanceledLabel => _fr ? 'Annulée' : 'Canceled';
  String sessionStatusUnknownLabel(String rawStatus) => _fr
      ? (rawStatus.isEmpty ? 'Inconnu' : rawStatus)
      : (rawStatus.isEmpty ? 'Unknown' : rawStatus);
  String sessionStatusCallingMessage({required bool isProfessional}) => _fr
      ? (isProfessional
            ? 'Le client est en train d\'être connecté. Veuillez rester sur cet écran.'
            : 'Le professionnel est en train d\'être connecté. Veuillez rester sur cet écran.')
      : (isProfessional
            ? 'The customer is being connected. Please stay on this screen.'
            : 'The professional is being connected. Please stay on this screen.');
  String sessionStatusAcceptedMessage({required bool isProfessional}) => _fr
      ? (isProfessional
            ? 'La demande a été acceptée. La connexion est en cours.'
            : 'La demande a été acceptée. La connexion est en cours.')
      : (isProfessional
            ? 'The request was accepted. The connection is in progress.'
            : 'The request was accepted. The connection is in progress.');
  String sessionStatusPendingMessage({required bool isProfessional}) => _fr
      ? (isProfessional
            ? 'La session est en attente de confirmation.'
            : 'La session est en attente de confirmation.')
      : (isProfessional
            ? 'The session is waiting for confirmation.'
            : 'The session is waiting for confirmation.');
  String sessionStatusInProgressMessage({required bool isProfessional}) => _fr
      ? (isProfessional
            ? 'La session est active. Vous êtes en consultation avec votre client.'
            : 'La session est active. Vous êtes en consultation avec votre professionnel.')
      : (isProfessional
            ? 'The session is live. You are connected with your customer.'
            : 'The session is live. You are connected with your professional.');
  String get sessionStatusCompletedMessage =>
      _fr ? 'Cette session est terminée.' : 'This session has ended.';
  String get sessionStatusRejectedMessage => _fr
      ? 'Cette session a été refusée et ne peut pas être rejointe.'
      : 'This session was rejected and cannot be joined.';
  String get sessionStatusCanceledMessage =>
      _fr ? 'Cette session a été annulée.' : 'This session was canceled.';
  String sessionStatusChangedMessage(String rawStatus) => _fr
      ? 'Le statut de la session a changé : ${rawStatus.isEmpty ? 'inconnu' : rawStatus}.'
      : 'Session status changed: ${rawStatus.isEmpty ? 'unknown' : rawStatus}.';
  String get unableCheckSessionStatus => _fr
      ? 'Impossible de vérifier le statut de la session'
      : 'Unable to check session status';
  String waitingForJoinTitle({required bool isProfessional}) => _fr
      ? (isProfessional
            ? 'En attente du client'
            : 'En attente du professionnel')
      : (isProfessional
            ? 'Waiting for customer to join'
            : 'Waiting for professional to join');
  String get sessionUnavailable =>
      _fr ? 'Session indisponible' : 'Session unavailable';
  String get sessionWaitTimedOutMessage => _fr
      ? 'Cela prend plus de temps que prévu. Vous pouvez réessayer maintenant ou créer une nouvelle demande de session.'
      : 'This is taking longer than expected. You can retry now or create a new session request.';
  String get refreshNow => _fr ? 'Actualiser maintenant' : 'Refresh now';
  String get rebookSession =>
      _fr ? 'Reprogrammer la session' : 'Rebook session';
  String get retryStatusCheck =>
      _fr ? 'Réessayer le statut' : 'Retry status check';
  String get backToHome => _fr ? 'Retour à l\'accueil' : 'Back to home';
  String get sessionAlreadyStarted => _fr
      ? 'La session est déjà lancée. Veuillez patienter.'
      : 'The session is already started. Please wait.';
  String get professionalBusyMessage => _fr
      ? 'Ce professionnel est actuellement en consultation. Veuillez réessayer dans quelques minutes, ou prenez un rendez-vous.'
      : 'This professional is currently in consultation. Please try again in a few minutes, or book a session.';
  String get rebookSessionFailed => _fr
      ? 'Impossible de créer une nouvelle demande de session. Veuillez réessayer.'
      : 'Could not create a new session request. Please try again.';
  String get connectionError =>
      _fr ? 'Erreur de connexion' : 'Connection Error';
  String get goBack => _fr ? 'Retour' : 'Go Back';
  String get mute => _fr ? 'Muet' : 'Mute';
  String get camera => _fr ? 'Caméra' : 'Camera';
  String get unmute => _fr ? 'Activer micro' : 'Unmute';
  String get cameraOff => _fr ? 'Couper caméra' : 'Camera off';
  String providerLabel(String provider) =>
      _fr ? 'Fournisseur : $provider' : 'Provider: $provider';
  String get connectingVideo =>
      _fr ? 'Connexion vidéo en cours...' : 'Connecting video...';
  String get waitingRemoteParticipant => _fr
      ? 'En attente de l\'autre participant...'
      : 'Waiting for the other participant...';
  String get reconnectingVideo =>
      _fr ? 'Reconnexion en cours...' : 'Reconnecting...';
  String get localPreview => _fr ? 'Vous' : 'You';
  String get remoteParticipant =>
      _fr ? 'Participant distant' : 'Remote participant';
  String get videoProviderNotSupported => _fr
      ? 'Le fournisseur vidéo reçu n\'est pas Agora.'
      : 'The received video provider is not Agora.';

  // ── Language selector ────────────────────────────────────────────────────────
  String get selectLanguage =>
      _l('Choisir la langue', 'Select Language', 'Seleccionar idioma');
  String get english => _l('Anglais', 'English', 'Inglés');
  String get french => _l('Français', 'French', 'Francés');

  // ── Profile / About dialogs ──────────────────────────────────────────────────
  String get privacyPolicy =>
      _fr ? 'Politique de confidentialité' : 'Privacy Policy';
  String get readOurTerms => _fr ? 'Lisez nos conditions' : 'Read our terms';
  String get aboutVoyanz => _fr ? 'À propos de Voyanz' : 'About Voyanz';
  String get version100 => _fr ? 'Version 1.0.0' : 'Version 1.0.0';
  String get close => _fr ? 'Fermer' : 'Close';
  String get versionLabel => _fr ? 'Version' : 'Version';
  String get helpCenterContent => _fr
      ? 'Les questions fréquentes et les guides seront bientôt disponibles. Pour une assistance immédiate, veuillez contacter notre équipe.'
      : 'Frequently asked questions and guides will be available soon. For immediate support, please contact our team.';
  String get privacyPolicyContent => _fr
      ? 'Notre politique de confidentialité détaille comment nous collectons, utilisons et protégeons vos données. La politique complète sera disponible dans la prochaine mise à jour.'
      : 'Our privacy policy details how we collect, use, and protect your data. Full policy will be available in the next update.';
  String get aboutVoyanzContent => _fr
      ? 'Voyanz - Votre plateforme de confiance pour les consultations professionnelles.\n\nVersion : 1.0.0\nConçu avec Flutter & ❤️'
      : 'Voyanz - Your trusted platform for professional consultations.\n\nVersion: 1.0.0\nBuilt with Flutter & ❤️';
  String get contactUs => _fr ? 'Contactez-nous' : 'Contact us';
  String get liveChat => _fr ? 'Chat en direct' : 'Live chat';
  String get openFullPolicy => _fr
      ? 'Ouvrir la politique complète en ligne'
      : 'Open the full policy online';
  String get supportChannels => _fr ? 'Canaux de contact' : 'Contact channels';

  // ── Wallet / Top-Up ──────────────────────────────────────────────────────
  String get wallet => _l('Portefeuille', 'Wallet', 'Monedero');
  String get topUp => _l('Recharger', 'Top Up', 'Recargar');
  String get topUpCredit =>
      _l('Recharger mon solde', 'Top Up Balance', 'Recargar saldo');
  String get buyPack => _l('Acheter', 'Buy', 'Comprar');
  String get selectPack =>
      _l('Choisir un pack', 'Select a pack', 'Seleccionar un paquete');
  String get creditReceived =>
      _l('Crédit reçu', 'Credit received', 'Crédito recibido');
  String get amountToPay =>
      _l('Montant à payer', 'Amount to pay', 'Importe a pagar');
  String get firstTopUpBonus =>
      _fr ? 'Bonus première recharge' : 'First top-up bonus';
  String get promoDiscount => _fr ? 'Réduction promo' : 'Promo discount';
  String get payWithCard =>
      _l('Payer par carte', 'Pay with Card', 'Pagar con tarjeta');
  String get processingPayment =>
      _fr ? 'Paiement en cours...' : 'Processing payment...';
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
  String get transactionHistory =>
      _fr ? 'Historique des transactions' : 'Transaction History';
  String get noTransactionsYet =>
      _fr ? 'Aucune transaction' : 'No transactions yet';
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
  String get newBalance => _fr ? 'Nouveau solde' : 'New balance';
  String get backToWallet => _fr ? 'Retour au portefeuille' : 'Back to Wallet';
  String get youPay => _fr ? 'Vous payez' : 'You pay';
  String get youReceive => _fr ? 'Vous recevez' : 'You receive';

  // ── Professional Stripe Account ──────────────────────────────────────────
  String get stripeAccount => _fr ? 'Compte Stripe' : 'Stripe Account';
  String get setUpPayments =>
      _fr ? 'Configurer les paiements' : 'Set Up Payments';
  String get stripeOnboardingDescription => _fr
      ? 'Connectez votre compte Stripe pour recevoir les paiements de vos sessions. Vous serez redirigé vers Stripe pour finaliser la configuration.'
      : 'Connect your Stripe account to receive payments for your sessions. You will be redirected to Stripe to complete setup.';
  String get startOnboarding =>
      _fr ? 'Commencer la configuration' : 'Start Onboarding';
  String get stripeAccountActive =>
      _fr ? 'Compte Stripe actif' : 'Stripe Account Active';
  String get stripeAccountPending =>
      _fr ? 'Configuration en attente' : 'Setup Pending';
  String get stripeAccountError =>
      _fr ? 'Erreur de configuration' : 'Setup Error';
  String get readyToReceivePayments => _fr
      ? 'Vous êtes prêt à recevoir des paiements.'
      : 'You are ready to receive payments.';
  String get completeOnboardingToReceive => _fr
      ? 'Finalisez la configuration Stripe pour recevoir vos paiements.'
      : 'Complete Stripe setup to receive your payments.';
  String get stripeAccountErrorDetail => _fr
      ? 'Une erreur est survenue avec votre compte Stripe. Contactez le support.'
      : 'An error occurred with your Stripe account. Contact support.';
  String get accountActive => _fr ? 'Compte actif' : 'Active Account';
  String get stripeAccountActiveMessage => _fr
      ? 'Votre compte Stripe est connecté et actif. Vous pouvez gérer vos paramètres de paiement depuis le tableau de bord Stripe.'
      : 'Your Stripe account is connected and active. You can manage your payment settings from the Stripe dashboard.';
  String get viewDashboard =>
      _fr ? 'Voir le tableau de bord Stripe' : 'View Stripe Dashboard';
  String get accountId => _fr ? 'ID du compte' : 'Account ID';
  String get stripeOnboardingInfo => _fr
      ? 'Vous serez redirigé vers Stripe pour configurer votre compte de paiement.'
      : 'You will be redirected to Stripe to set up your payment account.';
  String get failedLoadAccount => _fr
      ? 'Impossible de charger les informations du compte'
      : 'Failed to load account info';
  String get noOnboardingUrlAvailable => _fr
      ? 'Aucune URL d\'onboarding disponible. Réessayez plus tard.'
      : 'No onboarding URL available. Try again later.';
  String get invalidOnboardingUrl =>
      _fr ? 'URL d\'onboarding invalide.' : 'Invalid onboarding URL.';
  String get failedToOpenUrl =>
      _fr ? 'Impossible d\'ouvrir le lien.' : 'Failed to open link.';

  // ── Appointment Booking ─────────────────────────────────────────────────
  String get bookAppointment =>
      _fr ? 'Prendre rendez-vous' : 'Book Appointment';
  String get availableSlots => _fr ? 'Créneaux disponibles' : 'Available Slots';
  String get noSlotsAvailable =>
      _fr ? 'Aucun créneau disponible' : 'No slots available';
  String get registerAndPay => _fr ? 'S\'inscrire et payer' : 'Register & Pay';
  String get appointmentPaidSuccess => _fr
      ? 'Rendez-vous réservé et payé avec succès !'
      : 'Appointment booked & paid successfully!';
  String get appointmentPayFailed => _fr
      ? 'Le paiement du rendez-vous a échoué'
      : 'Appointment payment failed';
  String get appointmentPayPending => _fr
      ? 'Paiement reçu, réservation en cours de confirmation...'
      : 'Payment received, booking confirmation pending...';
  String get appointmentRateInfo => _fr
      ? 'Tarif : ~%s/min — facturé selon la durée réelle'
      : 'Rate: ~%s/min — charged for actual duration';
  String get slotDate => _fr ? 'Date' : 'Date';
  String get slotTime => _fr ? 'Horaire' : 'Time';
  String get confirmBooking =>
      _fr ? 'Confirmer la réservation' : 'Confirm Booking';
  String get processingRegistration =>
      _fr ? 'Inscription en cours...' : 'Registering...';
  String get registrationFailed =>
      _fr ? 'Échec de l\'inscription au créneau' : 'Slot registration failed';
  String get alreadyRegistered => _fr
      ? 'Vous êtes déjà inscrit(e) à cette séance.'
      : 'You are already registered for this session.';
  String get consultationSlotInfo => _fr
      ? 'Créneau de consultation 1-à-1 — facturé par minute. Lancez la session depuis le profil.'
      : '1-on-1 consultation slot — billed per minute. Start the session from the profile.';
  String get continueToProfile =>
      _fr ? 'Continuer vers le profil' : 'Continue to profile';
}
