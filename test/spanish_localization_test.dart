import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/l10n/app_translations.dart';

/// Spanish was added after French and English, and most of the string table
/// used a two-way `_fr ? .. : ..` ternary that silently served English to
/// Spanish users. These tests pin a sample from every section of the app so
/// that regression cannot come back unnoticed.
void main() {
  const fr = AppTranslations('fr');
  const en = AppTranslations('en');
  const es = AppTranslations('es');

  test('auth and registration', () {
    expect(es.sendResetLink, 'Enviar enlace');
    expect(es.backToLogin, 'Volver al inicio de sesión');
    expect(es.firstName, 'Nombre');
    expect(es.lastName, 'Apellidos');
    expect(es.dateOfBirth, 'Fecha de nacimiento');
    expect(es.country, 'País');
    expect(es.confirmPassword, 'Confirmar contraseña');
    expect(es.passwordsNoMatch, 'Las contraseñas no coinciden');
    expect(es.acceptCgu, 'Acepto las Condiciones Generales de Uso (CGU)');
    expect(es.alreadyHaveAccount, '¿Ya tienes una cuenta? ');
    expect(es.countryList, contains('Estados Unidos'));
    expect(es.countryList, contains('Reino Unido'));
    expect(fr.countryList, contains('États-Unis'));
    expect(en.countryList, contains('United States'));
  });

  test('dashboard, profile and settings', () {
    expect(es.dashboard, 'Panel de control');
    expect(es.welcomeBackName('Ana'), 'Bienvenido de nuevo, Ana');
    expect(es.settings, 'Ajustes');
    expect(es.logout, 'Cerrar sesión');
    expect(es.logoutConfirmMessage, '¿Seguro que quieres cerrar sesión?');
    expect(es.termsOfUse, 'Condiciones de uso (CGU)');
    expect(es.legalNotice, 'Aviso legal');
  });

  test('explore and filters', () {
    expect(es.filters, 'Filtros');
    expect(es.specialty, 'Especialidad');
    expect(es.experience, 'Experiencia');
    expect(es.price, 'Precio');
    expect(es.language, 'Idioma');
    expect(es.specialtyFilterLabel('Tarot'), 'Especialidad: Tarot');
  });

  test('availability, slots and weekdays', () {
    expect(es.monday, 'Lunes');
    expect(es.sunday, 'Domingo');
    expect(es.days, hasLength(7));
    expect(es.addSlot, 'Añadir horario');
    expect(es.slotsCountFor(1), '1 horario');
    expect(es.slotsCountFor(3), '3 horarios');
    expect(fr.slotsCountFor(3), '3 créneaux');
    expect(en.slotsCountFor(3), '3 slots');
  });

  test('sessions, calls and status messages', () {
    expect(es.phoneCall, 'Llamada telefónica');
    expect(es.videoCall, 'Videollamada');
    expect(es.endSession, 'Finalizar sesión');
    expect(es.sessionStatusInProgressLabel, 'En curso');
    expect(
      es.sessionStatusInProgressMessage(isProfessional: true),
      'La sesión está activa. Estás en consulta con tu cliente.',
    );
    expect(
      es.sessionStatusInProgressMessage(isProfessional: false),
      'La sesión está activa. Estás en consulta con tu profesional.',
    );
    expect(
      es.waitingForJoinTitle(isProfessional: true),
      'Esperando a que se una el cliente',
    );
    expect(es.sessionStatusUnknownLabel(''), 'Desconocido');
    expect(es.sessionStatusUnknownLabel('weird'), 'weird');
    expect(es.sessionStatusChangedMessage(''), contains('desconocido'));
    expect(es.mute, 'Silenciar');
    expect(es.camera, 'Cámara');
  });

  test('wallet, pricing and Stripe onboarding', () {
    expect(es.processingPayment, 'Procesando el pago...');
    expect(es.transactionHistory, 'Historial de transacciones');
    expect(es.youPay, 'Pagas');
    expect(es.youReceive, 'Recibes');
    expect(es.promoApplied('X', '10'), 'Código X aplicado: 10%');
    expect(es.stripeAccount, 'Cuenta de Stripe');
    expect(es.setUpPayments, 'Configurar los pagos');
  });

  test('appointments and booking', () {
    expect(es.bookAppointment, 'Reservar cita');
    expect(es.availableSlots, 'Horarios disponibles');
    expect(es.confirmBooking, 'Confirmar la reserva');
    expect(es.alreadyRegistered, 'Ya estás inscrito en esta sesión.');
  });

  test('shared labels added for previously hardcoded strings', () {
    expect(es.pleaseTryAgain, 'Inténtalo de nuevo.');
    expect(es.genericErrorRetry, 'Se ha producido un error. Inténtalo de nuevo.');
    expect(es.decline, 'Rechazar');
    expect(es.start, 'Iniciar');
    expect(es.preparingExperience, 'Preparando tu experiencia');
    expect(es.paymentUnavailable, contains('El pago'));
    expect(es.spanish, 'Español');
    expect(fr.spanish, 'Espagnol');
    expect(en.spanish, 'Spanish');
  });

  test('Spanish never silently reuses the English string', () {
    // A representative sweep of entries that used to fall back to English.
    final es3 = <String, String>{
      'firstName': es.firstName,
      'settings': es.settings,
      'filters': es.filters,
      'monday': es.monday,
      'endSession': es.endSession,
      'youPay': es.youPay,
      'bookAppointment': es.bookAppointment,
      'decline': es.decline,
    };
    final en3 = <String, String>{
      'firstName': en.firstName,
      'settings': en.settings,
      'filters': en.filters,
      'monday': en.monday,
      'endSession': en.endSession,
      'youPay': en.youPay,
      'bookAppointment': en.bookAppointment,
      'decline': en.decline,
    };
    for (final key in es3.keys) {
      expect(
        es3[key],
        isNot(equals(en3[key])),
        reason: '"$key" is still falling back to English',
      );
    }
  });

  test('screen strings found in the second sweep', () {
    expect(es.allMessages, 'Todos los mensajes');
    expect(es.pinned, 'Fijados');
    expect(es.open, 'Abrir');
    expect(es.dismiss, 'Descartar');
    expect(es.newChatSessionFrom('Ana'), 'Nueva sesión de chat de Ana');
    expect(es.splashTagline, 'Sesiones en directo y orientación experta');
    expect(es.pleaseTryAgainLater, 'Inténtalo de nuevo más tarde.');
    expect(es.couldNotLoadHistory, startsWith('No se pudo cargar tu historial'));
    expect(es.acceptTermsNotice, startsWith('Al continuar'));
  });

  test('incoming-call title localises the session type too', () {
    expect(es.incomingCallTitle('video'), 'Llamada de vídeo entrante');
    expect(es.incomingCallTitle('phone'), 'Llamada telefónica entrante');
    expect(es.incomingCallTitle('chat'), 'Llamada de chat entrante');
    expect(fr.incomingCallTitle('video'), 'Appel vidéo entrant');
    expect(en.incomingCallTitle('phone'), 'Incoming phone call');
    // The raw backend type must never leak into the UI string.
    expect(es.incomingCallTitle('video'), isNot(contains('video')));
  });
}
