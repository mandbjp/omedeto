mongoWrapper = require "mongoWrapper"
config = require("../../config").config

mongo = module.exports = new mongoWrapper.default config.mongo.host, config.mongo.port, config.mongo.options
mongo.ObjectID = mongoWrapper.ObjectID
