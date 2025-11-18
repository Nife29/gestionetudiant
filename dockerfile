# Étape 1 : Image de base PHP avec les extensions nécessaires
FROM php:8.2-cli

# Étape 2 : Installer les dépendances système
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip exif pcntl

# Étape 3 : Installer Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Étape 4 : Définir le répertoire de travail
WORKDIR /var/www

# Étape 5 : Copier les fichiers du projet
COPY . .

# Étape 6 : Installer les dépendances Laravel
RUN composer install --no-dev --optimize-autoloader

# Étape 7 : Générer les caches Laravel
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Étape 8 : Exposer le port utilisé par Laravel
EXPOSE 8000

# Étape 9 : Commande de démarrage
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT}"]