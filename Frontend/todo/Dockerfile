# syntax=docker/dockerfile:1
FROM node:22-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
ARG REACT_APP_API_BASE_URL=/api
ENV REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL
RUN npm run build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html

RUN addgroup -S app && adduser -S -G app app \
    && chown -R app:app /usr/share/nginx/html \
    && chown -R app:app /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown app:app /var/run/nginx.pid

USER app
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
