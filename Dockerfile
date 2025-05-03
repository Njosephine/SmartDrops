# Stage 1: Build assets
FROM node:18 AS node-builder

# Set working directory
WORKDIR /app

# Copy only necessary files for frontend build
COPY package*.json ./
RUN npm install

# Copy the rest of the project files
COPY . .

# Build assets
RUN npm run build

# Stage 2: PHP + Composer + final Laravel app

# Use the official PHP image with required extensions
FROM php:8.3-fpm

# Set working directory
WORKDIR /var/www

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage

# Expose port for Laravel's internal server
EXPOSE 8000

# Start Laravel server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
