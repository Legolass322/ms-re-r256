FROM ghcr.io/cirruslabs/flutter:3.24.3 AS build

ARG API_BASE_URL=http://localhost:8080
ENV API_BASE_URL=${API_BASE_URL}

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter pub get
RUN flutter pub run build_runner build --delete-conflicting-outputs || (echo "Build runner failed, checking generated files..." && find lib -name "*.g.dart" -ls || echo "No .g.dart files found")
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine AS runtime

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

