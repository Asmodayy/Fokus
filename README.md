# Fokus

Instagram, Facebook, YouTube et TikTok sans Reels, Shorts ni scroll infini, avec un timer sur TikTok : 20 min toutes les 3 h par défaut, modifiable dans les Réglages.

---

## Étape 1 — Mettre le code sur GitHub (sur le PC, 10 min)

1. Crée un compte gratuit sur **github.com**.
2. En haut à droite, clique **+ → New repository**.
   - Nom : `fokus`
   - Coche **Public** (plus simple pour télécharger l'appli depuis l'iPhone)
   - Ne coche rien d'autre, puis clique **Create repository**.
3. Dézippe `fokus.zip` sur le PC.
4. Sur la page du dépôt, clique le lien **uploading an existing file**.
5. Ouvre le dossier `fokus` dézippé, sélectionne **tout son contenu** (y compris le dossier `.github`) et glisse-le dans la page.
6. Clique **Commit changes**.

## Étape 2 — Laisser GitHub fabriquer l'appli (5 à 10 min)

1. Va dans l'onglet **Actions** du dépôt. Si GitHub le demande, clique **I understand… enable them**.
2. Le build « Build Fokus » démarre tout seul. S'il ne démarre pas, clique dessus puis **Run workflow**.
3. Une coche verte ✅ veut dire que c'est fini. Le fichier **Fokus.ipa** apparaît alors dans **Releases**, sur la page d'accueil du dépôt, à droite.

Si tu vois une croix rouge ❌, ouvre le build, copie le message d'erreur et envoie-le à Claude.

## Étape 3 — Installer SideStore (une seule fois, PC + iPhone, 20 min)

**Sur l'iPhone**
1. Installe **LocalDevVPN** depuis l'App Store.

**Sur le PC**
2. Installe **iTunes** depuis le site d'Apple (apple.com/fr/itunes), pas depuis le Microsoft Store.
3. Télécharge et installe **iloader** depuis **iloader.app** (ou github.com/nab138/iloader, ce sont les seules sources officielles).
4. Branche l'iPhone en USB. Sur l'iPhone, touche **Se fier à cet ordinateur**.
5. Ouvre iloader, connecte-toi avec ton **Apple ID** (un compte gratuit suffit), puis choisis **Install SideStore**.

**Sur l'iPhone**
6. Va dans **Réglages → Général → VPN et gestion de l'appareil**, touche ton Apple ID, puis **Faire confiance**.
7. Va dans **Réglages → Confidentialité et sécurité → Mode développeur**, active-le et redémarre.
8. Ouvre **LocalDevVPN** et active-le.
9. Ouvre **SideStore** et connecte-toi avec le **même Apple ID**.

Ensuite tu n'as plus besoin du PC, sauf si tu réinitialises l'iPhone ou si une mise à jour d'iOS casse l'appairage.

## Étape 4 — Installer Fokus (sur l'iPhone)

1. Dans Safari, va sur `github.com/TON-PSEUDO/fokus/releases/latest` et touche **Fokus.ipa** pour le télécharger.
2. Active **LocalDevVPN**.
3. Ouvre **SideStore → My Apps → +** et choisis **Fokus.ipa** dans « Téléchargements ».
4. Fokus apparaît sur l'écran d'accueil.

## Étape 5 — Les bons réflexes

- **Tous les 5 jours environ** : active LocalDevVPN, ouvre SideStore et touche **Refresh All**. Avec un Apple ID gratuit, l'appli expire au bout de 7 jours sans refresh.
- **Supprime les applis officielles** Instagram, TikTok, Facebook et YouTube. Sinon il suffit de les ouvrir pour contourner Fokus.
- Connecte-toi à tes comptes une fois dans chaque onglet de Fokus. Tu restes connecté ensuite.

---

## Ce que fait Fokus

| Réseau | Filtres (activables dans Réglages) |
|---|---|
| Instagram | Reels, Explorer, publications suggérées et sponsorisées. Les messages, profils et stories restent accessibles. |
| Facebook | Reels et vidéos, suggestions et pubs |
| YouTube | Shorts (un Short envoyé par un ami s'ouvre comme une vidéo normale, sans scroll), vidéos suggérées, fil d'accueil (désactivé par défaut) |
| TikTok | Bandeaux « Ouvrir l'appli » + **timer** |

**Le timer**
- Il ne compte que quand l'onglet est à l'écran et l'appli ouverte.
- La tranche démarre à ta première utilisation. Quand les 20 min sont écoulées, TikTok se verrouille jusqu'à la fin des 3 h.
- Tu peux l'activer sur n'importe quel réseau. Pendant un verrouillage, la limite ne peut pas être modifiée.
- Si tu supprimes et réinstalles l'appli, le compteur repart à zéro : c'est un garde-fou, pas une prison.

**Limites**
- Les sites modifient souvent leur code. Si un Reel ou un Short réapparaît, les sélecteurs à ajuster sont dans `Fokus/FilterScripts.swift`.
- Il n'y a pas de notifications push, comme sur la version web.

## Mettre à jour l'appli

Remplace le fichier modifié sur GitHub : ouvre-le, clique le crayon ✏️ ou **Add file → Upload files**, puis **Commit**. Un nouveau build démarre tout seul. Installe ensuite le nouveau Fokus.ipa avec SideStore, comme à l'étape 4. Tes connexions et réglages sont conservés.
