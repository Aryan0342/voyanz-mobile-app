/// Centralised bilingual string table.
/// Default language is French ('fr'). Switch to 'en' for English.
class AppTranslations {
  final String lang;
  const AppTranslations(this.lang);

  bool get _fr => lang == 'fr';

  // ── Branding ───────────────────────────────────────────────────────────────
  String get tagline => _fr
      ? 'Votre voyage spirituel commence ici'
      : 'Your spiritual journey begins here';

  // ── Auth – login ────────────────────────────────────────────────────────────
  String get welcomeBack => _fr ? 'Bon retour' : 'Welcome Back';
  String get email => _fr ? 'E-mail' : 'Email';
  String get emailRequired => _fr ? "L'e-mail est requis" : 'Email is required';
  String get password => _fr ? 'Mot de passe' : 'Password';
  String get passwordRequired =>
      _fr ? 'Le mot de passe est requis' : 'Password is required';
  String get logIn => _fr ? 'Connexion' : 'Log In';
  String get noAccount => _fr ? 'Pas de compte ? ' : "Don't have an account? ";
  String get signUp => _fr ? "S'inscrire" : 'Sign Up';

  // ── Auth – register ─────────────────────────────────────────────────────────
  String get createAccount => _fr ? 'Créer un compte' : 'Create Account';
  String get joinCommunity => _fr
      ? 'Rejoignez notre communauté de chercheurs'
      : 'Join our community of seekers';
  String get customer => _fr ? 'Client' : 'Customer';
  String get professional => _fr ? 'Professionnel' : 'Professional';
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
  String get accountCreated => _fr
      ? 'Compte créé ! Veuillez vous connecter.'
      : 'Account created! Please log in.';
  String createAccountFailed(String err) => _fr
      ? 'Échec de la création du compte : $err'
      : 'Failed to create account: $err';
  String loginFailed(String err) =>
      _fr ? 'Échec de la connexion : $err' : 'Login failed: $err';
  String get alreadyHaveAccount =>
      _fr ? 'Vous avez déjà un compte ? ' : 'Already have an account? ';

  // ── Bottom nav tabs ─────────────────────────────────────────────────────────
  String get tabExplore => _fr ? 'Explorer' : 'Explore';
  String get tabChat => _fr ? 'Chat' : 'Chat';
  String get tabHistory => _fr ? 'Historique' : 'History';
  String get tabReviews => _fr ? 'Avis' : 'Reviews';
  String get tabProfile => _fr ? 'Profil' : 'Profile';
  String get tabHome => _fr ? 'Accueil' : 'Home';
  String get tabSlots => _fr ? 'Créneaux' : 'Slots';
  String get tabClients => _fr ? 'Clients' : 'Clients';

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
  String get notifications => _fr ? 'Notifications' : 'Notifications';
  String get managePreferences =>
      _fr ? 'Gérer les préférences' : 'Manage preferences';
  String get notificationSettingsComingSoon => _fr
      ? 'Paramètres de notification bientôt disponibles'
      : 'Notification Settings Coming Soon';
  String get paymentMethods => _fr ? 'Moyens de paiement' : 'Payment Methods';
  String get cardsBilling =>
      _fr ? 'Cartes et facturation' : 'Cards and billing';
  String get support => _fr ? 'Assistance' : 'Support';
  String get helpCenter => _fr ? "Centre d'aide" : 'Help Center';
  String get faqsGuides => _fr ? 'FAQ et guides' : 'FAQs and guides';
  String get sessionsLabel => _fr ? 'Sessions' : 'Sessions';
  String get totalTime => _fr ? 'Temps total' : 'Total Time';
  String get rating => _fr ? 'Note' : 'Rating';
  String get logout => _fr ? 'Se déconnecter' : 'Log Out';
  String get logoutConfirmTitle => _fr ? 'Se déconnecter ?' : 'Log out?';
  String get logoutConfirmMessage => _fr
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to log out?';

