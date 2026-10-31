# Nos photos

Album photo partagé entre un iPhone et un Android. C'est une web app installable (PWA) :
pas d'App Store, pas de Play Store, la même appli sur les deux téléphones.

- **Stockage** : Supabase, offre gratuite, sans carte bancaire. Deux projets de 1 Go chacun, soit 2 Go au total.
- **Hébergement** : GitHub Pages (gratuit, sans carte)
- **Photos compressées à l'envoi** : 1600 px max, JPEG qualité 75 %, environ 250 Ko par photo miniature comprise (une photo de 3 Mo devient ~250 Ko)
- **Temps réel** : quand l'un ajoute une photo, elle apparaît chez l'autre

Tant que `config.js` est vide, l'appli tourne en **mode démo** (tout en mémoire, rien n'est envoyé).

---

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `index.html` | L'appli entière (interface + logique) |
| `config.js` | **Le seul fichier à modifier** : les adresses et clés de tes deux projets Supabase |
| `schema.sql` | Le script du **projet principal** : base, stockage et règles de sécurité |
| `schema-stockage.sql` | Le script du **2e projet** : seulement le stockage et ses règles |
| `manifest.json`, `sw.js`, `icons/` | Ce qui permet d'installer l'appli sur l'écran d'accueil |
| `.github/workflows/garder-actif.yml` | Optionnel : évite la mise en pause des projets Supabase |

---

## Installation (environ 30 minutes)

Tu peux faire les étapes 1 à 6 d'abord, utiliser l'appli avec 1 Go, et ajouter le 2e projet (étape 7) plus tard.

### 1. Créer le projet Supabase

