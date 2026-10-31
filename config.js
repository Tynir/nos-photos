// =====================================================================
//  Configuration de l'appli « Nos photos »
//  Colle ici les valeurs de tes projets Supabase
//  (Project Settings → API Keys). Voir le guide, étapes 4 et 7.
//  Tant que le projet principal est vide, l'appli tourne en mode démo.
// =====================================================================
window.APP_CONFIG = {
  appName: 'Nos photos',

  // ---- Projet principal (connexion, albums, 1er Go de photos) ----
  // Ex. : 'https://abcdefghijkl.supabase.co'
  supabaseUrl: 'https://euvlhyjeoacdzxkfobnk.supabase.co',
  // La clé publique (« anon » ou « publishable »). Elle peut être visible :
  // ce sont les règles de sécurité de la base qui protègent vos photos.
  // Ne mets JAMAIS ici la clé « service_role » ou « secret ».
  supabaseAnonKey: 'sb_publishable_ZFtfDeIyyhSE1m2Xm7kFxQ_ZR-SPQqw',

  // ---- 2e projet : 1 Go de plus pour les photos (optionnel) ----
  // L'appli remplit d'abord le projet principal, puis passe à celui-ci.
  // Laisse les deux champs vides si tu n'en as pas encore besoin.
  extraStorage: [
    { supabaseUrl: '', supabaseAnonKey: '' },
  ],
};
