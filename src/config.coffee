# config設定
exports.config =
  port: 3000
  mongo:
    host: "127.0.0.1"
    port: 27017
    options:
      poolSize: 10
      auto_reconnect: true
  auth:
    admin:
      user: "admin"
      password: "adminpassword"
    general:
      user: "user"
      password: "password"
