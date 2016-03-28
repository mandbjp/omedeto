mongoWrapper = require "mongoWrapper"
config = require "../../config"

mongo = module.exports = new mongoWrapper config.mongo
mongo.ObjectID = mongoWrapper.ObjectID
