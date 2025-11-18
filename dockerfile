# Utilise une image PHP-Apache officielle
FROM php:8.2-apache

# Variables d'environnement
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
ENV COMPOSER_ALLOW_SUPERUSER=1

# Installe les dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    git \
    curl \
    libonig-dev \
    libxml2-dev \
    zip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libgd-dev \
    && rm -rf /var/lib/apt/lists/*

# Installe et configure les extensions PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mbstring \
        zip \
        exif \
        pcntl \
        bcmath \
        gd \
        intl

# Active les modules Apache nécessaires
RUN a2enmod rewrite headers

# Installe Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définit le répertoire de travail
WORKDIR /var/www/html

# Copie le code de votre application
COPY . .

# Crée les dossiers de cache et de logs
RUN mkdir -p storage/framework/{cache/data,sessions,views} storage/logs bootstrap/cache

# Met à jour les permissions temporaires
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Installe les dépendances de production
RUN composer install --optimize-autoloader --no-dev --no-interaction

# --- AJOUTEZ CETTE LIGNE ---
# Crée le lien symbolique pour le stockage
RUN php artisan storage:link
# -------------------------

# Videz et mettez en cache la configuration
RUN php artisan config:clear --no-interaction || true \
    && php artisan route:clear --no-interaction || true \
    && php artisan view:clear --no-interaction || true \
    && php artisan config:cache --no-interaction || true \
    && php artisan route:cache --no-interaction || true \
    && php artisan view:cache --no-interaction || true

# Définit les permissions finales
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 storage \
    && chmod -R 775 bootstrap/cache \
    && chmod -R 755 public

# Configuration d'Apache pour Laravel
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && echo '<Directory ${APACHE_DOCUMENT_ROOT}>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
    DirectoryIndex index.php\n\
    </Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Expose le port 80
EXPOSE 80

# Configure le point d'entrée et la commande par défaut
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]