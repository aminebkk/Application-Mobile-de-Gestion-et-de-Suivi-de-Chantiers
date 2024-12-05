# Projet Mobile avec Flutter et Appwrite

## Description
Cette application mobile est un outil de gestion de chantiers pour deux types d'utilisateurs :
1. **Responsable de Chantier**
2. **Chef de Chantier**
3. **Equipier**

Chaque utilisateur dispose d'un tableau de bord personnalisé pour gérer les tâches qui lui sont attribuées.

## Fonctionnalités

### Responsable de Chantier
- **Gestion des Chantiers :**
    - Créer et visualiser les chantiers.
    - Consulter les détails de chaque chantier : nom, localisation, date de début et de fin, etc.
    - Voir la localisation des chantiers sur une carte à l'aide de **Fleaflet**.
    - Choisir si le chantier a lieu le matin ou le soir.
    - Assigner un Chef de Chantier parmi ceux disponibles pour travailler le matin ou le soir, selon le critère choisi.
    - **Voir les rapports** des chantiers.

- **Gestion des Ressources :**
    - **Matériaux :**
        - Créer des matériaux et les affecter aux chantiers.
    - **Véhicules :**
        - Ajouter des véhicules et les associer à des chantiers.
    - **Personnels :**
        - Former des groupes de personnels (un seul groupe par chantier).
        - Assigner un groupe de personnels à un chantier.

### Chef de Chantier
- **Visualisation des Chantiers :**
    - Accéder uniquement aux chantiers qui lui ont été assignés par le Responsable de Chantier.
    - Voir la localisation des chantiers sur une carte à l'aide de **Fleaflet**.

- **Mise à jour du Statut :**
    - Modifier le statut des chantiers (par exemple : en cours, terminé).

- **Gestion des Rapports :**
    - Créer des rapports pour chaque chantier.
    - Consulter les rapports liés aux chantiers.

### Equipier
- **Visualisation des Chantiers :**
    - Voir les chantiers qui lui sont affectés par le chef de Chantier.
    - Voir la localisation des chantiers sur une carte à l'aide de **Fleaflet**.
    - **Choisir** s'il aime un chantier en cochant une case.

## Structure des Collections dans Appwrite

### Collections
1. **Chantiers :**
    - Attributs :
        - Nom
        - Localisation
        - Date de début
        - Date de fin
        - Statut
        - Chef de Chantier assigné
        - **MatérielId :** Liste de chaînes de caractères contenant les identifiants des matériaux associés.
        - **VéhiculeId :** Liste de chaînes de caractères contenant les identifiants des véhicules associés.
        - **PersonnelId :** Chaîne de caractères contenant l'identifiant du groupe de personnels associé.
        - **Période :** Matin ou Soir.
        - **IP :** Adresse IP pour récupérer la localisation via [ipstack](https://ipstack.com/).

2. **Matériaux :**
    - Attributs :
        - Nom
        - Quantité
        - **Période :** Matin ou Soir.

3. **Véhicules :**
    - Attributs :
        - Modèle
        - Immatriculation
        - **Période :** Matin ou Soir.

4. **Personnels :**
    - Attributs :
        - Nom du groupe
        - Nombre de personnes
        - **Période :** Matin ou Soir.

5. **Rapports :**
    - Attributs :
        - Titre
        - Description
        - Date de création
        - Chantier associé
        - **Image :** Photo associée au rapport (par exemple : progression ou problème identifié).

## Technologies Utilisées
- **Flutter :** Framework utilisé pour développer l'application mobile.
- **Appwrite :** Plateforme backend pour la gestion des collections et des utilisateurs.
- **Fleaflet :** Utilisé pour afficher les cartes et localiser les chantiers.
- **ipstack :** API utilisée pour récupérer l'adresse IP et obtenir des informations géographiques (localisation) des chantiers.

## Installation et Démarrage
1. **Prérequis :**
    - Installer Flutter ([documentation officielle](https://flutter.dev/docs/get-started)).
    - Configurer un serveur Appwrite ([documentation officielle](https://appwrite.io/docs)).
    - Créer un compte sur [ipstack](https://ipstack.com/) pour obtenir une clé API.

2. **Installation :**
    - Cloner ce dépôt :
      ```bash
      git clone <URL_DU_DEPOT>
      ```
    - Naviguer dans le dossier du projet :
      ```bash
      cd <NOM_DU_PROJET>
      ```
    - Installer les dépendances Flutter :
      ```bash
      flutter pub get
      ```

3. **Configuration :**
    - Ajouter les paramètres de votre serveur Appwrite dans le fichier de configuration du projet.
    - Configurer l'API ipstack en ajoutant votre clé API.

4. **Exécution :**
    - Lancer l'application en mode développement :
      ```bash
      flutter run
      ```

## Contributions
Les contributions sont les bienvenues. Veuillez soumettre une pull request ou ouvrir une issue pour discuter des modifications.

## Licence
Ce projet est sous licence MIT. Consultez le fichier `LICENSE` pour plus de détails.
