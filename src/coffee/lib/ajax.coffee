Promise = require("q").Promise
req = (type, path, query) ->
  return Promise (resolve, reject) ->
    $.ajax
      type: type
      url: path
      data: query
      contentType: "application/json"
      headers:
        "x-csrf-token": $("#csrf").val()
    .done (data, textStatus, jqXHR) ->
      resolve data
      return
    .fail (jqXHR, textStatus, errorThrown) ->
      reject jqXHR
      return
    return

Ajax = (resource) ->
  @resource = resource
  return

Ajax::index = (query) ->
  return req "GET", "/#{@resource}", query

Ajax::create = (query) ->
  return req "POST", "/#{@resource}", JSON.stringify query

Ajax::show = (id, query) ->
  return req "GET", "/#{@resource}/#{id}", query

Ajax::update = (id, query) ->
  return req "PUT", "/#{@resource}/#{id}", JSON.stringify query

Ajax::destroy = (id, query) ->
  return req "DELETE", "/#{@resource}/#{id}", JSON.stringify query

module.exports = Ajax
