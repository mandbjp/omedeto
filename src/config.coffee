# config設定
exports.config =
  port: 3000
  mongo:
    options:
      poolSize: 10
      auto_reconnect: true
      host: "127.0.0.1"
