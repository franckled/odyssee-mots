/// Achats intégrés (abonnement mensuel) via RevenueCat.
/// Sur le web, une version vide est utilisée : l'abonnement se prend
/// dans l'application iPhone ou Android.
export 'billing_stub.dart' if (dart.library.io) 'billing_native.dart';
