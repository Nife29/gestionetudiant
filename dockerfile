# Utilise une image PHP officielle avec les extensions nécessaires
FROM php:8.2-cli

# Installe les dépendances système
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    && docker-php-ext-install pdo mbstring zip exif pcntl

# Installe Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copie les fichiers du projet
COPY . /var/www
WORKDIR /var/www

# Installe les dépendances Laravel
RUN composer install --no-dev --optimize-autoloader

# Met en cache la configuration, les routes et les vues
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Démarre le serveur Laravel
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]