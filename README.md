# 1- HelloWorld Spring Boot + Kubernetes

Ce projet a été monté pour répondre à une consigne : créer une application Spring Boot, la builder, la tester, l'encapsuler dans un conteneur Docker, puis la déployer dans un cluster Kubernetes (via Minikube). Voici comment je m’y suis pris, étape par étape.

---

##  Objectif

Développer une API REST très simple, la conteneuriser, puis la déployer en local via Minikube. Le but est de voir le flux complet d’un déploiement Java vers Kubernetes.

---

## ⚙️ Outils utilisés

- Java 17
- Spring Boot 3.5.0
- Maven
- Docker (installé sur ma VM Debian)

##  Étapes principales

## 1. Création du projet

J’ai utilisé le site [https://start.spring.io](https://start.spring.io) pour générer l’appli.  
Voilà les infos :

- Group : `com.infoline`
- Artifact : `helloworld`
- Dépendance : `Spring Web`
- Java : 17

Ensuite j’ai ajouté un petit contrôleur dans le dossier `src/main/java/com/infoline/helloworld` :

```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello, World!";
    }
}
```

J’ai lancé avec Maven :

```bash
./mvnw spring-boot:run
```

Et bim, dans mon navigateur j’ai testé `http://localhost:8080/hello`  
Et ça affiche : **Hello, World!**

---

## 2. Dockerisation de l’application

Ensuite j’ai voulu faire tourner tout ça dans Docker (bah ouais, DevOps oblige 😅).

### Mon Dockerfile :

```Dockerfile
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Commandes utilisées :

```bash
docker build -t helloworld-app .
docker run -p 8080:8080 helloworld-app
```

Et là encore, même résultat, l’appli est bien accessible sur :  
[http://localhost:8080/hello](http://localhost:8080/hello)

---

### 1.  Compilation avec Maven

Commande utilisée :
```bash
mvn clean package -DskipTests
```
Pourquoi `-DskipTests` ? Parce que les tests unitaires n’étaient pas nécessaires pour cette démo, et ça accélère le processus.

---

### 2. Dockerisation

Voici le contenu du `Dockerfile` :
```Dockerfile
FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY target/helloworld-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Et la commande pour construire l’image :
```bash
docker build -t helloworld-app .
```

---

### 3. Déploiement avec Minikube

Lancement de Minikube (avec un peu moins de mémoire à cause de la VM) :
```bash
minikube start --memory=1700mb
```

Déploiement des fichiers :
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Ouverture de l’URL dans le navigateur :
```bash
minikube service helloworld-service
```

---

## Arborescence du projet

```
helloworld/
├── src/main/java/com/infoline/helloworld/
│   ├── HelloworldApplication.java
│   └── HelloController.java
├── Dockerfile
├── pom.xml
├── deployment.yaml
└── service.yaml
```
##  retour experience 
- Fallait juste bien penser à installer Java et mettre JAVA_HOME sinon Maven râle.
- Le build multi-stage avec Maven + Temurin c’est top pour alléger les images.
- J’ai fais ça sur ma VM Debian dans VirtualBox, donc pas besoin de cloud ni de payer quoi que ce soit pour eviter mon erreur aws sur l'activité 1

---

# Grand Etape 2 – Dockerisation de mon app Java Spring Boot

Deuxième etape de mon ECF DevOps : ici j'ai mis mon app Spring Boot dans un conteneur Docker.  
Le but c’est de pouvoir la lancer facillement n’importe ou (sur ma VM dans ce cas).

---

##  Objectif

Créer une image Docker de l’app et la faire tourner sur ma VM Debian.  
Pas besoin de cloud ni d’AWS, tout tourne en local 

---

##  Mon Dockerfile

J’ai mis ce fichier `Dockerfile` à la racine du projet :

```Dockerfile
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Y’a deux étapes :
1. on construit l’app avec Maven
2. on l’execute dans une image plus legère avec juste Java

---

##  Commandes utilisées

###  Pour construire l’image :

```bash
sudo docker build -t helloworld-app .
```

###  Pour la lancer :

```bash
sudo docker run -p 8080:8080 helloworld-app
```

---

## Test dans le navigateur

Ensuite je suis allé sur Firefox dans ma VM et j’ai tapé :

```
http://localhost:8080/hello
```

Et BIM :  
```
Hello, World!
```

---

##  Résultat obtenu

- L’image Docker marche 
- Le conteneur tourne
- Le port 8080 est bien ouvert
- L’app répond bien dans le navigateur

---

##  Petit retour d’experience

- J’ai du faire un `sudo` sinon Docker voulais pas executer (accès refusé au socket).
- Le build multi-stage est super utile pour pas faire une image trop lourde


## Grand Etape 3- Déploiement d'une Application Java Spring Boot sur Kubernetes (Minikube)

# Déploiement d'une Application Spring Boot sur Kubernetes (Minikube)

Ce projet a pour but de démontrer un cycle complet de déploiement : du code source d'une application Java Spring Boot jusqu'à son exécution dans un cluster Kubernetes local via Minikube.

L'application est un simple service "Hello World" qui répond sur le port 8080.

##  1. Structure du Projet

Le projet est organisé de manière simple pour se concentrer sur le processus de déploiement.

```
helloworld/
├── src/main/java/com/infoline/helloworld/
│   ├── HelloworldApplication.java  (Point d'entrée Spring Boot)
│   └── HelloController.java        (Contrôleur REST)
├── pom.xml                         (Dépendances et configuration Maven)
├── Dockerfile                      (Instructions pour construire l'image Docker)
├── deployment.yaml                 (Manifeste de déploiement Kubernetes)
└── service.yaml                    (Manifeste de service Kubernetes)
```

### Code Source (`HelloController.java`)

Le contrôleur expose un unique endpoint `/` qui retourne un message de bienvenue.

```java
package com.infoline.helloworld;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello from Spring Boot!";
    }
}
```

---

## Processus de Déploiement

Voici les étapes détaillées pour compiler, containeriser et déployer l'application.

### Étape 1 : Build de l'Application avec Maven

Cette commande compile le code source, exécute les tests (ici désactivés avec `-DskipTests`) et empaquette l'application dans un fichier `.jar` exécutable.

```bash
mvn clean package -DskipTests
```

Le fichier `helloworld-0.0.1-SNAPSHOT.jar` sera généré dans le répertoire `target/`.

### Étape 2 : Containerisation avec Docker

Nous utilisons un `Dockerfile` pour créer une image Docker contenant notre application.

#### Contenu du `Dockerfile`

```dockerfile
# 1. Utiliser une image de base Java 17
FROM eclipse-temurin:17-jdk

# 2. Définir le répertoire de travail dans le conteneur
WORKDIR /app

# 3. Copier le .jar buildé dans le conteneur et le renommer
COPY target/helloworld-0.0.1-SNAPSHOT.jar app.jar

# 4. Exposer le port sur lequel l'application tourne
EXPOSE 8080

# 5. Définir la commande à exécuter au démarrage du conteneur
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Commande de build de l'image

Cette commande construit l'image Docker en utilisant le `Dockerfile` présent dans le répertoire courant et la nomme (`-t`) `helloworld-app`.

```bash
docker build -t helloworld-app .
```

### Étape 3 : Déploiement sur Kubernetes

#### 3.1. Démarrage de Minikube

On démarre un cluster Kubernetes local. L'option `--memory` permet d'allouer suffisamment de ressources pour éviter les problèmes de performance.

```bash
minikube start --memory=4096mb
```

#### 3.2. Chargement de l'Image dans Minikube

Pour que Minikube puisse utiliser notre image locale sans la télécharger depuis un registre distant, nous devons la charger directement dans l'environnement de Minikube.

```bash
minikube image load helloworld-app
```

*Note : C'est la raison pour laquelle `imagePullPolicy: Never` est utilisé dans le `deployment.yaml`. Cela indique à Kubernetes de ne pas essayer de télécharger l'image et d'utiliser celle qui est déjà présente localement dans le cluster.*

#### 3.3. Manifestes Kubernetes

Nous utilisons deux fichiers pour décrire notre déploiement.

**`deployment.yaml`** : Ce fichier crée un **Déploiement** qui gère la création et la mise à l'échelle des **Pods** (conteneurs) de notre application.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      containers:
      - name: helloworld
        image: helloworld-app
        imagePullPolicy: Never # Important : utiliser l'image locale chargée
        ports:
        - containerPort: 8080
```

**`service.yaml`** : Ce fichier crée un **Service** de type `NodePort`, qui expose notre application à l'extérieur du cluster sur un port statique.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: helloworld-service
spec:
  type: NodePort # Expose le service sur l'IP du nœud à un port statique
  selector:
    app: helloworld # Cible les pods avec ce label
  ports:
    - protocol: TCP
      port: 8080       # Port interne du service
      targetPort: 8080 # Port du conteneur
      nodePort: 30080  # Port externe accessible
```

#### 3.4. Application des Manifestes

Ces commandes appliquent les configurations définies dans les fichiers YAML au cluster Kubernetes.

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

##  4. Vérification et Accès à l'Application

Une fois le déploiement terminé, vous pouvez accéder à votre application.

1.  **Obtenir l'URL d'accès au service :**
    Minikube fournit une commande pratique pour obtenir l'URL directe.

    ```bash
    minikube service helloworld-service --url
    ```
    Cette commande retournera une URL, par exemple : `http://192.168.49.2:30080`

2.  **Tester avec `curl` ou un navigateur :**
    Ouvrez l'URL retournée dans votre navigateur ou utilisez `curl` dans votre terminal.

    ```bash
    curl $(minikube service helloworld-service --url)
    ```

    **Réponse attendue :**
    ```
    Hello from Spring Boot!
    ```

---

## 5. Nettoyage

Pour arrêter et supprimer les ressources créées, utilisez les commandes suivantes.

```bash
# Supprimer le service et le déploiement de Kubernetes
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

# Arrêter le cluster Minikube
minikube stop

# (Optionnel) Supprimer complètement le cluster Minikube
minikube delete
```

---

##  Script d'Automatisation Complet

Pour simplifier, voici un script `deploy.sh` qui exécute toutes les étapes en une seule fois.

```bash
#!/bin/bash

# Script pour builder, containeriser et déployer l'application Spring Boot sur Minikube

echo "### Étape 1: Build de l'application Maven ###"
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "Erreur lors du build Maven. Arrêt du script."
    exit 1
fi

echo "\n### Étape 2: Build de l'image Docker ###"
docker build -t helloworld-app .
if [ <span class="math-inline">? \-ne 0 \]; then
echo "Erreur lors du build Docker\. Arrêt du script\."
exit 1
fi
echo "\\n\#\#\# Étape 3\: Démarrage et configuration de Minikube \#\#\#"
minikube start \-\-memory\=4096mb
echo "Chargement de l'image Docker dans Minikube\.\.\."
minikube image load helloworld\-app
echo "\\n\#\#\# Étape 4\: Déploiement sur Kubernetes \#\#\#"
kubectl apply \-f deployment\.yaml
kubectl apply \-f service\.yaml
echo "\\n\#\#\# Attente du démarrage du pod\.\.\. \#\#\#"
kubectl wait \-\-for\=condition\=ready pod \-l app\=helloworld \-\-timeout\=120s
echo "\\n\#\#\# Déploiement terminé \! \#\#\#"
URL\=</span>(minikube service helloworld-service --url)
echo "Application accessible à l'URL : $URL"
echo "Test avec curl :"
curl $URL
```


## Grand Etape 4- Projet Angular - Hello Angular

 créer une application Angular qui affiche un message "Hello world" dans un navigateur. C’était l’occasion de mettre les mains dans Angular CLI et de valider que l’environnement était fonctionnel, de A à Z.

---

##  Objectif de l’exercice

Créer une application Angular basique avec le CLI officiel (`npx @angular/cli`) et vérifier qu’elle fonctionne en local dans un navigateur.

---

## Étapes réalisées

### 1. Installation des prérequis

Après avoir galéré un peu avec les versions de Node.js (eh oui, Angular veut au moins la v20 ou v22), j’ai mis à jour Node via `n`, et j’ai finalement pu lancer Angular CLI sans encombre :

```bash
npx @angular/cli@latest new hello-angular
```

J’ai répondu à quelques questions (zone.js, CSS, SSR...) puis j’ai laissé Angular bosser. Après quelques minutes , le projet était prêt.

---

### 2. Lancer l’application

Je suis ensuite allé dans le dossier fraîchement généré :

```bash
cd hello-angular
npm start
```

Puis j’ai ouvert Firefox sur :

```
http://localhost:4200
```

Et bim !  Un bel écran avec marqué "Hello, hello-angular" – preuve que tout fonctionne.

---

##  Résultat attendu

- Application Angular créée avec succès
-  Serveur de dev opérationnel
-  Affichage du message dans le navigateur
- Objectif de l'exercice validé

---

## Remarques personnelles

Ce genre d’exercice est simple en apparence, mais il faut tout de même faire gaffe aux versions (Node, npm, Angular CLI...). Une fois que tout est aligné, ça roule tout seul.

---

##  Structure

```
hello-angular/
├── src/
├── angular.json
├── package.json
└── ...
```
# Grand Etape 5- xécution locale d’un job CircleCI pour builder et tester une app Angular

## Présentation

Dans le cadre de ma formation (Studi), j'ai eu à répondre à l'exercice suivant :

« Écrivez le script qui build/test et le Angular (CircleCI est accepté) »

L'objectif était de faire fonctionner un pipeline CircleCI **en local**, qui build une application Angular (et, éventuellement, exécute des tests).

---

## Déroulé

### 1. Mise en place de l'environnement

J'ai travaillé sur une machine virtuelle Debian via Oracle VirtualBox.
J'ai installé :

- Node.js (dans un premier temps en version 18)
- Le projet Angular dans `~/projet-infoline`
- Le binaire `circleci` (CLI CircleCI officiel)

### 2. Configuration CircleCI

Dans le dossier `.circleci/`, j'ai créé un fichier `config.yml` contenant le job suivant :

```yaml
version: 2.1

jobs:
  build-and-test:
    docker:
      - image: cimg/node:18.20.2
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: npm ci
      - run:
          name: Build Angular App
          command: npm run build
      - run:
          name: Skipping tests (pas encore en place)
          command: |
            echo "Bonjour studi   steve avisse"

workflows:
  build:
    jobs:
      - build-and-test
```

### 3. Première erreur : `unknown flag: --job`

Au départ, j'exécutais la commande suivante pour tester le job :

```bash
circleci local execute --job build-and-test
```

Mais j'ai eu cette erreur : `unknown flag: --job`

Après recherche, j'ai compris que le CLI actuel ne reconnaît plus `--job` et qu’il faut simplement passer le nom du job en argument positionnel :

```bash
circleci local execute build-and-test
```

### 4. Deuxième erreur : version de Node.js insuffisante

Le build Angular échouait avec :

```
Node.js version v18.20.2 detected.
The Angular CLI requires a minimum Node.js version of v20.19 or v22.12.
```

Donc j’ai modifié l’image Docker utilisée dans le `config.yml` en :

```yaml
image: cimg/node:20.19.1
```

Et là, le build a réussi.

### 5. Troisième problème : pas assez d’espace disque

La VM Debian avait un disque de 20 Go, presque plein.
J’ai donc :

- étendu le disque `.vdi` via VirtualBox (de 20 Go à 80 Go)
- utilisé GParted (image ISO montée en démarrage CD-ROM) pour élargir `/dev/sda1`
- relancé Debian : l’espace était bien disponible

### 6. Tests : pas encore en place

Pour l’instant, il n’y avait pas de tests configurés dans le projet Angular. Donc j’ai juste simulé une étape test dans le `config.yml` avec un `echo`. J’ai volontairement mis :

```bash
echo "Bonjour studi   steve avisse"
```

Juste pour vérifier que c’était bien exécuté.

---

## Résultat final 

En relancant :

```bash
circleci local execute build-and-test
```

J’ai bien obtenu :

```
Success!
```

Et les logs confirment que :

- le code a été checkout
- les `node_modules` ont été installés via `npm ci`
- la commande `ng build` a généré le bundle dans `dist/`
- et enfin mon message test perso a bien été affiché

---

## Conclusion

J’ai réussi à faire tourner **un job CircleCI localement** pour build une application Angular.

J’ai galéré un peu au début sur les options de la CLI, et sur les problèmes de disque ou de version Node, mais au final tout a été résolu proprement. Le tout fonctionne **sans cloud**, **sans Docker Compose**, uniquement avec le CLI et un `.circleci/config.yml` bien configuré.