1. Va sur [supabase.com](https://supabase.com) et crée un compte (tu peux te connecter avec GitHub).
2. **New project**. Donne un nom (`nos-photos`), un mot de passe de base de données (note-le quelque part),
   et choisis une région en Europe (Paris si elle est proposée).
3. Attends une à deux minutes que le projet soit prêt.

### 2. Créer la base et le stockage

1. Menu de gauche : **SQL Editor** → **New query**.
2. Colle tout le contenu de `schema.sql` et clique **Run**.
3. Tu dois voir « Success. No rows returned ».

### 3. Créer vos deux comptes

1. **Authentication** → **Users** → **Add user** → **Create new user**.
2. Mets ton e-mail et un mot de passe, et coche **Auto Confirm User**. Recommence pour ta copine.
3. **Authentication** → **Sign In / Providers** (ou **Settings** selon la version) :
   désactive **Allow new users to sign up**. Personne d'autre ne pourra créer de compte.
4. Retourne dans **SQL Editor** et exécute ces deux lignes avec vos vrais e-mails et prénoms :

   ```sql
   insert into public.members (user_id, display_name)
   select id, 'Ton prénom' from auth.users where email = 'toi@exemple.fr';

   insert into public.members (user_id, display_name)
   select id, 'Son prénom' from auth.users where email = 'elle@exemple.fr';
   ```

   C'est cette table qui donne l'accès. Même si quelqu'un réussissait à se créer un compte,
   il ne verrait rien.

### 4. Brancher l'appli sur Supabase

1. **Project Settings** → **API Keys** (ou **Data API** / **API** selon la version).
2. Copie l'**URL du projet** (`https://xxxx.supabase.co`) et la **clé publique**
   (appelée `anon` ou `publishable`). Si tu ne trouves que des clés `sb_publishable_…`,
   l'onglet **Legacy API keys** contient aussi la clé `anon` : les deux marchent.
3. Ouvre `config.js` et colle-les :

   ```js
   supabaseUrl: 'https://xxxx.supabase.co',
   supabaseAnonKey: 'eyJhbGciOi…',
   ```

> ⚠️ N'utilise **jamais** la clé `service_role` / `secret` dans `config.js` : elle contourne toute la sécurité.
> La clé publique, elle, peut être vue sans risque : ce sont les règles du `schema.sql` qui protègent vos photos.

### 5. Mettre l'appli en ligne avec GitHub Pages

1. Crée un compte sur [github.com](https://github.com) si tu n'en as pas.
2. **New repository** → nom `nos-photos` → **Public** (GitHub Pages gratuit demande un dépôt public ;
   seul le code est public, pas vos photos).
3. **Add file** → **Upload files** → glisse tout le contenu du dossier (y compris le dossier `icons`) → **Commit**.
   Le dossier `.github` est caché sur Mac et Windows : pour éviter la mise en pause (étape 8),
   ajoute-le ensuite via **Add file → Create new file** en tapant `.github/workflows/garder-actif.yml`
   comme nom, et colle son contenu.
4. **Settings** → **Pages** → Source : **Deploy from a branch**, branche `main`, dossier `/ (root)` → **Save**.
5. Au bout d'une minute, l'adresse s'affiche : `https://ton-pseudo.github.io/nos-photos/`.

### 6. Installer l'appli sur les téléphones

- **iPhone** : ouvre l'adresse dans **Safari** → bouton **Partager** → **Sur l'écran d'accueil**.
- **Android (Samsung)** : ouvre l'adresse dans **Chrome** → menu **⋮** → **Ajouter à l'écran d'accueil** / **Installer l'application**.

Connecte-toi avec l'e-mail et le mot de passe créés à l'étape 3. La session reste ouverte.

### 7. Ajouter le 2e Go (deuxième projet Supabase)

L'offre gratuite autorise 2 projets par compte. Le 2e sert uniquement à stocker des photos :
l'appli remplit d'abord le projet principal, puis range automatiquement les nouvelles photos dans le 2e.
Pour vous, rien ne change : tout s'affiche dans les mêmes albums.

1. Sur supabase.com, **New project** (par exemple `nos-photos-2`), même région que le premier.
2. **SQL Editor** → colle tout `schema-stockage.sql` → **Run**.
3. **Authentication** → **Users** : crée **les mêmes deux comptes, avec exactement les mêmes e-mails et les mêmes mots de passe**
   que dans le projet principal (coche **Auto Confirm User**). Désactive aussi **Allow new users to sign up**.
4. **SQL Editor** : exécute les deux lignes `insert into public.members…` en bas de `schema-stockage.sql`, avec vos e-mails.
5. Récupère l'URL et la clé publique de ce 2e projet, et colle-les dans `config.js`, dans `extraStorage` :

   ```js
   extraStorage: [
     { supabaseUrl: 'https://yyyy.supabase.co', supabaseAnonKey: 'eyJhbGciOi…' },
   ],
   ```

6. Remplace `config.js` dans le dépôt GitHub. Au prochain lancement, l'appli redemande le mot de passe une fois
   (pour se connecter aux deux projets), puis la jauge affiche « / 2 Go ».

> Si tu changes un jour un mot de passe, change-le dans **les deux** projets, sinon la connexion sera refusée.
> Et ne retire jamais le 2e projet de `config.js` une fois qu'il contient des photos : elles ne s'afficheraient plus.

### 8. (Optionnel) Éviter la mise en pause

Un projet Supabase gratuit se met en pause après 7 jours sans activité. Les données restent,
mais il faut le relancer à la main depuis le tableau de bord (bouton **Restore project**).

Pour l'éviter, le fichier `.github/workflows/garder-actif.yml` fait une petite requête tous les 3 jours :

1. Dans ton dépôt GitHub : **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. Ajoute `SUPABASE_URL` et `SUPABASE_ANON_KEY` (projet principal),
   puis `SUPABASE2_URL` et `SUPABASE2_ANON_KEY` (2e projet, si tu l'as créé).
3. Onglet **Actions** → **Garder Supabase actif** → **Run workflow** pour tester une première fois.

GitHub désactive les tâches planifiées d'un dépôt resté 60 jours sans modification :
il recevra un e-mail, il suffit alors de cliquer **Enable workflow**.

---

## Bon à savoir

- **Capacité** : environ 4 000 photos par Go, donc 8 000 avec les deux projets. La jauge en haut de l'accueil
  indique où vous en êtes. Quand tout est plein, l'appli le dit et arrête l'envoi.
- **Qualité** : les photos sont réduites à 1600 px. C'est net sur un téléphone,
  mais ce n'est pas une sauvegarde des originaux. Pour changer, modifie `maxSide` et `quality` dans `index.html`
  (2048 et 0.82 donnent ~450 Ko par photo, soit deux fois moins de place).
- **Photos HEIC de l'iPhone** : Safari les convertit automatiquement en JPEG à l'envoi.
- **Enregistrer une photo** : le bouton **Enregistrer** ouvre le menu de partage du téléphone
  (« Enregistrer l'image » sur iPhone, « Enregistrer » ou galerie sur Android).
- **Mettre à jour l'appli** : remplace `index.html` dans le dépôt GitHub. Les téléphones prennent la nouvelle version
  à la prochaine ouverture (parfois la suivante).