  // ── Explore / Professionals list ────────────────────────────────────────────
  String get explore => _fr ? 'Explorer' : 'Explore';
  String get unableLoadExplore =>
      _fr ? 'Impossible de charger les données' : 'Unable to load explore data';
  String get tryAgain => _fr ? 'Réessayer' : 'Try Again';
  String get noProfessionalsFound =>
      _fr ? 'Aucun professionnel trouvé' : 'No professionals found';
  String get searchAdvisor => _fr
      ? 'Rechercher un conseiller ou une spécialité'
      : 'Search advisor or specialty';
  String get all => _fr ? 'Tous' : 'All';
  String get online => _fr ? 'En ligne' : 'Online';
  String get offline => _fr ? 'Hors ligne' : 'Offline';
  String get recommended => _fr ? 'Recommandé' : 'Recommended';
  String get filters => _fr ? 'Filtres' : 'Filters';
  String get reset => _fr ? 'Réinitialiser' : 'Reset';
  String get specialty => _fr ? 'Spécialité' : 'Specialty';
  String get type => _fr ? 'Type' : 'Type';
  String get experience => _fr ? 'Expérience' : 'Experience';
  String get price => _fr ? 'Prix' : 'Price';
  String get language => _fr ? 'Langue' : 'Language';
  String get sessionType => _fr ? 'Type de session' : 'Session type';
  String get favoritesOnly => _fr ? 'Favoris seulement' : 'Favorites only';
  String get phone => _fr ? 'Téléphone' : 'Phone';
  String get video => _fr ? 'Vidéo' : 'Video';
  String get moreFilters => _fr ? 'Plus de filtres' : 'More Filters';
  String get filterSubtitle => _fr
      ? 'Spécialité, expérience, prix, type de session, langue'
      : 'Specialty, experience, price, session type, language';
  String get specialties => _fr ? 'Spécialités' : 'Specialties';
  String get pricingEurMin => _fr ? 'Prix (EUR/min)' : 'Price (EUR/min)';
  String get featuredAdvisors =>
      _fr ? 'Conseillers vedettes' : 'Featured Advisors';
  String get topProsReadyNow => _fr
      ? 'Les meilleurs professionnels en ligne disponibles'
      : 'Top online professionals ready now';
  String get noFeaturedAdvisors => _fr
      ? 'Aucun conseiller vedette pour les filtres actuels.'
      : 'No featured advisors for current filters.';
  String get allAdvisors => _fr ? 'Tous les conseillers' : 'All Advisors';
  String nResults(int n) => _fr ? '$n résultats' : '$n results';
  String get noAdvisorsMatch => _fr
      ? 'Aucun conseiller ne correspond à votre recherche.'
      : 'No advisors match your search right now.';
  String get discoverYourGuide =>
      _fr ? 'Découvrez votre guide' : 'Discover Your Guide';
  String nAdvisorsAvailable(int n) => _fr
      ? '$n conseillers disponibles pour chat et vidéo'
      : '$n advisors available for chat and video sessions';
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
  String get availableNow => _fr ? 'Disponible maintenant' : 'Available now';
  String get noAvailabilityAtMoment => _fr
      ? 'Aucune disponibilité pour le moment'
      : 'No availability at the moment';
  String get bookSession => _fr ? 'Réserver une session' : 'Book Session';
  String get availableServices =>
      _fr ? 'Services disponibles' : 'Available Services';
  String get about => _fr ? 'À propos' : 'About';
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
  String failedAddSlot(String err) =>
      _fr ? "Échec de l'ajout du créneau : $err" : 'Failed to add slot: $err';
  String get failedLoadAvailability => _fr
      ? 'Impossible de charger les disponibilités'
      : 'Failed to load availability';
  String get retry => _fr ? 'Réessayer' : 'Retry';
  String get noSlotsYet => _fr ? 'Aucun créneau ajouté' : 'No slots added yet';
  String get tapAddSlot => _fr
      ? 'Appuyez sur "Ajouter un créneau" pour définir vos disponibilités.'
      : 'Tap "Add Slot" to set your availability.';
  String get refresh => _fr ? 'Actualiser' : 'Refresh';

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
  String get reviews => _fr ? 'Avis' : 'Reviews';
  String get myReviews => _fr ? 'Mes avis' : 'My Reviews';
  String get failedLoadReviews =>
      _fr ? 'Impossible de charger les avis' : 'Failed to load reviews';
  String get noReviewsFound => _fr ? 'Aucun avis trouvé' : 'No reviews found';
  String get noReviewsYet =>
      _fr ? 'Aucun avis pour le moment' : 'No reviews yet';
  String get beFirstToReview => _fr
      ? 'Soyez le premier à laisser un avis !'
      : 'Be the first to leave a review!';
  String get writeReview => _fr ? 'Écrire un avis' : 'Write a review';
  String get submitReview => _fr ? 'Soumettre un avis' : 'Submit review';
  String get yourRating => _fr ? 'Votre note' : 'Your rating';
  String get yourComment => _fr ? 'Votre commentaire' : 'Your comment';
  String get reviewTargetCoidHint =>
      _fr ? 'ID du professionnel (optionnel)' : 'Professional ID (optional)';
  String get reviewSessionIdHint =>
      _fr ? 'ID de session (optionnel)' : 'Session ID (optional)';
  String get ratingRequired =>
      _fr ? 'La note est requise' : 'Rating is required';
  String get reviewSubmitted =>
      _fr ? 'Avis soumis avec succès' : 'Review submitted successfully';
  String reviewSubmitFailed(String err) => _fr
      ? 'Échec de l\'envoi de l\'avis : $err'
      : 'Failed to submit review: $err';
  String nReviews(int count) => _fr ? '$count avis' : '$count reviews';
  String get reviewsFromClientsWillAppear => _fr
      ? 'Les avis de vos clients\napparaîtront ici'
      : 'Reviews from your clients\nwill appear here';
  String get reviewsFromConsultationsWillAppear => _fr
      ? 'Les avis de vos consultations\napparaîtront ici'
      : 'Reviews from your consultations\nwill appear here';
  String get anonymous => _fr ? 'Anonyme' : 'Anonymous';

  // ── History ──────────────────────────────────────────────────────────────────
  String get sessionHistory =>
      _fr ? 'Historique des sessions' : 'Session History';
  String get pastConsultations =>
      _fr ? 'Vos consultations passées' : 'Your past consultations';
  String get failedLoadHistory =>
      _fr ? "Impossible de charger l'historique" : 'Failed to load history';
  String get noSessionsFound =>
      _fr ? 'Aucune session trouvée' : 'No sessions found';
  String get completed => _fr ? 'Terminé' : 'Completed';
  String get cancelled => _fr ? 'Annulé' : 'Cancelled';
  String get pending => _fr ? 'En attente' : 'Pending';
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
  String get messages => _fr ? 'Messages' : 'Messages';
  String get searchConversations =>
      _fr ? 'Rechercher des conversations...' : 'Search conversations...';
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
  String get typeMessage => _fr ? 'Écrire un message...' : 'Type a message...';
  String get send => _fr ? 'Envoyer' : 'Send';
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

  // ── Language selector ────────────────────────────────────────────────────────
  String get selectLanguage => _fr ? 'Choisir la langue' : 'Select Language';
  String get english => _fr ? 'Anglais' : 'English';
  String get french => _fr ? 'Français' : 'French';

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
}
