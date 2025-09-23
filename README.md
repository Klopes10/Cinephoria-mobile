# 🎬 Cinéphoria Desktop & Mobile – Application bureautique / mobile

Bienvenue dans le dépôt **Cinéphoria-mobile**, qui contient à la fois les applications **mobile** et **desktop** du projet Cinéphoria.  
La partie desktop est destiné aux **employés du cinéma** pour la **gestion des incidents techniques** dans les salles de projection, tandis que la partie mobile permet à un utilisateur de voir ses prochaines séances et d'utiliser le QRcode pour accéder à sa salle de cinéma.

---

## 🖥️ Fonctionnalités du module Desktop

- Connexion sécurisée via identifiants employés  
- Tableau de suivi des incidents par salle  
- Ajout d’un incident   
- Filtrage des salles par cinéma

L’application desktop & mobile utilisent la même base de données (backend) que l'application web déployé de Cinéphoria.

---

## 📂 Chemin du dépôt

Le code est dans ce repository GitHub :  
[Klopes10 / Cinephoria-mobile](https://github.com/Klopes10/Cinephoria-mobile/tree/master) 

La structure comprend notamment deux dossiers :

- `cinephoria_desktop` → le code de l’application desktop  
- `cinephoria_mobile` → le code de l’application mobile

## 📥 Téléchargement & Installation (Windows – Desktop)

### ✅ Prérequis

- Windows 10 ou supérieur  
- Aucune installation de Flutter n’est nécessaire : le moteur est inclus dans l’exécutable généré

### 🔗 Lien de téléchargement

➡️ [Télécharger l'application Cinéphoria Desktop (Windows)](https://github.com/Klopes10/Cinephoria-mobile/releases/tag/v1.0.0-desktop)

---

### 🧾 Étapes d’installation (Desktop)

1. Téléchargez le fichier **`CinephoriaDesktop-windows-x64-1.0.0.zip`** depuis la section *Releases*.  
2. **Extrayez** le fichier ZIP dans le dossier de votre choix.  
3. Double-cliquez sur **`CinephoriaDesktop.exe`** pour lancer l'application.  

L’application démarre automatiquement : connectez-vous avec vos **identifiants employés**.

---
## 📱 Installation & utilisation (Mobile)

### ✅ Prérequis

- Android 8.0 ou supérieur (APK fourni)  
- iOS (bientôt disponible)  

### 🔗 Lien de téléchargement

➡️ [Télécharger l'application Cinéphoria Mobile (APK Android)]((https://github.com/Klopes10/Cinephoria-mobile/releases/tag/v1.0.0-mobile))  

### 🧾 Étapes d’installation (Mobile)

1. Téléchargez le fichier **`.apk`** sur votre smartphone Android.  
2. Autorisez l’installation d’applications issues de sources externes si nécessaire.  
3. Lancez l’application et connectez-vous avec vos identifiants.  

---

## 🧑‍💼 Accès & Authentification

- **Employés (Desktop)** : se connectent avec leurs identifiants fournis par l’administration du cinéma.  
- **Utilisateurs (Mobile)** : se connectent avec leur compte utilisateur Cinéphoria (identique à l’espace web).  
- 🔑 En cas de perte de mot de passe, la réinitialisation se fait depuis le site web.  

---

## 📁 Structure du dépôt

Ce dépôt contient :  

- `cinephoria_desktop/` → application bureau (Flutter Desktop – Windows)  
- `cinephoria_mobile/` → application mobile (Flutter Mobile – Android/iOS)  
- `README.md` → documentation du projet  
- Fichiers de configuration Flutter et build  

---

## 🛠️ Technologies utilisées

- **Flutter (Dart)** – développement multiplateforme  
- **Flutter Desktop** (Windows)  
- **Flutter Mobile** (Android / iOS)  
- **PostgreSQL** – base de données partagée  
- **BCrypt** – hashage des mots de passe

- ---

## 📌 Projet global Cinéphoria

Ce dépôt s’intègre dans l’écosystème **Cinéphoria**, qui comprend :  

- 🌐 **Application Web** : Symfony + PostgreSQL + MongoDB (dashboard statistiques) + Docker  
- 📱 **Application Mobile** : Flutter (Android/iOS)  
- 🖥️ **Application Desktop** : Flutter Desktop (Windows)  

---
